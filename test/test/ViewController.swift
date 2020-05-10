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
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet weak var labelOutlet: UILabel!
    
    let loadingScreen = LoadingScreen()
    var beginImage: CIImage!
    var colorFilter: CIFilter!
    
    private var context: CIContext!
    private var playerVC: AVPlayerViewController?
    private var videoURL: URL?
    private var videoAsset: AVAsset?
    private var isStylized = false
    
    let numStyles = 9
    
    var mlModelWrapper: green_swirly?
    var inputImage: green_swirlyInput?
    var prediction: green_swirlyOutput?
    var CPUOptions: MLPredictionOptions?
    
    let scaleFilter = CIFilter(name: "CILanczosScaleTransform")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadMLModel()
        
        // Do any additional setup after loading the view.
        colorFilter = CIFilter(name: "CIColorControls")
        context = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
        
        // Sample Image
//        let sampleImage = UIImage(named: "sample")
//        beginImage = CIImage(image: sampleImage!)
//        imageOutlet.image = sampleImage
//        colorFilter.setValue(beginImage, forKey: kCIInputImageKey)
        
        // Sample Video
        guard let path = Bundle.main.path(forResource: "video", ofType: ".MOV", inDirectory: "app_assets") else { print("Bad URL"); return }
        self.labelOutlet.text = "Tap thumbnail to play video"
        videoURL = URL(fileURLWithPath: path)
        setupVideoPlayer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.addSubview(loadingScreen)
        loadingScreen.hide()
    }
    
    func loadMLModel() {
        let bundle = Bundle(for: green_swirly.self)
        let modelURL = bundle.url(forResource: "green_swirly", withExtension: "mlmodelc")!
        
        mlModelWrapper = try? green_swirly(contentsOf: modelURL)
    }
    
    func setupVideoPlayer() {
        guard let vidURL = videoURL else { return }
        
        isStylized = false
        playerVC = AVPlayerViewController()
        videoAsset = AVAsset(url: vidURL)
        
        let playerItem = AVPlayerItem(asset: videoAsset!)
        playerItem.seekingWaitsForVideoCompositionRendering = true
        playerItem.videoComposition = generateVideoComposition(for: videoAsset!, stylize: false)
        
        self.playerVC!.player = AVPlayer(playerItem: playerItem)
        guard let thumbnail = generateVideoThumbnail(url: vidURL) else { return }
        
        beginImage = CIImage(image: thumbnail)
        colorFilter.setValue(beginImage, forKey: kCIInputImageKey)
        imageOutlet.image = thumbnail
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
                slider.value = 0.5
                break
                
            default:
                slider.value = 0.0
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
                colorFilter.setValue(slider.value * 2, forKey: kCIInputContrastKey)
                break
                
            default:
                colorFilter.setValue(slider.value / 5, forKey: kCIInputBrightnessKey)
                break
            }
        }
        
        let outputImage = colorFilter.outputImage
        
        if let cgImage = context!.createCGImage(outputImage!, from: outputImage!.extent){
            imageOutlet.image = UIImage(cgImage: cgImage)
        }
    }
    
    func generateVideoThumbnail(url: URL) -> UIImage? {
        guard let videoAsset = videoAsset else { return nil }
        let imageGenerator = AVAssetImageGenerator(asset: videoAsset)
        let cgImage = try! imageGenerator.copyCGImage(at: CMTime(seconds: 0, preferredTimescale: 1), actualTime: nil)
        
        return UIImage(cgImage: cgImage)
    }
    
    func generateCGImage(from ciImage: CIImage) -> CGImage? {
        return context.createCGImage(ciImage, from: ciImage.extent)
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
    
    func exportFinished(_ avExportSession: AVAssetExportSession) {
        guard
            avExportSession.status == .completed, let outputURL = avExportSession.outputURL
            else {
                return }
        
        UISaveVideoAtPathToSavedPhotosAlbum(outputURL.path, self, #selector(saveVideo(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @IBAction func changeBrightness(_ sender: UISlider) {
        colorFilter.setValue(sender.value / 5, forKey: kCIInputBrightnessKey)
        let outputImage = colorFilter.outputImage
        
        if let cgImage = context!.createCGImage(outputImage!, from: outputImage!.extent){
            imageOutlet.image = UIImage(cgImage: cgImage)
        }
    }
    
    
    @IBAction func changeContrast(_ sender: UISlider) {
        colorFilter.setValue(sender.value * 2, forKey: kCIInputContrastKey)
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
        if videoURL != nil {
            setupVideoPlayer()
        } else {
            imageOutlet.image = UIImage(ciImage: beginImage)
        }
        
        resetFiltersAndSliders()
    }
    
    @IBAction func loadImage(_ sender: UIButton) {
        AttachmentHandler.handler.showAttachmentActionSheet(vc: self)
        AttachmentHandler.handler.imagePickedBlock = {(image) in
            self.beginImage = CIImage(image: image)
            self.colorFilter.setValue(self.beginImage, forKey: kCIInputImageKey)
            self.imageOutlet.image = image
            self.labelOutlet.text = nil
            self.playerVC = nil
            self.videoURL = nil
            
            self.resetFiltersAndSliders()
        }
        AttachmentHandler.handler.videoPickedBlock = {(videoURL) in
            self.videoURL = videoURL
            self.labelOutlet.text = "Tap thumbnail to play video"
            self.setupVideoPlayer()
        }
    }
    
    // Video player will pop up when preview is tapped
    @IBAction func imageTapped(_ sender: UITapGestureRecognizer) {
        if let videoPlayer = playerVC {
            self.present(videoPlayer, animated: true) {
                videoPlayer.player!.play()
            }
        }
    }
    
    @IBAction func saveMedia(_ sender: UIButton) {
        if let _ = playerVC, let vidURL = videoURL, let asset = videoAsset {
            let videoPath = vidURL.path
            
            if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoPath) {
                guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else { return }
                guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .long
                dateFormatter.timeStyle = .short
                let date = dateFormatter.string(from: Date())
                
                exporter.outputURL = directory.appendingPathComponent("exportVideo-\(date).mov")
                exporter.outputFileType = .mov
                exporter.shouldOptimizeForNetworkUse = true
                exporter.videoComposition = generateVideoComposition(for: asset, stylize: isStylized)
                
                for button in buttons {
                    button.isEnabled = false
                    button.alpha = 0.5
                }
                for slider in sliderOutlets {
                    slider.isEnabled = false
                }
                
                exporter.exportAsynchronously() {
                    DispatchQueue.main.async {
                        self.exportFinished(exporter)
                        
                        for button in self.buttons {
                            button.isEnabled = true
                            button.alpha = 1.0
                        }
                        
                        for slider in self.sliderOutlets {
                            slider.isEnabled = true
                        }
                    }
                }
            }
        } else {
            guard let outputImage = imageOutlet.image else { return }
            
            if outputImage.cgImage != nil {
                UIImageWriteToSavedPhotosAlbum(outputImage, self, #selector(saveImage(_:didFinishSavingWithError:contextInfo:)), nil)
            } else{
                guard let ciImage = outputImage.ciImage else { return }
                guard let cgImage = generateCGImage(from: ciImage) else { return }
                
                UIImageWriteToSavedPhotosAlbum(UIImage(cgImage: cgImage), self, #selector(saveImage(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }
    
    
    //ML STUFF BEGINS DOWN HERE
    
    @IBAction func remixPressed(_ sender: Any) {
        loadingScreen.show()
        
        for button in buttons {
            button.isEnabled = false
            button.alpha = 0.5
        }
        
        for slider in sliderOutlets {
            slider.isEnabled = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            let styleIndex = Int.random(in: 0..<self.numStyles)
            
            if let videoURL = self.videoURL {
                self.isStylized = true
                
                self.playerVC = AVPlayerViewController()
                let playerItem = self.stylizeVideo(url: videoURL, styleIndex: styleIndex)
                self.playerVC?.player = AVPlayer(playerItem: playerItem)
                
                let styleImage = self.generateVideoThumbnail(url: videoURL)
                self.imageOutlet.image = styleImage
//                self.colorFilter.setValue(CIImage(image: styleImage!), forKey: kCIInputImageKey)
            } else {
                let styleImage = self.stylizePic(inputImg: UIImage(ciImage: self.beginImage), styleIndex: styleIndex)
                self.imageOutlet.image = UIImage(ciImage: styleImage)
                self.colorFilter.setValue(styleImage, forKey: kCIInputImageKey)
            }
            
            self.reapplyFilters()
            
            DispatchQueue.main.async {
                self.loadingScreen.hide()
                
                for button in self.buttons {
                    button.isEnabled = true
                    button.alpha = 1.0
                }
                
                for slider in self.sliderOutlets {
                    slider.isEnabled = true
                }
            }
        }
    }
    
    func generateVideoComposition(for asset: AVAsset, stylize: Bool) -> AVVideoComposition {
        let composition = AVMutableVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
//            guard let self = self else { request.finish(with: Error); return}
            let inputImage = request.sourceImage
            
            if stylize {
                let styleImage = self.stylizePic(inputImg: UIImage(ciImage: inputImage), styleIndex: 0)
                self.colorFilter.setValue(styleImage, forKey: kCIInputImageKey)
            } else {
                self.colorFilter.setValue(inputImage, forKey: kCIInputImageKey)
            }
            
            let outputImage = self.colorFilter.outputImage
            
            request.finish(with: outputImage!, context: nil)
            
        })
        
        return composition
    }
    
    func stylizeVideo(url: URL, styleIndex: Int) -> AVPlayerItem {
        let asset = videoAsset!
        let playerItem = AVPlayerItem(asset: asset)
        
        playerItem.seekingWaitsForVideoCompositionRendering = true
        playerItem.videoComposition = generateVideoComposition(for: asset, stylize: true)
        
        return playerItem
    }
    
    func stylizePic(inputImg: UIImage, styleIndex: Int) -> CIImage {
        
        let pixelBuffer = createPixelBuffer(width: 480, height: 640)
        let aspectRatio = 480.0/640.0
        let scalingFactor = ((480.0 * 640.0)/(Double(inputImg.size.width) * Double(inputImg.size.height))).squareRoot()
        var scaledCIImage: CIImage
        
        if let ciImage = inputImg.ciImage {
            scaledCIImage = scaleFilter(ciImage, aspectRatio: aspectRatio, scale:scalingFactor)
            context.render(scaledCIImage, to: pixelBuffer!)
            //scaledCIImage = ciImage
        }else {
            scaledCIImage = scaleFilter(CIImage(cgImage:inputImg.cgImage!), aspectRatio: aspectRatio, scale:0.5)
            context.render(scaledCIImage, to: pixelBuffer!) // change begin image for video stuff
            //  scaledCIImage = CIImage(cgImage:inputImg.cgImage!)
        }
        
        do {
            prediction = try mlModelWrapper?.prediction(_0: pixelBuffer!)
        } catch {
            print("No.")
        }
        
//        var output:Trial3Output? = nil;
//        let queue = OperationQueue()
//
//        queue.addOperation {
//            output = try? model.prediction(image: pixelBuffer!, index: styleArray!)
//        }
//
//        queue.waitUntilAllOperationsAreFinished()
        
//        let predImage = CIImage(cvPixelBuffer: (output?.stylizedImage)!) // output image
        let predImage = CIImage(cvPixelBuffer: (prediction?._156)!)
        return predImage
    }
    
    func scaleFilter(_ input:CIImage, aspectRatio: Double, scale: Double) -> CIImage {
        scaleFilter.setValue(input, forKey: kCIInputImageKey)
        scaleFilter.setValue(scale, forKey: kCIInputScaleKey)
        scaleFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
        return scaleFilter.outputImage!
    }
}

