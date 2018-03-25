//
//  HQMemoryCache.swift
//  HQCache
//
//  Created by qihuang on 2018/3/26.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import Foundation

fileprivate class HQCacheLinkNode {
    weak var prev: HQCacheLinkNode?
    weak var next: HQCacheLinkNode?
    var key: String!
    var value: Any!
    var cost: UInt = 0
    var time: TimeInterval!
}

extension HQCacheLinkNode: Equatable {
    static func ==(lhs: HQCacheLinkNode, rhs: HQCacheLinkNode) -> Bool {
        return lhs.key == rhs.key
    }
}

fileprivate struct HQCacheLinkMap {
    // dictionary is hash map, query fast than array
    //    var dict: CFMutableDictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, [kCFTypeDictionaryKeyCallBacks], [kCFTypeDictionaryValueCallBacks])
    var dict = Dictionary<String, HQCacheLinkNode>()
    var totalCost: UInt = 0
    var totalCount: UInt = 0
    var head: HQCacheLinkNode?
    var tail: HQCacheLinkNode?
    
    var releaseOnMainThread = false
    var releaseAsynchronously = true
    
    mutating func insert(node: HQCacheLinkNode) {
        //        CFDictionarySetValue(dict, &node.key, Unmanaged.passUnretained(node).toOpaque())
        dict[node.key] = node
        totalCost += node.cost
        totalCount += 1
        if let h = head {
            node.next = h
            h.prev = node
            head = node
        }
        else {
            head = node
            tail = node
        }
    }
    
    mutating func toHead(node: HQCacheLinkNode) {
        guard let h = head, h != node else { return }
        if tail! == node {
            tail = node.prev
            tail?.next = nil
        }
        else {
            node.next?.prev = node.prev
            node.prev?.next = node.next
        }
        
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node
    }
    
    mutating func remove(node: HQCacheLinkNode) {
        //        CFDictionaryRemoveValue(dict, &node.key)
        dict.removeValue(forKey: node.key)
        totalCost -= node.cost
        totalCount -= 1
        if let n = node.next { n.prev = node.prev }
        if let p = node.prev { p.next = node.next }
        if head! == node { head = node.next }
        if tail! == node { tail = node.prev }
    }
    
    mutating func removeTail() -> HQCacheLinkNode? {
        guard let t = tail else { return nil }
        remove(node: t)
        return t
    }
    
    mutating func removeAll() {
        totalCost = 0
        totalCount = 0
        tail = nil
        head = nil
        // CFDictionaryGetCount(dict) > 0
        if !dict.isEmpty {
            var holder = dict
            dict = Dictionary()
            //CFDictionaryCreateMutable(kCFAllocatorDefault, 0, [kCFTypeDictionaryKeyCallBacks], [kCFTypeDictionaryValueCallBacks])
            
            if releaseAsynchronously {
                let queue = releaseOnMainThread ? DispatchQueue.main : DispatchQueue.global(qos: .utility)
                queue.async { holder.removeAll() }
            }
            else if releaseOnMainThread && pthread_main_np() == 0 { // back to main thread release
                DispatchQueue.main.async { holder.removeAll() }
            }
            // auto release
        }
    }
}

public class HQMemoryCache: HQCacheProtocol {
    
    private var cacheMap = HQCacheLinkMap()
    private let queue = DispatchQueue(label: "com.HQPerson.cache.memory", qos: .default, attributes: DispatchQueue.Attributes.concurrent)
    private let mutex = Mutex()
    
    public var name: String = "MemoryCache"
    public var countLimit: UInt = UInt(UINTMAX_MAX)
    public var costLimit: UInt = UInt(UINTMAX_MAX)
    public var ageLimit: TimeInterval = TimeInterval(UINTMAX_MAX)
    public var autoTrimInterval: TimeInterval = 5.0
    
    var autoEmptyCacheOnMemoryWarning = true
    var autoEmptyCacheWhenEnteringBackground = true
    
    var didReceiveMemoryWarningClosure: ((HQMemoryCache)->Void)?
    var didEnterBackgroundClosure: ((HQMemoryCache)->Void)?
    
    var releaseAsynchronously: Bool {
        get {
            mutex.lock()
            let release = cacheMap.releaseAsynchronously
            mutex.unlock()
            return release
        }
        set {
            mutex.lock()
            cacheMap.releaseAsynchronously = newValue
            mutex.unlock()
        }
    }
    var releaseOnMainThread: Bool {
        get {
            mutex.lock()
            let release = cacheMap.releaseOnMainThread
            mutex.unlock()
            return release
        }
        set {
            mutex.lock()
            cacheMap.releaseOnMainThread = newValue
            mutex.unlock()
        }
    }
    
    public init() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryWarning), name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        clearCacheTiming()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        deleteAllCache()
    }
    
}


extension HQMemoryCache {
    public func exist(forKey key: String) -> Bool {
        //        var k = key
        mutex.lock()
        //        let contains = CFDictionaryContainsKey(cacheMap.dict, &k)
        let contains = cacheMap.dict.keys.contains(key)
        mutex.unlock()
        return contains
    }
    
    public func query(objectForKey key: String) -> Any? {
        //        var k = key
        
        mutex.lock()
        defer { mutex.unlock() }
        //        guard let pointer = CFDictionaryGetValue(cacheMap.dict, &k) else { return nil }
        //        let node = Unmanaged<HQCacheLinkNode>.fromOpaque(pointer).takeUnretainedValue()
        guard let node = cacheMap.dict[key] else { return nil }
        node.time = CACurrentMediaTime()
        cacheMap.toHead(node: node)
        return node.value
    }
    
    public func insertOrUpdate(object obj: Any, forKey key: String, cost: UInt = 0) {
        mutex.lock()
        //        var k = key
        let now = CACurrentMediaTime()
        //        if let pointer = CFDictionaryGetValue(cacheMap.dict, &k) {
        //        let node = Unmanaged<HQCacheLinkNode>.fromOpaque(pointer).takeUnretainedValue()
        if let node = cacheMap.dict[key] {
            cacheMap.totalCost -= node.cost
            cacheMap.totalCost += cost
            node.cost = cost
            node.time = now
            node.value = obj
            cacheMap.toHead(node: node)
        }
        else {
            let node = HQCacheLinkNode()
            node.cost = cost
            node.value = obj
            node.time = now
            node.key = key
            cacheMap.insert(node: node)
        }
        mutex.unlock()
        
        if getTotalCount() > countLimit {
            clearCacheCondition(cond: cacheMap.totalCount > countLimit)
        }
        if getTotalCost() > costLimit {
            clearCacheCondition(cond: cacheMap.totalCost > costLimit)
        }
    }
    
    public func delete(objectForKey key: String) {
        mutex.lock()
        //        var k = key
        //        guard let pointer = CFDictionaryGetValue(cacheMap.dict, &k) else {
        //            mutex.unlock()
        //            return
        //        }
        //        let node = Unmanaged<HQCacheLinkNode>.fromOpaque(pointer).takeUnretainedValue()
        guard let node = cacheMap.dict[key] else {
            mutex.unlock()
            return
        }
        cacheMap.remove(node: node)
        mutex.unlock()
        
        if releaseAsynchronously {
            let queue = releaseOnMainThread ? DispatchQueue.main : DispatchQueue.global(qos: .utility)
            queue.async { let _ = node.self }
        }
        else if releaseOnMainThread && pthread_main_np() == 0 { // back to main thread release
            DispatchQueue.main.async { let _ = node.self }
        }
    }
    
    public func deleteAllCache() {
        mutex.lock()
        cacheMap.removeAll()
        mutex.unlock()
    }
    
    public func deleteCache(exceedToCost cost: UInt) {
        if cost <= 0 {
            deleteAllCache()
            return
        }
        if getTotalCost() <= cost { return }
        
        clearCacheCondition(cond: cacheMap.totalCost > cost)
    }
    
    public func deleteCache(exceedToCount count: UInt) {
        if count <= 0 {
            deleteAllCache()
            return
        }
        if getTotalCount() <= count { return }
        
        clearCacheCondition(cond: cacheMap.totalCount > count)
    }
    
    public func deleteCache(exceedToAge age: TimeInterval) {
        if age <= 0 {
            deleteAllCache()
            return
        }
        
        var finish = false
        mutex.lock()
        let now = CACurrentMediaTime()
        if cacheMap.tail == nil || (now - cacheMap.tail!.time) <= age {
            finish = true
        }
        mutex.unlock()
        if finish { return }
        
        clearCacheCondition(cond: cacheMap.tail != nil && (now - cacheMap.tail!.time) > age )
    }
    
    public func getTotalCount() -> UInt {
        mutex.lock()
        let count = cacheMap.totalCount
        mutex.unlock()
        return count
    }
    
    public func getTotalCost() -> UInt {
        mutex.lock()
        let cost = cacheMap.totalCost
        mutex.unlock()
        return cost
    }
    
}


private extension HQMemoryCache {
    
    func clearCacheCondition(cond: @autoclosure () -> Bool) {
        var finish = false
        var holders = [HQCacheLinkNode]()
        
        while !finish {
            if mutex.tryLock() == 0 { // lock success
                if cond() {
                    if let node = cacheMap.removeTail() {
                        holders.append(node)
                    }
                }
                else {
                    finish = true
                }
                mutex.unlock()
            }
            else { // lock failure
                usleep(10 * 1000) // waiting 10 ms and try again
            }
        }
        
        if !holders.isEmpty {
            if releaseAsynchronously {
                let queue = releaseOnMainThread ? DispatchQueue.main : DispatchQueue.global(qos: .utility)
                queue.async { holders.removeAll() }
            }
            else if releaseOnMainThread && pthread_main_np() == 0 { // back to main thread release
                DispatchQueue.main.async { holders.removeAll() }
            }
        }
    }
    
    func clearCacheTiming() {
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: DispatchTime.now() + 1.0) {[weak self] in
            guard let wself = self else { return }
            wself.clearInBackground()
            wself.clearCacheTiming() // cycle execute
        }
    }
    
    func clearInBackground() {
        queue.async {
            self.deleteCache(exceedToAge: self.ageLimit)
            self.deleteCache(exceedToCost: self.costLimit)
            self.deleteCache(exceedToCount: self.countLimit)
        }
    }
    
    @objc private func didReceiveMemoryWarning() {
        if let did = didReceiveMemoryWarningClosure { did(self) }
        if autoEmptyCacheOnMemoryWarning { deleteAllCache() }
    }
    
    @objc private func AppDidEnterBackground() {
        if let did = didEnterBackgroundClosure { did(self) }
        if autoEmptyCacheWhenEnteringBackground { deleteAllCache() }
    }
}
