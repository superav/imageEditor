//
//  ViewController.swift
//  test
//
//  Created by Jessica Zhang on 4/17/20.
//  Copyright © 2020 Jessica Zhang. All rights reserved.
//

import UIKit
import CoreML

class ViewController: UIViewController {
    @IBOutlet weak var imageOutlet: UIImageView!
    @IBOutlet var sliderOutlets: [UISlider]!
    @IBOutlet weak var remixButton: UIButton!
    
    let sampleImage = UIImage(named: "sample")
    var beginImage: CIImage!
    var colorFilter: CIFilter!
//    var gaussFilter: CIFilter!
    var context: CIContext!
    
    let numStyles = 9
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        colorFilter = CIFilter(name: "CIColorControls")
//        gaussFilter = CIFilter(name: "CIGaussianBlur")
        beginImage = CIImage(image: sampleImage!)
        
        context = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
        
        colorFilter.setValue(beginImage, forKey: kCIInputImageKey)
        
        imageOutlet.image = sampleImage
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
    
//    @IBAction func changeBlue(_ sender: UISlider) {
//        let image = CIImage(image: imageOutlet.image!)
//        gaussFilter.setValue(image, forKey: kCIInputImageKey)
//        gaussFilter.setValue(sender.value, forKey: kCIInputRadiusKey)
//        let outputImage = gaussFilter.outputImage
//        
//        if let cgImage = context!.createCGImage(outputImage!, from: outputImage!.extent){
//            imageOutlet.image = UIImage(cgImage: cgImage)
//        }
//    }
    
    @IBAction func loadImage(_ sender: UIButton) {
        AttachmentHandler.handler.showAttachmentActionSheet(vc: self)
        AttachmentHandler.handler.imagePickedBlock = {(image) in
//            print(image)
            self.beginImage = CIImage(image: image)
            self.colorFilter.setValue(self.beginImage, forKey: kCIInputImageKey)
            self.imageOutlet.image = image
            
            self.resetFiltersAndSliders()
        }
        AttachmentHandler.handler.videoPickedBlock = {(video) in
            print("VIDEO")
        }
    }


//ML STUFF BEGINS DOWN HERE
    
    @IBAction func remixPressed(_ sender: Any) {
        stylizePic()
    }
    
    func stylizePic(){
        let styleIndex = Int.random(in: 0..<numStyles)
        let styleArray = try? MLMultiArray(shape: [numStyles] as [NSNumber], dataType: MLMultiArrayDataType.double)
        for i in 0...((styleArray?.count)!-1){
            styleArray?[i] = 0.0
        }
        
        styleArray?[styleIndex] = 1.0
        
        let model = Trial3()
        
        let modelInputSize = CGSize(width: 256, height: 256)
        
        var pixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        CVPixelBufferCreate(kCFAllocatorDefault,
                            Int(modelInputSize.width),
                            Int(modelInputSize.height),
                            kCVPixelFormatType_32BGRA,
                            attrs,
                            &pixelBuffer)
        let context = CIContext()
        context.render(beginImage, to: pixelBuffer!)
        let output = try? model.prediction(image: pixelBuffer!, index: styleArray!)
        let predImage = CIImage(cvPixelBuffer: (output?.stylizedImage)!)
        imageOutlet.image = UIImage(ciImage: predImage)
    }
    
    /*
    func stylizePic(){
        let model = Trial3();
        let styleArray = try? MLMultiArray(shape: [1] as [NSNumber], dataType: .double)
        styleArray?[0] = 1.0
        
        if let image = pixelBuffer(from: imageOutlet.image!) {
            do {
                let predictionOutput = try model.prediction(image: image, index: styleArray!)
                        
                let ciImage = CIImage(cvPixelBuffer: predictionOutput.stylizedImage)
                let tempContext = CIContext(options: nil)
                let tempImage = tempContext.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(predictionOutput.stylizedImage), height: CVPixelBufferGetHeight(predictionOutput.stylizedImage)))
                imageOutlet.image = UIImage(cgImage: tempImage!)
            } catch let error as NSError {
                print("CoreML Model Error: \(error)")
            }
        }
    }
    
    
    
    func pixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 256, height: 256), true, 2.0)
        image.draw(in: CGRect(x: 0, y: 0, width: 256, height: 256))
        _ = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
     
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, 256, 256, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
           
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: 256, height: 256, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: 256)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: 256, height: 256))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
            
        return pixelBuffer
    }


*/

}

