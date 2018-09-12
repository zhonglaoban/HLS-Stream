//
//  DownloadManager.swift
//  HLS Stream
//
//  Created by zhongfan on 2018/6/5.
//  Copyright © 2018年 zhongfan. All rights reserved.
//

import Foundation
import AVFoundation

class DownloadManager:NSObject {
    static var shared = DownloadManager()
    private var config: URLSessionConfiguration!
    private var downloadSession: AVAssetDownloadURLSession!
    fileprivate var downloadingMap = [URL: AVAssetDownloadTask]()
    var player:AVPlayer!
    
    
    override private init() {
        super.init()
        config = URLSessionConfiguration.background(withIdentifier: "background")
        downloadSession = AVAssetDownloadURLSession(configuration: config, assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
    }
    
    func setupAssetDownload(_ url: URL) {
//        let options = [AVURLAssetAllowsCellularAccessKey: false]
        let asset = AVURLAsset(url: url)
        let downloadTask = downloadSession.makeAssetDownloadTask(asset: asset,
                                                                 assetTitle: "Test Download",
                                                                 assetArtworkData: nil,
                                                                 options: nil)
//        let preferredMediaSelection = asset.preferredMediaSelection
//        let downloadTask = downloadSession.aggregateAssetDownloadTask(with: asset,
//                                                           mediaSelections: [preferredMediaSelection],
//                                                           assetTitle:"Test",
//                                                           assetArtworkData: nil,
//                                                           options:
//            [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 265_000])
        
        downloadTask?.resume()
    }
    
    func restorePendingDownloads() {
        
        downloadSession.getAllTasks { tasksArray in
            
            for task in tasksArray {
                guard let downloadTask = task as? AVAssetDownloadTask else { break }
                
                downloadTask.resume()
            }
        }
    }
    
    func playOfflineAsset() -> AVURLAsset? {
        guard let assetPath = UserDefaults.standard.value(forKey: "assetPath") as? String else {
            
            return nil
        }
        let baseURL = URL(fileURLWithPath: NSHomeDirectory())
        let assetURL = baseURL.appendingPathComponent(assetPath)
        let asset = AVURLAsset(url: assetURL)
        if let cache = asset.assetCache, cache.isPlayableOffline {
            return asset
            
        } else {
            return  nil
            
        }
    }
    
    func getPath() -> String {
        return UserDefaults.standard.value(forKey: "assetPath") as? String ?? ""
    }
    
    func deleteOfflineAsset() {
        do {
            let userDefaults = UserDefaults.standard
            if let assetPath = userDefaults.value(forKey: "assetPath") as? String {
                let baseURL = URL(fileURLWithPath: NSHomeDirectory())
                let assetURL = baseURL.appendingPathComponent(assetPath)
                try FileManager.default.removeItem(at: assetURL)
                userDefaults.removeObject(forKey: "assetPath")
            }
        } catch {
            print("An error occured deleting offline asset: \(error)")
        }
    }
    func downloadAsset(_ url: URL, _ assetKey:String) {
        if let downloadTask = downloadingMap[url] {
            if (downloadTask.state == .suspended) {
                downloadTask.resume()
            }
            if (downloadTask.state == .running) {
                downloadTask.suspend()
            }
        }else {
            let asset = AVURLAsset(url: url)
            // Create new AVAssetDownloadTask for the desired asset
            // Passing a nil options value indicates the highest available bitrate should be downloaded
            let downloadTask = downloadSession.makeAssetDownloadTask(asset: asset,
                                                                     assetTitle: "downloadAsset",
                                                                     assetArtworkData: nil,
                                                                     options:nil)!
            downloadingMap[url] = downloadTask
            downloadTask.taskDescription = assetKey
            // Start task
            downloadTask.resume()
        }
    }
    func getPlayerItem(_ assetKey:String) -> AVPlayerItem? {
        guard let location = UserDefaults.standard.url(forKey: assetKey) else {
            return nil
        }
        if (!FileManager.default.fileExists(atPath: location.relativePath)) {
            return nil
        }
        let asset = AVURLAsset(url: location)
        let playerItem = AVPlayerItem(asset: asset)
        return playerItem
    }
}

extension DownloadManager: AVAssetDownloadDelegate {
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        var percentComplete = 0.0
        
        for value in loadedTimeRanges {
            
            let loadedTimeRange = value.timeRangeValue
            
            percentComplete += loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
        
        debugPrint("Progress \( assetDownloadTask) \(percentComplete)")
        
        let params = ["percent": percentComplete]
        NotificationCenter.default.post(name: .DownloadProgressNotification, object: nil, userInfo: params)
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        print(location)
        guard let assetKey = assetDownloadTask.taskDescription else {
            return
        }
        UserDefaults.standard.set(location, forKey:assetKey)
        UserDefaults.standard.synchronize()
    }
    //MARK: - URLSessionTaskDelegate
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        debugPrint("Download finished: \(location)")
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        guard error == nil else {
            debugPrint("Task completed: \(task), error: \(String(describing: error))")
            return
        }
        guard let task = task as? AVAssetDownloadTask else { return }
        
        print("DOWNLOAD: FINISHED")
    }
}
extension Notification.Name {
    
    /// Notification for when download progress has changed.
    static let DownloadProgressNotification = NSNotification.Name(rawValue: "downloadProgress")
}
