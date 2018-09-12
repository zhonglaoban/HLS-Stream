//
//  ViewController.swift
//  HLS Stream
//
//  Created by zhongfan on 2018/6/5.
//  Copyright © 2018年 zhongfan. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {
    var playerViewController:AVPlayerViewController?
    let assetKey1 = "assetKey1"
    
    @IBOutlet weak var downLoadProgress: UIProgressView!
    @IBAction func downloadHLS(_ sender: UIButton) {
        guard let url = URL(string: "http://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8") else { return }
        DownloadManager.shared.downloadAsset(url, assetKey1)
    }
    //MARK: - system
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NotificationCenter.default.addObserver(self, selector: #selector(downloadProgress), name: .DownloadProgressNotification, object: nil)
        DownloadManager.shared.restorePendingDownloads()
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //MARK: - actions
    @objc func downloadProgress(notification: NSNotification) {
        guard let userInfo = notification.userInfo as? [String:Any] else { return }
        guard let percent = userInfo["percent"] as? Double else { return }
        downLoadProgress.setProgress(Float(percent), animated: true)
        print(percent)
    }
    //MARK: - segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destVC = segue.destination as? AVPlayerViewController else { return }
        playerViewController = destVC
        if segue.identifier == "offline" {
            guard let playerItem = DownloadManager.shared.getPlayerItem(assetKey1) else {
                print("file not exist")
                return
            }
//            guard let location = UserDefaults.standard.url(forKey: assetKey1) else {
//                return
//            }
//            let onlinePlayer = AVPlayer(url: location)
            let onlinePlayer = AVPlayer(playerItem: playerItem)
            playerViewController?.player = onlinePlayer
        }
        if segue.identifier == "online" {
            guard let url = URL(string: "http://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8") else { return }
            let onlinePlayer = AVPlayer(url: url)
            playerViewController?.player = onlinePlayer
        }
        super.prepare(for: segue, sender: sender)
    }
}

