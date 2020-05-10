//
//  VideoController.swift
//  test
//
//  Created by Jessica Zhang on 4/30/20.
//  Copyright © 2020 Jessica Zhang. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Accelerate

class VideoController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var imageOutlet: UIImageView!
    
    var captureSession: AVCaptureSession?
    var captureDevice: AVCaptureDevice?
    var captureDeviceInput: AVCaptureDeviceInput?
    var captureVideoOutput: AVCaptureVideoDataOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var connection: AVCaptureConnection?
    private let context = CIContext()

    var stylizeEnabled = false
    
    var imageBuffer   = createPixelBuffer(width: 1920, height: 1080)!
    var resizedBuffer = createPixelBuffer(width: 480, height: 640)
    
    var mlModelWrapper: green_swirly?
    var inputImage: green_swirlyInput?
    var prediction: green_swirlyOutput?
    var CPUOptions: MLPredictionOptions?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            loadMLModel()
            self.captureSession = AVCaptureSession()
            try configureCaptureDevices()
            try configureDeviceInput()
            try configureCaptureOutput()
            try startCaptureSession()
        } catch {
            return
        }
    }
    
    // load ML Model
    func loadMLModel() {
        let bundle = Bundle(for: green_swirly.self)
        let modelURL = bundle.url(forResource: "green_swirly", withExtension: "mlmodelc")!
        
        mlModelWrapper = try? green_swirly(contentsOf: modelURL)
    }
    
    // Configure rear camera
    func configureCaptureDevices() throws {
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back)
        let cameras = session.devices.map { $0 }
        
        guard !cameras.isEmpty else { throw camError.noCamerasAvailable }
        
        for camera in cameras {
            if camera.position == .back {
                self.captureDevice = camera
                
                try camera.lockForConfiguration()
                camera.focusMode = .continuousAutoFocus
                camera.unlockForConfiguration()
            }
        }
    }
    
    // Configure device input
    func configureDeviceInput() throws {
        guard let captureSession = self.captureSession else { throw camError.captureSessionIsMissing }
        
        if let rearCamera = captureDevice {
            captureDeviceInput = try AVCaptureDeviceInput(device: rearCamera)
            
            if captureSession.canAddInput(captureDeviceInput!){ captureSession.addInput(captureDeviceInput!)}
        } else {
            throw camError.noCamerasAvailable
        }
    }
    
    // Configure output
    func configureCaptureOutput() throws {
        guard let captureSession = self.captureSession else { throw camError.captureSessionIsMissing }
        
        captureVideoOutput = AVCaptureVideoDataOutput()
        captureVideoOutput!.setSampleBufferDelegate(self, queue: DispatchQueue(label: "Sample_Buffer"))
        captureVideoOutput!.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA as UInt32]
        
        captureSession.sessionPreset = .vga640x480
        
        if captureSession.canAddOutput(captureVideoOutput!) { captureSession.addOutput(captureVideoOutput!)}
    }
    
    // Start capture session
    func startCaptureSession() throws {
        guard let captureSession = self.captureSession else { throw camError.captureSessionIsMissing }
        captureSession.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = .portrait
        
//        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        do {
            prediction = try mlModelWrapper?.prediction(_0: resizedBuffer!)
        } catch {
            print("Camera warming up")
            return
        }
                
        let ciImage = CIImage(cvImageBuffer: (prediction?._156)!)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)
        
        DispatchQueue.main.async {
            self.imageOutlet.image = uiImage
        }
    }
    
    @IBAction func viewTypeChanged(_ sender: UISegmentedControl) {
        stylizeEnabled = sender.selectedSegmentIndex == 1
    }
    
    @IBAction func check(_ sender: UIButton) {
        if stylizeEnabled {
            print("Style enabled")
        } else {
            print("Style disabled")
        }
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
