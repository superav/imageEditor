//
//  VideoController.swift
//  test
//
//  Created by Jessica Zhang on 4/30/20.
//  Copyright © 2020 Jessica Zhang. All rights reserved.
//

import UIKit
import AVKit

class VideoController: UIViewController {
    
    @IBOutlet weak var playerView: AVPlayerView!
    
    var url: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        guard let videoUrl = Bundle.main.url(forResource: "video", withExtension: ".MOV", subdirectory: "app_assets") else {
            return
        }
        
        url = videoUrl
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        playVideo()
    }
    
    func playVideo(){
        if let videoUrl = url { playerView.play(with: videoUrl)}
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
