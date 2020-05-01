//
//  AVPlayerView.swift
//  test
//
//  Created by Jessica Zhang on 4/30/20.
//  Copyright © 2020 Jessica Zhang. All rights reserved.
//

import UIKit
import AVFoundation

class AVPlayerView: UIView {
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    var player: AVPlayer? {
        get {
            return playerLayer.player
        } set {
            playerLayer.player = newValue
        }
    }
    
    private var playerItemContext = 0
    private var playerItem: AVPlayerItem?
    var url: URL?

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    private func setUpAsset(with url: URL, completion: ((_ asset: AVAsset) -> Void)?){
        let asset = AVAsset(url: url)
        asset.loadValuesAsynchronously(forKeys: ["playable"]){
            var error: NSError? = nil
            let status = asset.statusOfValue(forKey: "playable", error: &error)
            
            switch status {
            case .loaded:
                completion?(asset)
                
            case .failed:
                print("Asset load failed")
                
            case .cancelled:
                print("Asset load cancelled")
                
            default:
                print("Defaulted")
            }
        }
    }
    
    private func setUpPlayerItem(with asset: AVAsset){
        playerItem = AVPlayerItem(asset: asset)
        
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &playerItemContext)
        DispatchQueue.main.async {
            [weak self] in
            self?.player = AVPlayer(playerItem: self?.playerItem!)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            }else{
                status = .unknown
            }
            
            switch status {
            case .readyToPlay:
                print("Video Ready")
                player?.play()
                
            case .failed:
                print("Video playback failed")
                
            case .unknown:
                print("????? lskdjfalksdjfl")
                
            @unknown default:
                print("@?????? lasjdflkjasdlfkj")
            }
        }
    }
    
    func play(with url:URL){
        setUpAsset(with: url) {
            [weak self] (asset: AVAsset) in
            self?.setUpPlayerItem(with: asset)
        }
    }

    deinit {
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        print("Player deinitialized")
    }
}
