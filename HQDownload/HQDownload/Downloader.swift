//
//  Downloader.swift
//  HQDownload
//
//  Created by HonQi on 5/31/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import HQFoundation
import HQCache

public class Downloader: Eventable {
    var eventsMap = InnerKeyMap<Eventable.EventWrap>()
    var eventsLock = DispatchSemaphore(value: 1)
    
    private let options: OptionsInfo
    
    private let cache: CacheManager
    
    private let scheduler: Scheduler
    
//    private let backScheduler: Scheduler
    
    init(_ infos: OptionsInfo) {
        var directory: URL! = nil
        if let item = infos.lastMatchIgnoringAssociatedValue(.cacheDirectory(holderUrl)),
            case .cacheDirectory(let dire) = item {
            directory = dire
            options = infos
        }
        else {
            let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
            directory = URL(fileURLWithPath: path).appendingPathComponent("Download", isDirectory: true)
            options = infos + [.cacheDirectory(directory)]
        }

        cache = CacheManager(options.cacheDirectory)
        scheduler = Scheduler(options)
//        backScheduler = Scheduler(options)
        
        scheduler.subscribe(
            .start({ [weak self] (source, name, size) in
                self?.trigger(source, .start(name, size))
            }),
            .progress({ [weak self] (source, rate) in
                self?.trigger(source, .progress(rate))
            }),
            .data({ [weak self] (source, data) in
                self?.trigger(source, .data(data))
            }),
            .completed({ [weak self] (source, file) in
                self?.trigger(source, .completed(file))
            }),
            .error({ [weak self] (source, err) in
                self?.trigger(source, .error(err))
            })
        )
    }
}


extension Downloader {
    public func start(url: URL) {
//        let options = data // decode
//        download(options: <#T##OptionsInfo#>)
    }
    
    public func pause(source: String) -> Data? {
        /// return resume data
        return nil
    }
    
    public func cancel() {
        // remove task and delete options
    }
    
    public func allTasks() {
        
    }
    
    public func failureTasks() {
        
    }
    
    public func completedTasks() {
        
    }
    
    public func progressTasks() {
        
    }
    
    public func download(source: URL) {
        download(infos: [.sourceUrl(source)])
    }
    
    public func download(source: String) {
        guard let url = URL(string: source) else {
            assertionFailure("Source string: \(source) is empty or can not convert to URL!")
            return
        }
        return download(source: url)
    }
    
    public func download(infos: OptionsInfo) {
        guard let url = infos.sourceUrl else {
            assertionFailure("Source URL can not be empty!")
            return
        }
        
        var items = infos
        
        if let cacheInfo: OptionsInfo = cache.query(objectForKey: url.absoluteString),
            let completed = cacheInfo.completedCount,
            let total = cacheInfo.exceptedCount {
            if completed > total {
                trigger(url, .completed(cacheInfo.cacheDirectory.appendingPathComponent(cacheInfo.fileName!)))
                return
            }
            else {
                items = cacheInfo + infos
            }
        }
//        if items.backgroundSession {
//            // TODO: back taks identifier
//            backScheduler.download(info: items)
//        }
//        else {
            scheduler.download(info: items)
//        }
    }
}
