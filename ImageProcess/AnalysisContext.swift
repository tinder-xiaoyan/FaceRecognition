//
//  AnalysisContext.swift
//  ImageProcess
//
//  Created by Xiao Yan on 1/9/20.
//  Copyright © 2020 Xiao Yan. All rights reserved.
//

import Foundation
import Combine
import UIKit
import CoreImage
import Vision
import Metal
import MetalKit
import MetalPerformanceShaders
import VideoToolbox

final class AnalysisContext {

    var isVision: Bool = false

    var image: UIImage?

    var faceInfosCoreImage: [FaceInfo] {
        return image?.faceInfosFromCoreImage() ?? []
    }

    var faceInfosVision: [FaceInfo] {
        return image?.faceInfosFromVision() ?? []
    }

    var imageWithLandmarks: UIImage? {
        return isVision ? image?.drawLandmarks() : image
    }
}

extension UIImage {

    // Core Image
    func faceInfosFromCoreImage() -> [FaceInfo] {
        let startTime = NSDate().timeIntervalSince1970
        var faceInfos: [FaceInfo] = []

        let cImage = ciImage ?? CIImage(cgImage: cgImage!)

        guard let detector = CIDetector(ofType: CIDetectorTypeFace,
                                        context: nil,
                                        options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else {
            return faceInfos
        }
        let options = [CIDetectorSmile: true, CIDetectorEyeBlink: true]
        let features = detector.features(in: cImage, options: options)
        guard !features.isEmpty else { return faceInfos }

        for feature:CIFaceFeature in (features as! [CIFaceFeature]) {
            var faceInfo = FaceInfo()
            var rect = feature.bounds
            rect = CGRect(x: rect.minX / UIScreen.main.scale,
                          y: rect.minY / UIScreen.main.scale,
                          width: rect.width / UIScreen.main.scale,
                          height: rect.height / UIScreen.main.scale)
            rect.origin.y = size.height - (rect.origin.y + rect.size.height)
            //            combinedRect = combinedRect == nil ? rect : combinedRect!.union(rect)
            faceInfo.faceRect = rect
            faceInfo.hasSmile = feature.hasSmile
            faceInfo.leftEyeClose = feature.leftEyeClosed
            faceInfo.rightEyeClose = feature.rightEyeClosed

            faceInfos.append(faceInfo)
        }

        let endTime = NSDate().timeIntervalSince1970 - startTime
        print("Total Faces: \(faceInfos.count), Time Spend:\(endTime)")
        return faceInfos
    }
}

@available(iOS 11.0, *)
extension UIImage {

    // Vision
    func faceInfosFromVision() -> [FaceInfo] {
        let startTime = NSDate().timeIntervalSince1970
        var faceInfos: [FaceInfo] = []

        let faceDetection = VNDetectFaceLandmarksRequest()
        let requestHandler = VNImageRequestHandler(cgImage: self.cgImage!, orientation: .right, options: [:])
        do {
            try requestHandler.perform([faceDetection])
        } catch {
            print(error)
        }

        guard let results = faceDetection.results as? [VNFaceObservation], !results.isEmpty else { return faceInfos }

        for face in results {
            var faceInfo = FaceInfo()
            faceInfo.face = face
            let w = face.boundingBox.size.width * size.width
            let h = face.boundingBox.size.height * size.height
            let x = face.boundingBox.origin.x * size.width
            let y = face.boundingBox.origin.y * size.height
            let faceRect = CGRect(x: x, y: y, width: w, height: h)
            faceInfo.faceRect = faceRect
            if let leftEye = face.landmarks?.leftEye?.normalizedPoints {
                faceInfo.leftEyePoints = leftEye.compactMap({CGPoint(x: x + $0.x * w, y: y + $0.y * h)})
            }
            if let rightEye = face.landmarks?.rightEye?.normalizedPoints {
                faceInfo.rightEyePoints = rightEye.compactMap({CGPoint(x: x + $0.x * w, y: y + $0.y * h)})
            }
            if let outerLips = face.landmarks?.outerLips?.normalizedPoints {
                faceInfo.outerLipsPoints = outerLips.compactMap({CGPoint(x: x + $0.x * w, y: y + $0.y * h)})
            }
            if let innerLips = face.landmarks?.innerLips?.normalizedPoints {
                faceInfo.innerLipsPoints = innerLips.compactMap({CGPoint(x: x + $0.x * w, y: y + $0.y * h)})
            }
            faceInfos.append(faceInfo)
        }

        let endTime = NSDate().timeIntervalSince1970 - startTime
        print("Total Faces: \(faceInfos.count), Time Spend:\(endTime)")
        return faceInfos
    }

    func drawLandmarks() -> UIImage? {
        guard let faceInfo = faceInfosFromVision().first,
            let faceRect = faceInfo.faceRect else { return self }

        UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return self }

        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)

        context.setStrokeColor(UIColor.red.cgColor)
        context.addRect(faceRect)
        context.setLineWidth(10.0)
        context.strokePath()

        context.setStrokeColor(UIColor.blue.cgColor)
        context.addLines(between: faceInfo.leftEyePoints)
        context.closePath()
        context.strokePath()

        context.setStrokeColor(UIColor.green.cgColor)
        context.addLines(between: faceInfo.rightEyePoints)
        context.closePath()
        context.strokePath()

        context.setStrokeColor(UIColor.yellow.cgColor)
        context.addLines(between: faceInfo.outerLipsPoints)
        context.addLines(between: faceInfo.innerLipsPoints)
        context.closePath()
        context.strokePath()

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

@available(iOS 10.0, *)
extension UIImage {
    func blurrinessResult() -> Int {
        let startTime = NSDate().timeIntervalSince1970

        // Initialize MTL
        guard let mtlDevice = MTLCreateSystemDefaultDevice(),
            let mtlCommandQueue = mtlDevice.makeCommandQueue() else { return 0 }
        // Create a command buffer for the transformation pipeline
        let commandBuffer = mtlCommandQueue.makeCommandBuffer()!
        // These are the two built-in shaders we will use
        let laplacian = MPSImageLaplacian(device: mtlDevice)
        let meanAndVariance = MPSImageStatisticsMeanAndVariance(device: mtlDevice)
        // Load the captured pixel buffer as a texture
        let textureLoader = MTKTextureLoader(device: mtlDevice)
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(self.pixelBuffer(), options: nil, imageOut: &cgImage)
        let sourceTexture = try! textureLoader.newTexture(cgImage: cgImage!, options: nil)
        // Create the destination texture for the laplacian transformation
        let lapDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: sourceTexture.pixelFormat, width: sourceTexture.width, height: sourceTexture.height, mipmapped: false)
        lapDesc.usage = [.shaderWrite, .shaderRead]
        let lapTex = mtlDevice.makeTexture(descriptor: lapDesc)!
        // Encode this as the first transformation to perform
        laplacian.encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: lapTex)
        // Create the destination texture for storing the variance.
        let varianceTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: sourceTexture.pixelFormat, width: 2, height: 1, mipmapped: false)
        varianceTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        let varianceTexture = mtlDevice.makeTexture(descriptor: varianceTextureDescriptor)!
        // Encode this as the second transformation
        meanAndVariance.encode(commandBuffer: commandBuffer, sourceTexture: lapTex, destinationTexture: varianceTexture)
        // Run the command buffer on the GPU and wait for the results
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        // The output will be just 2 pixels, one with the mean, the other the variance.
        var result = [Int8](repeatElement(0, count: 2))
        let region = MTLRegionMake2D(0, 0, 2, 1)
        varianceTexture.getBytes(&result, bytesPerRow: 1 * 2 * 4, from: region, mipmapLevel: 0)
        let variance = result.last!

        let endTime = NSDate().timeIntervalSince1970 - startTime
        print("Blur Detection Time Spend:\(endTime)")

        return Int(variance)
    }

    func pixelBuffer() -> CVPixelBuffer {
        let ciimage = CIImage(image: self)
        //let cgimage = convertCIImageToCGImage(inputImage: ciimage!)
        let tmpcontext = CIContext(options: nil)
        let cgimage =  tmpcontext.createCGImage(ciimage!, from: ciimage!.extent)

        let cfnumPointer = UnsafeMutablePointer<UnsafeRawPointer>.allocate(capacity: 1)
        let cfnum = CFNumberCreate(kCFAllocatorDefault, .intType, cfnumPointer)
        let keys: [CFString] = [kCVPixelBufferCGImageCompatibilityKey, kCVPixelBufferCGBitmapContextCompatibilityKey, kCVPixelBufferBytesPerRowAlignmentKey]
        let values: [CFTypeRef] = [kCFBooleanTrue, kCFBooleanTrue, cfnum!]
        let keysPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 1)
        let valuesPointer =  UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 1)
        keysPointer.initialize(to: keys)
        valuesPointer.initialize(to: values)

        let options = CFDictionaryCreate(kCFAllocatorDefault, keysPointer, valuesPointer, keys.count, nil, nil)

        let width = cgimage!.width
        let height = cgimage!.height

        var pxbuffer: CVPixelBuffer?
        // if pxbuffer = nil, you will get status = -6661
        var status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                         kCVPixelFormatType_32BGRA, options, &pxbuffer)
        status = CVPixelBufferLockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))

        let bufferAddress = CVPixelBufferGetBaseAddress(pxbuffer!)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesperrow = CVPixelBufferGetBytesPerRow(pxbuffer!)
        let context = CGContext(data: bufferAddress,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: bytesperrow,
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue);
        context?.concatenate(CGAffineTransform(rotationAngle: 0))
        context?.concatenate(__CGAffineTransformMake( 1, 0, 0, -1, 0, CGFloat(height) )) //Flip Vertical
        //        context?.concatenate(__CGAffineTransformMake( -1.0, 0.0, 0.0, 1.0, CGFloat(width), 0.0)) //Flip Horizontal


        context?.draw(cgimage!, in: CGRect(x:0, y:0, width:CGFloat(width), height:CGFloat(height)))
        status = CVPixelBufferUnlockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return pxbuffer!
    }
}

struct FaceInfo {
    var face: VNFaceObservation?
    var faceRect: CGRect?
    var hasSmile: Bool = false
    var leftEyeClose: Bool = false
    var rightEyeClose: Bool = false
    var leftEyePoints: [CGPoint] = []
    var rightEyePoints: [CGPoint] = []
    var outerLipsPoints: [CGPoint] = []
    var innerLipsPoints: [CGPoint] = []
}
