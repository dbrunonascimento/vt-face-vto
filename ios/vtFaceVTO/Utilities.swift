//
//  Utilities.swift
//  VtFacevto
//
//  Created by Muhammad Syahman on 16/04/2020.
//  Copyright © 2020 Vettons. All rights reserved.
//

import Foundation
import AVFoundation
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
            //return simd_float3(0,2.7,9.5) * 0.01
            return simd_float3(0,2.4,1.5) * 0.01
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
/*
enum VTOMakeupType{
    case eyeshadow
    case lipstick
    case eyeliner
    case contour
    case highlighter
    case blusher
    case eyebrow
}
*/

/// AR Asset to store global values
struct ARAsset {
    static var modelURL: URL?
    static var textureURL: URL?
    static var faceImage: UIImage?
    static var sliderImage: UIImage?
    static var sliderImageArray: [UIImage] = []
    static var vtoType: VTOType?
    static var isModelAvailable: Bool = false
    static var isTextureAvailable: Bool = false
    static var stringFromRN: String = ""
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

struct VTOSetup {
    static var state: Bool = false
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
        let markImagePosX = imageWidth - markImageWidth - 15*ratio
        let markImagePosY = imageHeight - markImageHeight - 20*ratio
        
        //        Start Drawing
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0)
        image.draw(in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        markImage.draw(in: CGRect(x: markImagePosX, y: markImagePosY, width: markImageWidth, height: markImageHeight), blendMode: CGBlendMode.screen, alpha: 0.8)
        var finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        //        End Drawing
        
        finalImage = UIImage(cgImage: (finalImage?.cgImage)!)
        return finalImage!
    }
    
}


// MARK:- ImageData structs
struct VariantData: Codable {
    // Make sure it follows the JSON value type
    let name: String
    let productVariantID: String
    let faceImage: String
    let sliderImage: String
}

struct VTOSliderItem {
    static var name = "Name"
    static var url = "URL"
    static var productVariantID = "productVariantID"
    static var faceImage = "faceImage"
    static var sliderImage = "sliderImage"
    static var sliderImageArray = [""]
    static var count = 0
    static var outputData = "outputData"
    static var index = 0
}

// MARK:- Vibration for haptics
@available(iOS 12.0, *)
enum Vibration {
    case error
    case success
    case warning
    case light
    case medium
    case heavy
    @available(iOS 13.0, *)
    case soft
    @available(iOS 13.0, *)
    case rigid
    case selection
    case oldSchool

    public func vibrate() {
        switch self {
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .soft:
            if #available(iOS 13.0, *) {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
        case .rigid:
            if #available(iOS 13.0, *) {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .oldSchool:
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }
}
