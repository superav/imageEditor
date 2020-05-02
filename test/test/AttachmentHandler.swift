//
//  AttachmentHandler.swift
//  test
//
//  Created by Jessica Zhang on 4/19/20.
//  Copyright © 2020 Jessica Zhang. All rights reserved.
//
// Reference: https://medium.com/@deepakrajmurugesan/swift-access-ios-camera-photo-library-video-and-file-from-user-device-6a7fd66beca2

import UIKit
import Photos
import MobileCoreServices

class AttachmentHandler: NSObject {
    static let handler = AttachmentHandler()
    fileprivate var viewController: UIViewController?
    //    private var permissionGranted = false
    
    var imagePickedBlock: ((UIImage) -> (Void))?
    var videoPickedBlock: ((URL) -> (Void))?
    
    enum FileType {
        case camera, photoLibrary, video
    }
    
    func loadMedia(vc: UIViewController, fileType: FileType){
        viewController = vc
        checkPermissions { permissionGranted in
            if permissionGranted {
                DispatchQueue.main.async {
                    switch fileType {
                    case .camera:
                        self.openCamera()
                        
                    case .video:
                        self.openVideo()
                        
                    case .photoLibrary:
                        self.openPhotos()
                    }
                }
                
            } else {
                DispatchQueue.main.async {
                    self.showSettingsAlert(fileType)
                    
                }
            }
            
        }
        
        //            if permissionGranted {
        //                switch fileType {
        //                case .camera:
        //                    self.openCamera()
        //
        //                case .video:
        //                    self.openVideo()
        //
        //                case .photoLibrary:
        //                    self.openPhotos()
        //                }
        //            } else {
        //                self.showSettingsAlert(fileType)
        //            }
        
    }
    
    func checkPermissions(completion: @escaping (Bool) -> ()) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            completion(true)
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (status) in
                switch status {
                case .authorized:
                    completion(true)
                    //                    DispatchQueue.main.async {
                    //                    permissionGranted = true
                    //                    }
                    
                default:
                    //                    permissionGranted = false
                    completion(false)
                }
            }
            
            //            completion(requestPermission())
            
        default:
            completion(false)
        }
    }
    
//    func requestPermission() -> Bool {
//        var permissionGranted = false
//        PHPhotoLibrary.requestAuthorization { (status) in
//            switch status {
//            case .authorized:
//                DispatchQueue.main.async {
//                    permissionGranted = true
//                }
//                
//            default:
//                permissionGranted = false
//            }
//        }
//        
//        return permissionGranted
//    }
    
    // Camera Access
    func openCamera(){
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            let pickerController = UIImagePickerController()
            pickerController.delegate = self
            pickerController.sourceType = .camera
            viewController?.present(pickerController, animated: true, completion: nil)
        }
    }
    
    // Photos Library Access
    func openPhotos(){
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let pickerController = UIImagePickerController()
            pickerController.delegate = self
            pickerController.sourceType = .photoLibrary
            viewController?.present(pickerController, animated: true, completion: nil)
        }
    }
    
    func openVideo(){
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let pickerController = UIImagePickerController()
            pickerController.delegate = self
            pickerController.sourceType = .photoLibrary
            pickerController.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String]
            viewController?.present(pickerController, animated: true, completion: nil)
        }
    }
    
    func showAttachmentActionSheet(vc: UIViewController){
        viewController = vc
        
        let actionSheet = UIAlertController(title: "Load Image or Video", message: "Choose.", preferredStyle: .actionSheet)
        
        let cameraButton = UIAlertAction(title: "Camera", style: .default) { (action) -> Void in
            self.loadMedia(vc: self.viewController!, fileType: .camera)
        }
        
        let photosButton = UIAlertAction(title: "Photos Library", style: .default) { (action) -> Void in
            self.loadMedia(vc: self.viewController!, fileType: .photoLibrary)
        }
        
        let videoButton = UIAlertAction(title: "Videos", style: .default) { (action) -> Void in
            self.loadMedia(vc: self.viewController!, fileType: .video)
        }
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        actionSheet.addAction(cameraButton)
        actionSheet.addAction(photosButton)
        actionSheet.addAction(videoButton)
        actionSheet.addAction(cancelButton)
        
        vc.present(actionSheet, animated: true, completion: nil)
    }
    
    func showSettingsAlert(_ fileTypeEnum: FileType){
        var alertMessage = ""
        
        switch fileTypeEnum {
        case .camera:
            alertMessage = "Turn camera access on in Settings."
            
        case .photoLibrary:
            alertMessage = "Turn Photo Library access on in Settings."
            
        case .video:
            alertMessage = "Turn Video Library access on in Settings."
        }
        
        let cameraAlert = UIAlertController(title: alertMessage, message: nil, preferredStyle: .alert)
        
        let settingsButton = UIAlertAction(title: "Open Settings", style: .destructive) { (_) -> Void in
            let settingsURL = URL(string: UIApplication.openSettingsURLString)
            
            if let url = settingsURL {
                UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
            }
        }
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        cameraAlert.addAction(settingsButton)
        cameraAlert.addAction(cancelButton)
        
        viewController?.present(cameraAlert, animated: true, completion: nil)
    }
}

// Adding ImagePickerControllerDelegate
extension AttachmentHandler: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        viewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.imagePickedBlock?(image)
        } else {
            print("No Image")
        }
        
        if let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            print("URL: ", videoURL)
            
            let data = NSData(contentsOf: videoURL as URL)!
            print("Size before compression: \(Double(data.length / 1048576)) mb")
            compress(videoURL)
        } else{
            print("No Video")
        }
        
        viewController?.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func compress(_ videoURL: URL){
        let compressURL = URL(fileURLWithPath: NSTemporaryDirectory() + NSUUID().uuidString + ".MOV")
        //        let compressURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".MOV")
        
        compressVideo(inputURL: videoURL, outputURL: compressURL) { (exportSession) in
            guard let session = exportSession else {
                return
            }
            
            switch session.status {
            case .completed:
                guard let compressedData = NSData(contentsOf: compressURL) else {
                    return
                }
                
                print("Size after compression \(Double(compressedData.length / 1048576)) mb")
                
                DispatchQueue.main.async {
                    self.videoPickedBlock?(compressURL)
                }
                
            default:
                break
            }
        }
    }
    
    // Video compression
    func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?) -> Void){
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPreset1280x720) else {
            handler(nil)
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mov
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously {
            () -> Void in handler(exportSession)
        }
    }
}
