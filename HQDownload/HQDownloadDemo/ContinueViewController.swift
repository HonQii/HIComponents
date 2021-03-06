////
////  ContinueViewController.swift
////  HQDownloadDemo
////
////  Created by HonQi on 4/25/18.
////  Copyright © 2018 HonQi Indie. All rights reserved.
////
//
//import UIKit
//import HQDownload
//
//class ContinueViewController: UIViewController {
//    var progressView = UIProgressView(progressViewStyle: .default)
//    var statusLabel = UILabel()
//    var startBtn = UIButton()
//    var endBtn = UIButton()
//    var pauseBtn = UIButton()
//    var resumeBtn = UIButton()
//
//    let source = URL(string: "http://p11s9kqxf.bkt.clouddn.com/iPhone.mp4")!
//    let directory = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!)
//
////    var operation: HQDownloader?
//    var resumeData: Data?
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = UIColor.white
//        title = "断点续传"
//
//        progressView.frame = CGRect(x: 12, y: 106, width: view.bounds.width - 24, height: 44)
//        progressView.progressTintColor = UIColor.green
//        progressView.backgroundColor = UIColor.lightGray
//
//        statusLabel.frame = CGRect(x: 12, y: progressView.frame.maxY + 12, width: progressView.frame.width, height: 44)
//        statusLabel.backgroundColor = UIColor.lightGray
//        statusLabel.textColor = UIColor.white
//        statusLabel.text = "Ready"
//        statusLabel.textAlignment = .center
//
//        let width = (view.frame.width - 12 * 5) / 4
//        let top = statusLabel.frame.maxY + 24
//
//        startBtn.setTitle("开始", for: .normal)
//        startBtn.backgroundColor = UIColor.green
//        startBtn.frame = CGRect(x: 12, y: top, width: width, height: 44)
//        startBtn.addTarget(self, action: #selector(start), for: .touchUpInside)
//
//        endBtn.setTitle("取消", for: .normal)
//        endBtn.backgroundColor = UIColor.red
//        endBtn.frame = CGRect(x: startBtn.frame.maxX + 12, y: top, width: width, height: 44)
//        endBtn.addTarget(self, action: #selector(finish), for: .touchUpInside)
//
//        pauseBtn.setTitle("暂停", for: .normal)
//        pauseBtn.backgroundColor = UIColor.yellow
//        pauseBtn.frame = CGRect(x: endBtn.frame.maxX + 12, y: top, width: width, height: 44)
//        pauseBtn.addTarget(self, action: #selector(pause), for: .touchUpInside)
//
//        resumeBtn.setTitle("继续", for: .normal)
//        resumeBtn.backgroundColor = UIColor.blue
//        resumeBtn.frame = CGRect(x: pauseBtn.frame.maxX + 12, y: top, width: width, height: 44)
//        resumeBtn.addTarget(self, action: #selector(resume), for: .touchUpInside)
//
//        view.addSubview(progressView)
//        view.addSubview(statusLabel)
//        view.addSubview(startBtn)
//        view.addSubview(endBtn)
//        view.addSubview(pauseBtn)
//        view.addSubview(resumeBtn)
//    }
//
//
//
//    @objc func start() {
//        HQDownloadScheduler.scheduler.download(source: source) { (file, downloader) in
//            
//        }
//        operation = HQDownloader(source: source)
//            .started { (fiel, total) in
//                DispatchQueue.main.async {
//                    self.statusLabel.text = "Start and total is \(total/1024) kb"
//                }
//            }
//            .progress { (rece, frac) in
//                DispatchQueue.main.async {
//                    self.statusLabel.text = "Downloading and received \(rece/1024) kb, frac is \(frac*100) %"
//                    self.progressView.progress = Float(frac)
//                }
//            }
//            .finished { (file, err) in
//                DispatchQueue.main.async {
//                    self.statusLabel.text = "Finished and download file is \(String(describing: file?.path))"
//                    if let e = err {
//                        self.statusLabel.text = "Error: \(e.description)"
//                    }
//                }
//            }
//        operation?.start()
//        statusLabel.text = "Click start"
//    }
//
//    @objc func finish() {
//        operation?.cancel()
//        statusLabel.text = "Click finish"
//        operation = nil
//        try? FileManager.default.removeItem(at: directory)
//    }
//
//    @objc func pause() {
//        operation?.cancel(resumeData: { [weak self] (data) in
//            self?.resumeData = data
//        })
//        statusLabel.text = "Click pause"
//    }
//
//    @objc func resume() {
//        do {
//            let config = try JSONDecoder().decode(HQDownloadConfig.self, from: resumeData!)
//            operation = HQDownloader(source: source, config: config)
//                .started { (fiel, total) in
//                    DispatchQueue.main.async {
//                        self.statusLabel.text = "Start and total is \(total/1024) kb"
//                    }
//                }
//                .progress { (rece, frac) in
//                    DispatchQueue.main.async {
//                        self.statusLabel.text = "Downloading and received \(rece/1024) kb, frac is \(frac*100) %"
//                        self.progressView.progress = Float(frac)
//                    }
//                }
//                .finished { (file, err) in
//                    DispatchQueue.main.async {
//                        self.statusLabel.text = "Finished and download file is \(String(describing: file?.path))"
//                        if let e = err {
//                            self.statusLabel.text = "Error: \(e.description)"
//                        }
//                    }
//            }
//            operation?.start()
//        }
//        catch let err {
//            print(err.localizedDescription)
//        }
//
//        
//        statusLabel.text = "Click resume"
//    }
//}
