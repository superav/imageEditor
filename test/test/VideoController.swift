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
    
    @IBOutlet weak var imageOutlet: UIImageView!
    var frameExtractor: FrameExtractor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self
        
    }
    
    @IBAction func viewTypeChanged(_ sender: UISegmentedControl) {
        frameExtractor.stylizeEnabled = sender.selectedSegmentIndex == 1
    }
    
    func captured(image: UIImage) {
        imageOutlet.image = image
    }
    
    @IBAction func check(_ sender: UIButton) {
        frameExtractor.checkStylized()
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
