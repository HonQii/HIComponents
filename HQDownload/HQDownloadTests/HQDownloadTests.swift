//
//  HQDownloadTests.swift
//  HQDownloadTests
//
//  Created by qihuang on 2018/3/26.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import XCTest
@testable import HQDownload

class HQDownloadTest: XCTestCase {
    let domain: URL = URL(string: "https://httpbin.org")!
    let testDirectory: URL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("download_test", isDirectory: true)
    
    override func setUp() {
        super.setUp()
        try? FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true, attributes: nil)
    }
    
    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: testDirectory)
    }
    
    func randomTargetPath() -> URL {
        return testDirectory.appendingPathComponent("\(UUID().uuidString).json")
    }
    
    func async(_ timeout: TimeInterval = 15, _ execute: (@escaping ()->Void) -> Void) {
        let exception = self.expectation(description: "Excetation async task executed")
        execute({exception.fulfill()})
        waitForExpectations(timeout: timeout, handler: nil)
    }
}