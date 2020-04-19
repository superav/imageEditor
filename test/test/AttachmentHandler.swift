////
////  AttachmentHandler.swift
////  test
////
////  Created by Jessica Zhang on 4/19/20.
////  Copyright © 2020 Jessica Zhang. All rights reserved.
////
//// Reference: https://medium.com/@deepakrajmurugesan/swift-access-ios-camera-photo-library-video-and-file-from-user-device-6a7fd66beca2
//
//import UIKit
//import Photos
//
//class AttachmentHandler: NSObject {
//    static let handler = AttachmentHandler()
//    fileprivate var viewController: UIViewController?
//    
//    enum FileType {
//        case camera, photoLibrary, video
//    }
//    
//    func loadMedia(vc: UIViewController, fileType: FileType){
//        viewController = vc
//        
//        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
//        
//        switch authorizationStatus{
//        case .authorized:
//            switch fileType {
//            case .camera:
//                openCamera()
//                break
//                
//            case .photoLibrary:
//                openPhotos()
//                break
//                
//            case .video:
//                openVideo()
//                break
//            }
//            
//        case .denied:
//            print("denied.")
//            break
//            
//        case .notDetermined:
//            PHPhotoLibrary.requestAuthorization { (status) in
//                if status == PHAuthorizationStatus.authorized{
//                    switch fileType {
//                    case .camera:
//                        openCamera()
//                        break
//                        
//                    case .photoLibrary:
//                        openPhotos()
//                        break
//                        
//                    case .video:
//                        openVideo()
//                        break
//                    }
//                } else{
//                    print("actively denied")
//                }
//            }
//            break
//            
//        case .restricted:
//            print("restricted")
//            break
//            
//        default:
//            break
//        }
//    }
//    
//    func openCamera(){
//        if UIImagePickerController.isSourceTypeAvailable(.camera){
//            let pickerController = UIImagePickerController()
//            pickerController.delegate = self
//        }
//    }
//    
//    func showActionSheet(vc: UIViewController){
//        viewController = vc
//        
//        let actionSheet = UIAlertController(title: "Load Image or Video", message: "Choose.", preferredStyle: .actionSheet)
//        
//        let imageButton = UIAlertAction(title: "Choose from Photos", style: .default) { (action) -> Void in
//            <#code#>
//        }
//    }
//}
