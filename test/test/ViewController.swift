//
//  ViewController.swift
//  test
//
//  Created by Jessica Zhang on 4/17/20.
//  Copyright © 2020 Jessica Zhang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var imageOutlet: UIImageView!
    @IBOutlet weak var sliderOutlet: UISlider!
    
    let sampleImage = UIImage(named: "sample")
    var beginImage: CIImage!
    var colorFilter: CIFilter!
//    var gaussFilter: CIFilter!
    var context: CIContext!
//    var filteredImage: CIImage?
        
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        colorFilter = CIFilter(name: "CIColorControls")
//        gaussFilter = CIFilter(name: "CIGaussianBlur")
        beginImage = CIImage(image: sampleImage!)
        
        context = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
        
        colorFilter.setValue(beginImage, forKey: kCIInputImageKey)
        
//        let gaussFilter = CIFilter(name: "CIGaussianBlur")
//        gaussFilter?.setValue(beginImage, forKey: kCIInputImageKey)
//        gaussFilter?.setValue(8, forKey: kCIInputRadiusKey)
//        let outputImage = gaussFilter?.outputImage
//
//
//            if let cgImage = context!.createCGImage(outputImage!, from: outputImage!.extent){
//                imageOutlet.image = UIImage(cgImage: cgImage)
//            }

//        gaussFilter.setValue(beginImage, forKey: kCIInputImageKey)
//        filter.setValue(0.5, forKey: kCIInputBrightnessKey)
//
//        let outputImage = filter.outputImage
//        let cgImage = context.createCGImage(outputImage!, from: outputImage!.extent)
        
        imageOutlet.image = sampleImage

    }

    @IBAction func changeBrightness(_ sender: UISlider) {
        
//        if let prevImage = beginImage{
//            let prevImage = CIImage(image: img)
            
//            filter = CIFilter(name: "CIColorControls")
//            filter?.setValue(prevImage, forKey: kCIInputImageKey)
            colorFilter.setValue(sender.value / 2, forKey: kCIInputBrightnessKey)
        let outputImage = colorFilter.outputImage
            
            if let cgImage = context!.createCGImage(outputImage!, from: outputImage!.extent){
                imageOutlet.image = UIImage(cgImage: cgImage)
            }
//        }
    }
    
        
    @IBAction func changeContrast(_ sender: UISlider) {
//        let prevImage = CIImage(image: sampleImage!)

//        filter = CIFilter(name: "CIColorControls")
        
        colorFilter.setValue(sender.value / 2, forKey: kCIInputContrastKey)
        let outputImage = colorFilter.outputImage
            
            
            if let cgImage = context!.createCGImage(outputImage!, from: outputImage!.extent){
                imageOutlet.image = UIImage(cgImage: cgImage)
            }
        
//        filter?.setValue(beginImage, forKey: kCIInputImageKey)
//        filter?.setValue(sender.value, forKey: kCIInputContrastKey)
//
//        if let outputImage = filter?.outputImage{
//            filteredImage = outputImage
//            imageOutlet.image = UIImage(ciImage: outputImage)
//        }
    }
    
    @IBAction func changeGreen(_ sender: UISlider) {
        colorFilter.setValue(sender.value, forKey: kCIInputSaturationKey)
        let outputImage = colorFilter.outputImage
            
            
            if let cgImage = context!.createCGImage(outputImage!, from: outputImage!.extent){
                imageOutlet.image = UIImage(cgImage: cgImage)
            }
    }
    
    @IBAction func changeBlue(_ sender: UISlider) {
        let gaussFilter = CIFilter(name: "CIGaussianBlur")
        gaussFilter?.setValue(beginImage, forKey: kCIInputImageKey)
        gaussFilter?.setValue(sender.value, forKey: kCIInputRadiusKey)
        let outputImage = gaussFilter?.outputImage
            
            
            if let cgImage = context!.createCGImage(outputImage!, from: outputImage!.extent){
                imageOutlet.image = UIImage(cgImage: cgImage)
            }
        
//        DispatchQueue.main.async {
//            if let img = self.sampleImage{
//                self.imageOutlet.image = OpenCVWrapper.changeSaturation(img, (sender.value - 0.5), 2)
//            }
//        }
    }
    
    
}
