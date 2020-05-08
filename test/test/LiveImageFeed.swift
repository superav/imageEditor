//
//  LiveImageFeed.swift
//  test
//
//  Created by Jessica Zhang on 5/2/20.
//  Copyright © 2020 Jessica Zhang. All rights reserved.
//

import UIKit
import CoreML
import AVFoundation

protocol FrameExtractorDelegate: class {
    func captured(image:UIImage)
}

class FrameExtractor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let position = AVCaptureDevice.Position.front
    private let quality = AVCaptureSession.Preset.medium
    
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "live camera")
    private let context = CIContext()
    private var permissionGranted = false
    
    weak var delegate: FrameExtractorDelegate?
    let numStyles = 9
    var stylizeEnabled = false
    
    override init() {
        super.init()
        checkPermissions()
        
        sessionQueue.async { [unowned self] in
            self.configureSession()
            self.captureSession.startRunning()
        }
    }
    
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            
        case .notDetermined:
            requestPermission()
            
        default:
            permissionGranted = false
        }
    }
    
    private func requestPermission() {
        sessionQueue.suspend()
        
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    private func selectCaptureDevice() -> AVCaptureDevice? {
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: .video, position: position).devices.first
    }
    
    func configureSession() {
        guard permissionGranted else { return }
        captureSession.sessionPreset = quality
        guard let captureDevice = selectCaptureDevice() else { return }
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        guard captureSession.canAddInput(captureDeviceInput) else { return }
        captureSession.addInput(captureDeviceInput)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "Video Sample Buffer"))
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)
        
        guard let connection = videoOutput.connection(with: .video) else { return }
        guard connection.isVideoOrientationSupported else { return }
        guard connection.isVideoMirroringSupported else { return }
        connection.videoOrientation = .portrait
        connection.isVideoMirrored = position == .front
    }
    
    private func getImageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil}
        return UIImage(cgImage: cgImage)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let ogImage = getImageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        var uiImage = ogImage
        
        if stylizeEnabled {
            let ciImage = stylizePic(inputImg: ogImage, styleIndex: Int.random(in: 0..<self.numStyles))
            uiImage = UIImage(ciImage: ciImage)
        }
        
        DispatchQueue.main.async { [unowned self] in
            self.delegate?.captured(image: uiImage)
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
        let output = try? model.prediction(image: pixelBuffer!, index: styleArray!)
        let predImage = CIImage(cvPixelBuffer: (output?.stylizedImage)!) // output image
        return predImage
    }
    
    func checkStylized(){
        if stylizeEnabled{
            print("stylized")
        }
    }
    
    deinit {
        print("Live Image Feed Deinitialized")
    }
}
