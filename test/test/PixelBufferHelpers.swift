//
//  PixelBufferHelpers.swift
//  test
//
//  Created by Jessica Zhang on 5/9/20.
//  Copyright © 2020 Jessica Zhang. All rights reserved.
//

import Foundation
import Accelerate
import CoreImage

enum camError: Swift.Error {
    case captureSessionAlreadyRunning
    case captureSessionIsMissing
    case inputsAreInvalid
    case invalidOperation
    case noCamerasAvailable
    case unknown
}

public func createPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)
    
    guard status == kCVReturnSuccess else { print("Error: Failed to create pixel buffer"); return nil}
    return pixelBuffer
}
