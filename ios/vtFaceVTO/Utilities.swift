//
//  Utilities.swift
//  VtFacevto
//
//  Created by Muhammad Syahman on 16/04/2020.
//  Copyright © 2020 Vettons. All rights reserved.
//

import Foundation
import SceneKit

/// Utilities class
var util = Utilities()
//var lut = lutFX()

/// AR Model type
/// Can be added later for positioning and scaling for each type of VTO
enum VTARModelType{
    case glass
    case earring
    case all
    
    /// Get the asset position
    func assetPosition() -> simd_float3{
        switch self {
        case .glass:
            return simd_float3(0,2.7,9.5) * 0.01
        case .earring:
            return simd_float3(0,2.7,9.5) * 0.01
        default:
            return simd_float3(0,0,0) * 0.01
        }
    }
    
    /// Get the asset scale
    func assetScale() -> simd_float3{
        switch self {
        case .glass:
            return simd_float3(1,1,1) * 0.01
        case .earring:
            return simd_float3(1,1,1) * 0.01
        default:
            return simd_float3(1,1,1) * 0.01
        }
    }
}

/// AR Asset to store global values
struct ARAsset {
    static var modelURL: URL?
    static var textureURL: URL?
    static var vtoType: VTOType?
    static var isModelAvailable: Bool = false
    static var isTextureAvailable: Bool = false
}

enum VTOType {
    case makeup
    case glass
    case sample
    case glassWithMakeup
    case sampleWithMakeup
}

struct vcDismiss {
    /// VC Dismiss state
    static var state : Bool = false
}

/// Utilities class to hold all utilities func
class Utilities {
    /// Add watermark onto the image at the bottom right
    ///
    /// - Parameter image: UIImage object of the image
    /// - Parameter markImage: UIImage watermark
    /// - Parameter view: UIView current view. Needed for bounds
    /// - Returns: Return a UIImage of the watermarked image
    func addWatermark(_ image: UIImage, markImage: UIImage, view: UIView) -> UIImage{
        
        let markImageWidth = markImage.size.width/2
        let markImageHeight = markImage.size.height/2
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        let frameWidth = view.bounds.width
        let ratio = imageWidth/frameWidth
        let markImagePosX = imageWidth - markImageWidth - 25*ratio
        let markImagePosY = imageHeight - markImageHeight - 25*ratio
        
        //        Start Drawing
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0)
        image.draw(in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        markImage.draw(in: CGRect(x: markImagePosX, y: markImagePosY, width: markImageWidth, height: markImageHeight), blendMode: CGBlendMode.screen, alpha: 0.8)
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        //        End Drawing
        
        return finalImage!
    }
}

class lutFX {
    
    static func colorCubeFilterFromLUT(imageName : String) -> CIFilter? {
        
        let size = 64
        
        let lutImage    = UIImage(named: imageName)!.cgImage
        let lutWidth    = lutImage!.width
        let lutHeight   = lutImage!.height
        let rowCount    = lutHeight / size
        let columnCount = lutWidth / size
        
        if ((lutWidth % size != 0) || (lutHeight % size != 0) || (rowCount * columnCount != size)) {
            NSLog("Invalid colorLUT %@", imageName);
            return nil
        }
        
        let bitmap  = getBytesFromImage(image: UIImage(named: imageName))!
        let floatSize = MemoryLayout<Float>.size
        
        let cubeData = UnsafeMutablePointer<Float>.allocate(capacity: size * size * size * 4 * floatSize)
        var z = 0
        var bitmapOffset = 0
        
        for _ in 0 ..< rowCount {
            for y in 0 ..< size {
                let tmp = z
                for _ in 0 ..< columnCount {
                    for x in 0 ..< size {
                        
                        let alpha   = Float(bitmap[bitmapOffset]) / 255.0
                        let red     = Float(bitmap[bitmapOffset+1]) / 255.0
                        let green   = Float(bitmap[bitmapOffset+2]) / 255.0
                        let blue    = Float(bitmap[bitmapOffset+3]) / 255.0
                        
                        let dataOffset = (z * size * size + y * size + x) * 4
                        
                        cubeData[dataOffset + 3] = alpha
                        cubeData[dataOffset + 2] = red
                        cubeData[dataOffset + 1] = green
                        cubeData[dataOffset + 0] = blue
                        bitmapOffset += 4
                    }
                    z += 1
                }
                z = tmp
            }
            z += columnCount
        }
        
        let colorCubeData = NSData(bytesNoCopy: cubeData, length: size * size * size * 4 * floatSize, freeWhenDone: true)
        
        // create CIColorCube Filter
        let filter = CIFilter(name: "CIColorCube")
        filter?.setValue(colorCubeData, forKey: "inputCubeData")
        filter?.setValue(size, forKey: "inputCubeDimension")
        
        return filter
    }
    
    
    static func getBytesFromImage(image:UIImage?) -> [UInt8]?
    {
        var pixelValues: [UInt8]?
        if let imageRef = image?.cgImage {
            let width = Int(imageRef.width)
            let height = Int(imageRef.height)
            let bitsPerComponent = 8
            let bytesPerRow = width * 4
            let totalBytes = height * bytesPerRow
            
            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            var intensities = [UInt8](repeating: 0, count: totalBytes)
            
            let contextRef = CGContext(data: &intensities, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
            contextRef?.draw(imageRef, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)))
            
            pixelValues = intensities
        }
        return pixelValues!
    }
    
}

enum photoFX: CaseIterable {
    case CIPhotoEffectFade, CIPhotoEffectInstant, CIPhotoEffectMono, CIPhotoEffectChrome, CIThermal, CIXRay, CIPhotoEffectTonal
    
    static func random() -> String{
        let a = photoFX.allCases.randomElement()
        
        switch a {
        case .CIPhotoEffectChrome:
            return "CIPhotoEffectChrome"
        case .CIPhotoEffectInstant:
            return "CIPhotoEffectInstant"
        case .CIPhotoEffectMono:
            return "CIPhotoEffectMono"
        case .CIPhotoEffectFade:
            return "CIPhotoEffectFade"
        case .CIThermal:
            return "CIThermal"
        case .CIXRay:
            return "CIXRay"
        case .CIPhotoEffectTonal:
            return "CIPhotoEffectTonal"
        case .none:
            return "none"
        }
    }
}
