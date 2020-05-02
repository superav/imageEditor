//
//  ViewController.swift
//  test
//
//  Created by Jessica Zhang on 4/17/20.
//  Copyright © 2020 Jessica Zhang. All rights reserved.
//

import UIKit
import CoreML
import AVKit

class ViewController: UIViewController {
    @IBOutlet weak var imageOutlet: UIImageView!
    @IBOutlet var sliderOutlets: [UISlider]!
    @IBOutlet weak var remixButton: UIButton!
    
    let sampleImage = UIImage(named: "sample")
    let loadingScreen = LoadingScreen()
    var beginImage: CIImage!
    var colorFilter: CIFilter!
    var context: CIContext!
    var playerVC: AVPlayerViewController?
    
    let numStyles = 9
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        colorFilter = CIFilter(name: "CIColorControls")
        beginImage = CIImage(image: sampleImage!)
        
        context = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
        
        colorFilter.setValue(beginImage, forKey: kCIInputImageKey)
        imageOutlet.image = sampleImage
        playerVC = nil
        print("loaded")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.addSubview(loadingScreen)
        loadingScreen.hide()
    }
    
    func resetFiltersAndSliders() {
        colorFilter = CIFilter(name: "CIColorControls")
        colorFilter.setValue(beginImage, forKey: kCIInputImageKey)
        
        for slider in sliderOutlets {
            switch slider.restorationIdentifier {
            case "sat":
                slider.value = 1.0
                break
                
            case "contrast":
                slider.value = 2.0
                break
                
            default:
                slider.value = 0.5
                break
            }
        }
    }
    
    func reapplyFilters() {
        for slider in sliderOutlets {
            switch slider.restorationIdentifier {
            case "sat":
                colorFilter.setValue(slider.value, forKey: kCIInputSaturationKey)
                break
                
            case "contrast":
                colorFilter.setValue(slider.value, forKey: kCIInputContrastKey)
                break
                
            default:
                colorFilter.setValue(slider.value, forKey: kCIInputBrightnessKey)
                break
            }
        }
    }
    
    func generateVideoThumbnail(url: URL) -> UIImage? {
        let videoAsset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: videoAsset)
        let cgImage = try! imageGenerator.copyCGImage(at: CMTime(seconds: 0, preferredTimescale: 1), actualTime: nil)
        
        return UIImage(cgImage: cgImage)
    }
    
    @IBAction func changeBrightness(_ sender: UISlider) {
        colorFilter.setValue(sender.value / 2, forKey: kCIInputBrightnessKey)
        let outputImage = colorFilter.outputImage
        
        if let cgImage = context!.createCGImage(outputImage!, from: outputImage!.extent){
            imageOutlet.image = UIImage(cgImage: cgImage)
        }
    }
    
    
    @IBAction func changeContrast(_ sender: UISlider) {
        colorFilter.setValue(sender.value / 2, forKey: kCIInputContrastKey)
        let outputImage = colorFilter.outputImage
        
        
        if let cgImage = context!.createCGImage(outputImage!, from: outputImage!.extent){
            imageOutlet.image = UIImage(cgImage: cgImage)
        }
    }
    
    @IBAction func changeGreen(_ sender: UISlider) {
        colorFilter.setValue(sender.value, forKey: kCIInputSaturationKey)
        let outputImage = colorFilter.outputImage
        
        
        if let cgImage = context!.createCGImage(outputImage!, from: outputImage!.extent){
            imageOutlet.image = UIImage(cgImage: cgImage)
        }
    }
    
    @IBAction func revertImage(_ sender: UIButton) {
        imageOutlet.image = UIImage(ciImage: beginImage)
        resetFiltersAndSliders()
    }
    
    
    
    @IBAction func loadImage(_ sender: UIButton) {
        AttachmentHandler.handler.showAttachmentActionSheet(vc: self)
        AttachmentHandler.handler.imagePickedBlock = {(image) in
//            print(image)
            self.beginImage = CIImage(image: image)
            self.colorFilter.setValue(self.beginImage, forKey: kCIInputImageKey)
            self.imageOutlet.image = image
            self.playerVC = nil
            
            self.resetFiltersAndSliders()
        }
        AttachmentHandler.handler.videoPickedBlock = {(videoURL) in
            self.playerVC = AVPlayerViewController()
            self.playerVC!.player = AVPlayer(url: videoURL)
            let thumbnail = self.generateVideoThumbnail(url: videoURL)

            self.imageOutlet.image = thumbnail
        }
    }
    
    // Video player will pop up when preview is tapped
    @IBAction func imageTapped(_ sender: UITapGestureRecognizer) {
        if let videoPlayer = playerVC {
            self.present(videoPlayer, animated: true) {
                videoPlayer.player!.play()
            }
        }
        print("TAPPED")
    }
    

//ML STUFF BEGINS DOWN HERE
    
    @IBAction func remixPressed(_ sender: Any) {
        loadingScreen.show()
        remixButton.isEnabled = false
        for slider in sliderOutlets {
            slider.isEnabled = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            let styleIndex = Int.random(in: 0..<self.numStyles)
                    let styleImage = self.stylizePic(inputImg: self.imageOutlet.image!, styleIndex: styleIndex)
                    self.imageOutlet.image = UIImage(ciImage: styleImage)
                    self.colorFilter.setValue(styleImage, forKey: kCIInputImageKey)
                    self.reapplyFilters()
            
            DispatchQueue.main.async {
                self.loadingScreen.hide()
                self.remixButton.isEnabled = true
                for slider in self.sliderOutlets {
                    slider.isEnabled = false
                }
            }
        }
    }
    
    func stylizePic(inputImg: UIImage, styleIndex: Int) -> CIImage {
        let styleArray = try? MLMultiArray(shape: [numStyles] as [NSNumber], dataType: MLMultiArrayDataType.double)
        for i in 0...((styleArray?.count)!-1){
            styleArray?[i] = 0.0
        }
        
        styleArray?[styleIndex] = 1.0
        
        let model = Trial3()
                
        var pixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        CVPixelBufferCreate(kCFAllocatorDefault,
                            Int(inputImg.size.width),
                            Int(inputImg.size.height),
                            kCVPixelFormatType_32BGRA,
                            attrs,
                            &pixelBuffer)
        
        if let ciImage = inputImg.ciImage {
            context.render(ciImage, to: pixelBuffer!)
        }else {
            context.render(CIImage(cgImage:inputImg.cgImage!), to: pixelBuffer!) // change begin image for video stuff
        }
        var output:Trial3Output? = nil;
        let queue = OperationQueue()
        queue.addOperation {
            output = try? model.prediction(image: pixelBuffer!, index: styleArray!)
        }
        queue.waitUntilAllOperationsAreFinished()
        let predImage = CIImage(cvPixelBuffer: (output?.stylizedImage)!) // output image
        return predImage
    }

}

