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
    var context: CIContext!
    
    let numStyles = 9
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        colorFilter = CIFilter(name: "CIColorControls")
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
    
    @IBAction func loadImage(_ sender: UIButton) {
        AttachmentHandler.handler.showAttachmentActionSheet(vc: self)
        AttachmentHandler.handler.imagePickedBlock = {(image) in
//            print(image)
            self.beginImage = CIImage(image: image)
            self.colorFilter.setValue(self.beginImage, forKey: kCIInputImageKey)
            self.imageOutlet.image = image
            
            self.resetFiltersAndSliders()
        }
        AttachmentHandler.handler.videoPickedBlock = {(videoURL) in
            print("VIDEO")
            
        }
    }


//ML STUFF BEGINS DOWN HERE
    
    @IBAction func remixPressed(_ sender: Any) {
        let styleIndex = Int.random(in: 0..<numStyles)
        let styleImage = stylizePic(inputImg: imageOutlet.image!, styleIndex: styleIndex)
        imageOutlet.image = UIImage(ciImage: styleImage)
        colorFilter.setValue(styleImage, forKey: kCIInputImageKey)
        reapplyFilters()
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
//        let context = CIContext()
//        print(inputImg.ciImage)
        
        if let ciImage = inputImg.ciImage {
            context.render(ciImage, to: pixelBuffer!)
        }else {
            context.render(CIImage(cgImage:inputImg.cgImage!), to: pixelBuffer!) // change begin image for video stuff
        }
        let output = try? model.prediction(image: pixelBuffer!, index: styleArray!)
        let predImage = CIImage(cvPixelBuffer: (output?.stylizedImage)!) // output image
        return predImage
//        imageOutlet.image = UIImage(ciImage: predImage)
    }

}

