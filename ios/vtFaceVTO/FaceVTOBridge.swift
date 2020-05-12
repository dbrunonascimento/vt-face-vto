//
//  FaceVTOBridge.swift
//  VtFacevto
//
//  Created by Muhammad Syahman on 15/04/2020.
//  Copyright © 2020 Vettons. All rights reserved.
//

import Foundation

@objc(FaceVTO)
class FaceVTOBridge: NSObject {
    
    @available(iOS 12.0, *)
    func gotoVC(){
        let vc = facesVC
        let rootVC = UIApplication.shared.keyWindow?.rootViewController
        vc.modalPresentationStyle = .fullScreen
        rootVC?.present(vc, animated: true, completion: nil)
    }
    
    @available(iOS 12.0, *)
    @objc
    func display(_ url: String,type vtoType: String){

        
        // MARK: VTO Type setting
        
        // Can add more later.
        switch vtoType {
        case "glass":
            ARAsset.vtoType = .glass
            downloadModel(url)
        case "makeup":
            ARAsset.vtoType = .makeup
            downloadTexture(url)
        case "sample":
            ARAsset.vtoType = .sample
        case "sampleWithMakeup":
            ARAsset.vtoType = .sampleWithMakeup
        case "glassWithMakeup":
            ARAsset.vtoType = .glassWithMakeup
        default:
            ARAsset.vtoType = .none
        }
        
        VTOSetup.state = false
        
        gotoVC()
    }
    
    func downloadTexture(_ url: String) {
        let fm = FileManager.default
        let url = URL(string: url)
        let cacheDir = try! fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        let textureName = url!.deletingPathExtension().lastPathComponent
        let textureDL = cacheDir.appendingPathComponent("\(textureName).png")
        
        // MARK:  Texture Download start
        do {
            let textureURL = url
            let textureData = try Data(contentsOf: textureURL!)
            
            if !ARAsset.isTextureAvailable{
                print("vettonsVTO => Texture not Available, proceed to download")
                print("vettonsVTO => Downloading texture")
                try textureData.write(to: textureDL, options: .atomic)
            }   else {
                print("vettonsVTO => Texture available, proceed to go to VC")
            }
            print("vettonsVTO => \(textureDL.absoluteString)")
            
            let imageTexture = UIImage(data: textureData)
            
            ARAsset.faceImage = imageTexture
            
            ARAsset.isTextureAvailable = true
            
        } catch {
            RNEventEmitter.sharedInstance.dispatch(name: "error", body: ["type": "download", "message": "Cannot download texture file to directory"])
            fatalError("vettonsVTO => Cannot download texture file to directory")
        }
        
        // MARK:  Texture Download finished
        print("vettonsVTO => texture Downloading Finished")
    }
    
    func downloadModel(_ url: String) {
        
        let fm = FileManager.default
        let url = URL(string: url)
        let modelName = url!.deletingPathExtension().lastPathComponent
        let cacheDir = try! fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        let modelDL = cacheDir.appendingPathComponent("\(modelName).usdz")
        
        // MARK:  Model Download start
        do {
            
            let data  = try Data(contentsOf: url!)
            
            if !ARAsset.isModelAvailable {
                print("vettonsVTO => Model not Available, proceed to download")
                print("vettonsVTO => Downloading 3D Model")
                try data.write(to: modelDL, options: .atomic)
            } else {
                print("vettonsVTO => Model available, proceed to go to VC")
            }
            
            // Set model url to download location
            ARAsset.modelURL = modelDL
            
            // Set model availability to true
            ARAsset.isModelAvailable = true
            
        } catch {
            RNEventEmitter.sharedInstance.dispatch(name: "error", body: ["type": "download", "message": "Cannot download model file to directory"])
            fatalError("vettonsVTO => Cannot download 3D model file to directory")
        }
        
        // MARK: Model Download finished
        print("vettonsVTO => 3D Model Downloading Finished")
    }
    
    @objc
    static func requiresMainQueueSetup() -> Bool {
        return true
    }
}
