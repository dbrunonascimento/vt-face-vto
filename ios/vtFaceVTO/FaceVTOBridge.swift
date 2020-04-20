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
        // vcDismiss.state = false
    }
    
    @available(iOS 12.0, *)
    @objc
    func display(_ url: String,type vtoType: String){
        
        let fm = FileManager.default
        let url = URL(string: url)
        let modelName = url!.deletingPathExtension().lastPathComponent
        let cacheDir = try! fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

        let downloadLocation = cacheDir.appendingPathComponent("\(modelName).usdz")
        
        // MARK: - Download file to Cache Directory
        
        do {
            
            let data  = try Data(contentsOf: url!)
            
            if !ARAsset.isModelAvailable {
                print("vettonsVTO => Model not Available, proceed to download")
                print("vettonsVTO => Downloading 3D Model")
                try data.write(to: downloadLocation, options: .atomic)
            } else {
                print("vettonsVTO => Model available, proceed to go to VC")
            }
            
            // Set model url to download location
            ARAsset.modelURL = downloadLocation
            
            // Set model availability to true
            ARAsset.isModelAvailable = true
            
        } catch {
            RNEventEmitter.sharedInstance.dispatch(name: "error", body: ["type": "download", "message": "Cannot download file to directory"])
            fatalError("vettonsVTO => Cannot download file to directory")
        }
        
        // MARK: - Download finished
        print("vettonsVTO => 3D Model Downloading Finished")
        
        // TODO: - Download face texture from texture url
        
            // Do face texture downloading here
        
        // MARK: - VTO Type setting
        
        // ARAsset.vtoType = .none
        // print("vettonsVTO => ARAsset.vtoType before switch: \(ARAsset.vtoType)")
        
        // Can add more later.
        switch vtoType {
        case "glass":
            ARAsset.vtoType = .glass
        case "makeup":
            ARAsset.vtoType = .makeup
        case "sample":
            ARAsset.vtoType = .sample
        case "sampleWithMakeup":
            ARAsset.vtoType = .sampleWithMakeup
        case "glassWithMakeup":
            ARAsset.vtoType = .glassWithMakeup
        default:
            ARAsset.vtoType = .none
        }
        
        // print("vettonsVTO => vtoType from bridge : \(vtoType)")
        // print("vettonsVTO => ARAsset.vtoType after switch : \(ARAsset.vtoType.debugDescription)")
        // print("vettonsVTO => url from bridge : \(url?.description)")
        
        VTOSetup.state = false
        
        gotoVC()
    }
    
    @objc
    static func requiresMainQueueSetup() -> Bool {
        return true
    }
}
