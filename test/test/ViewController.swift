//
//  ViewController.swift
//  test
//
//  Created by Jessica Zhang on 4/17/20.
//  Copyright © 2020 Jessica Zhang. All rights reserved.
//

import UIKit
import CoreML

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
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
        beginImage = CIImage(image: sampleImage!)
        
        context = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
        
        colorFilter.setValue(beginImage, forKey: kCIInputImageKey)
        
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
    
    @IBAction func loadImage(_ sender: UIButton) {
        
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        self.present(pickerController, animated: true, completion: nil)
        //        let actionSheet = UIAlertController(title: "Load Stuff", message: "Choose your action", preferredStyle: .actionSheet)
        //
        //        let imageButton = UIAlertAction(title: "Choose from Photots", style: .default, handler: { (action) -> Void in
        //            // UIImagePickerController
        ////            actionSheet.authoriza
        //            print("Clicked")
        //        })
        //
        //        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
        //            print("Cancelled")
        //        }
        //
        //        actionSheet.addAction(imageButton)
        //        actionSheet.addAction(cancelButton)
        //
        //        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.dismiss(animated: true, completion: nil)
        
        let chosenImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        
        beginImage = CIImage(image: chosenImage)
        colorFilter.setValue(beginImage, forKey: kCIInputImageKey)
        
        imageOutlet.image = chosenImage
//        print(info)
    }


//ML STUFF BEGINS DOWN HERE
    
    func stylizePic(){
        let model = StarryStyle();
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




}

