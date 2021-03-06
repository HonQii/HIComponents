//
//  InnerKeyMap.swift
//  HQDownload
//
//  Created by HonQi on 8/13/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

struct InnerKeyMap<T> {
    struct UIntKey: Hashable, Equatable {
        fileprivate let rawValue: UInt64
        var hashValue: Int { return rawValue.hashValue }
        public static func == (lhs: UIntKey, rhs: UIntKey) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
    }
    
    let ArrayMaxSize: Int = 30
    
    typealias Key = UIntKey
    
    private var _nextKey: Key = Key(rawValue: 0)
    
    /// Save first key, value pairs
    private var key_0: Key?
    private var value_0: T?
    private var singleValue = true
    
    /// Save 2th - 31th pairs to array
    typealias Pairs = (key: Key, value: T)
    private var pairs = ContiguousArray<Pairs>()
    
    /// Save 31th - ∞ pairs to dictionary
    private var dict: [Key: T]?
    
    var count: Int {
        return pairs.count + (dict?.count ?? 0) + (key_0 != nil ? 1 : 0)
    }
    
    init() {
    }
    
    @discardableResult
    mutating func insert(_ element: T) -> UInt64 {
        let key = _nextKey
        _nextKey = Key(rawValue: _nextKey.rawValue &+ 1) // 溢出加 1
        
        guard let _ = key_0 else {
            key_0 = key
            value_0 = element
            return key.rawValue
        }
        
        singleValue = false
        
        guard dict == nil else {
            dict![key] = element
            return key.rawValue
        }
        
        guard pairs.count >= ArrayMaxSize else {
            pairs.append((key: key, value: element))
            return key.rawValue
        }
        
        dict = [key: element]
        return key.rawValue
    }
    
    mutating func removeAll() {
        key_0 = nil
        value_0 = nil
        
        pairs.removeAll(keepingCapacity: false)
        
        dict?.removeAll(keepingCapacity: false)
    }
    
    @discardableResult
    mutating func remove(_ key: UInt64) -> T? {
        let _key = Key(rawValue: key)
        if key_0 == _key {
            key_0 = nil
            let value = value_0
            value_0 = nil
            return value
        }
        
        if let obj = dict?.removeValue(forKey: _key) {
            return obj
        }
        
        for i in 0 ..< pairs.count {
            if pairs[i].key == _key {
                let value = pairs[i].value
                pairs.remove(at: i)
                return value
            }
        }
        
        return nil
    }
    
    func forEach(_ action: (T) -> Void) {
        if let v = value_0 { action(v) }
        
        pairs.forEach{ action($1) }
        
        dict?.forEach{ action($1) }
    }
}
