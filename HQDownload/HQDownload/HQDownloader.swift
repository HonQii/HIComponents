//
//  HQDownloader.swift
//  HQDownload
//
//  Created by Magee Huang on 4/10/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import HQCache

public class HQDownloader {
    private var scheduler: HQDownloadScheduler!
    private var cache: HQDiskCache!
    
    /// name is download directory name, file save to Cache directory
    public init(_ path: URL = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!).appendingPathComponent("downloader", isDirectory: true)) {
        scheduler = HQDownloadScheduler(path)
        cache = HQDiskCache(path)
    }
    

    public func download(_ source: URL, _ start: ((URL)->Void)?) {
        if cache.exist(forKey: source.absoluteString) {
            var progress: HQdownloadProgress?
            cache.query(objectForKey: source.absoluteString) { (_, obj) in
                progress = obj
                if progress?.fractionCompleted >= 1 {
                    start(progress?.fileURL)
                }
            }
        }
    }
}