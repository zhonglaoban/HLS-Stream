# 使用AVPlayerViewController在线、离线播放hls

这篇文章演示了如何使用AVPlayerViewController播放hls，并且涉及了如何开始、暂停，如何下载、存储一个hls的播放。

## 使用这个示例

请在iOS 11.0或之后的真机上使用Xcode编译、运行此示例。示例中的这些APIs不支持在模拟器中工作。

## 在线播放hls
`AVPlayer`有很多初始化方式，我们这里采用最简单的通过url初始化。
`AVPlayerViewController`可以快速的创建一个播放器，使用简单。
将`AVPlayer`设置给`AVPlayerViewController`，就能播放视频啦。
```swift
guard let url = URL(string: "http://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8") else { return }
let onlinePlayer = AVPlayer(url: url)
playerViewController?.player = onlinePlayer
```
## 离线播放hls
在iOS10 之后，苹果为`AVAssetDownloadTask`提供了一个方法`makeAssetDownloadTask`用来下载hls。需要注意的是，下载下来的hls必须是一个`AVURLAsset`，它在本地存储为movpkg格式。
### 初始化配置并下载hls
创建一个类`DownloadManager`，添加`URLSessionConfiguration`和`AVAssetDownloadURLSession`的实例作为属性。`init()`的时候初始化属性。在这里我们可以设置一个代理为自己，我们在代理方法里面就可以监听到一些下载相关的事件。
```swift
private var config: URLSessionConfiguration!
private var downloadSession: AVAssetDownloadURLSession!

config = URLSessionConfiguration.background(withIdentifier: "background")
downloadSession = AVAssetDownloadURLSession(configuration: config, assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
```
### 获取下载进度和下载的位置
实现代理方法didLoad，它有三个值：
- timeRange：上一次调用的时间
- loadedTimeRanges：已下载每个资源耗费的时间
- timeRangeExpectedToLoad：总预期的时间

我们可以计算每一个资源的进度，综合起来就是这个下载任务的进度。然后我们把得到的进度以通知的形式发送给监听者。
```swift
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
```
当文件下载完成时，会通过didFinishDownloadingTo代理方法告诉我们下载位置。我们把这个位置存起来，就可以在任何其他地方获取并使用了。我这里是使用task的taskDescription作为key存在了UserDefaults中。
```swift
func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
    print(location)
    guard let assetKey = assetDownloadTask.taskDescription else {
        return
    }
    UserDefaults.standard.set(location, forKey:assetKey)
    UserDefaults.standard.synchronize()
}
```
### 读取并播放hls
我先用UserDefaults取出之前下载完成的文件地址，然后返回一个`AVPlayerItem`实例给`AVPlayer`使用，这样就可以播放之前下载好的hls了。
```swift
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
```
 
## Requirements

### Build

Xcode 9.0 or later; iOS 11.0 SDK or later

### Runtime

iOS 11.0 or later.

Copyright (C) 2017 Apple Inc. All rights reserved.
