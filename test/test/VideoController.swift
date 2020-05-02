//
//  VideoController.swift
//  test
//
//  Created by Jessica Zhang on 4/30/20.
//  Copyright © 2020 Jessica Zhang. All rights reserved.
//

import UIKit
import AVKit

class VideoController: UIViewController, FrameExtractorDelegate {
    
    
    
//    @IBOutlet weak var playerView: AVPlayerView!
    @IBOutlet weak var imageOutlet: UIImageView!
    var frameExtractor: FrameExtractor!
    
//    var url: URL?
//
    override func viewDidLoad() {
        super.viewDidLoad()
        
        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self
        
        // Do any additional setup after loading the view.
//        guard let videoUrl = Bundle.main.url(forResource: "video", withExtension: ".MOV", subdirectory: "app_assets") else {
//            return
        }
//
//        url = videoUrl
//    }
//
//    @IBAction func playButtonPressed(_ sender: UIButton) {
//        playVideo()
//    }
//
//    func playVideo(){
//        if let videoUrl = url { playerView.play(with: videoUrl)}
//    }
    
    func captured(image: UIImage) {
        imageOutlet.image = image
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
