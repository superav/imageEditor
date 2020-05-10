//
//  AttachmentHandler.swift
//  test
//
//  Created by Jessica Zhang on 4/19/20.
//  Copyright © 2020 Jessica Zhang. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices

class AttachmentHandler: NSObject {
    static let handler = AttachmentHandler()
    fileprivate var viewController: UIViewController?
    
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
                    
                default:
                    completion(false)
                }
            }
                        
        default:
            completion(false)
        }
    }
    
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
            pickerController.videoMaximumDuration = 5.0
            pickerController.allowsEditing = true
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
            self.videoPickedBlock?(videoURL)
        } else{
            print("No Video")
        }
        
        viewController?.dismiss(animated: true, completion: nil)
    }
}
