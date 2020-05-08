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
import AssetsLibrary

class ViewController: UIViewController {
    @IBOutlet weak var imageOutlet: UIImageView!
    @IBOutlet var sliderOutlets: [UISlider]!
    @IBOutlet weak var remixButton: UIButton!
    
    let sampleImage = UIImage(named: "sample")
    let loadingScreen = LoadingScreen()
    var beginImage: CIImage!
    var colorFilter: CIFilter!
    private var context: CIContext!
    private var playerVC: AVPlayerViewController?
    private var videoURL: URL?
    private var frameGenerator: AVAssetImageGenerator!
    var frames: [UIImage]!
    
    let numStyles = 9
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // Do any additional setup after loading the view.
        colorFilter = CIFilter(name: "CIColorControls")
        beginImage = CIImage(image: sampleImage!)
        
        context = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
        
        colorFilter.setValue(beginImage, forKey: kCIInputImageKey)
//        imageOutlet.image = sampleImage
        playerVC = nil
        print("loaded")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.addSubview(loadingScreen)
        loadingScreen.hide()
    }
    
    func grabFrames() {
        guard let vidURL = videoURL else { return }
        
        let asset = AVAsset(url: vidURL)
        let duration = CMTimeGetSeconds(asset.duration)
        
        self.frameGenerator = AVAssetImageGenerator(asset: asset)
        self.frameGenerator.appliesPreferredTrackTransform = true
        self.frames = []
        
        for index in 0..<Int(duration){
            getFrame(fromTime: Float64(index))
        }
        
        self.frameGenerator = nil
    }
    
    private func getFrame(fromTime: Float64) {
        let time:CMTime = CMTimeMakeWithSeconds(fromTime, preferredTimescale:600)
        let image:CGImage
        do {
           try image = self.frameGenerator.copyCGImage(at:time, actualTime:nil)
        } catch {
           return
        }
        
        self.frames.append(UIImage(cgImage: image))
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
    
    @objc func saveImage(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer){
        if let error = error {
            let errorAlert = UIAlertController(title: "Save Error", message: error.localizedDescription, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "Ok", style: .default))
            
            present(errorAlert, animated: true)
        } else {
            let savedAlert = UIAlertController(title: "Image Saved", message: "Image saved to Photos Library", preferredStyle: .alert)
            savedAlert.addAction(UIAlertAction(title: "Ok", style: .default))
            
            present(savedAlert, animated: true)
        }
    }
    
    @objc func saveVideo(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer){
        if let error = error {
            let errorAlert = UIAlertController(title: "Save Error", message: error.localizedDescription, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "Ok", style: .default))
            
            present(errorAlert, animated: true)
        } else {
            let savedAlert = UIAlertController(title: "Video Saved", message: "Video saved to Photos Library", preferredStyle: .alert)
            savedAlert.addAction(UIAlertAction(title: "Ok", style: .default))
            
            present(savedAlert, animated: true)
        }
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
            self.videoURL = nil
            
            self.resetFiltersAndSliders()
        }
        AttachmentHandler.handler.videoPickedBlock = {(videoURL) in
            self.playerVC = AVPlayerViewController()
            self.playerVC!.player = AVPlayer(url: videoURL)
            self.videoURL = videoURL
            guard let thumbnail = self.generateVideoThumbnail(url: videoURL) else { return }

            self.beginImage = CIImage(image: thumbnail)
            self.colorFilter.setValue(self.beginImage, forKey: kCIInputImageKey)
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
    
    @IBAction func saveMedia(_ sender: UIButton) {
        if let _ = playerVC, let vidURL = videoURL {
            let videoPath = vidURL.absoluteString
            
            if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoPath) {
                UISaveVideoAtPathToSavedPhotosAlbum(videoPath, self, #selector(saveVideo(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        } else {
            guard let outputImage = imageOutlet.image else { return }
            UIImageWriteToSavedPhotosAlbum(outputImage, self, #selector(saveImage(_:didFinishSavingWithError:contextInfo:)), nil)
        }
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
            
//            if let videoURL = self.videoURL {
//                self.grabFrames()
//                
//                for frame in self.frames {
//                    ciImage = self.stylizePic(inputImg: frame, styleIndex: styleIndex)
//                }
//            }
            
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

