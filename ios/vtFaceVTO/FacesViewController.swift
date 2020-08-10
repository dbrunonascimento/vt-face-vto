//
//  FacesViewController.swift
//  vtFaceVTO
//
//  Created by Muhammad Syahman on 16/04/2020.
//  Copyright © 2020 Vettons. All rights reserved.
//

/*
 * Copyright 2019 Google LLC. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import UIKit
import CoreMedia
import CoreMotion
import SceneKit
import AVFoundation
import ARCoreAugmentedFaces
import SpriteKit
import CircularCarousel
import SDWebImageWebPCoder

// Filter Test
import CoreImage

@available(iOS 12.0, *)
var facesVC = FacesViewController()

var pos_sliderX: Float = 0
var pos_sliderY: Float = 0
var pos_sliderZ: Float = 0
var isCapturing: Bool = false
var DEBUGMODE: Bool = false



@available(iOS 12.0, *)
/// Demonstrates how to use ARCore Augmented Faces with SceneKit.
public final class FacesViewController: UIViewController {
    
    // MARK: - Camera properties
    
    private let kCameraZNear = CGFloat(0.05)
    private let kCameraZFar = CGFloat(100)
    private var captureDevice: AVCaptureDevice?
    private var captureSession: AVCaptureSession?
    private lazy var cameraImageLayer = CALayer()
    
    // MARK: - Scene properties
    
    private let kCentimetersToMeters: Float = 0.01
    private lazy var faceMeshConverter = FaceMeshGeometryConverter()
    private lazy var sceneView = SCNView()
    private lazy var sceneCamera = SCNCamera()
    private lazy var faceNode = SCNNode()
    private lazy var faceTextureNode = SCNNode()
    private lazy var faceOccluderNode = SCNNode()
    private lazy var faceTextureMaterial = SCNMaterial()
    private lazy var faceOccluderMaterial = SCNMaterial()
    
    private lazy var headOccluderNode = SCNNode()
    private var containerNode: SCNNode?
    private var arModelNode: SCNReferenceNode?
    private var faceImage: UIImage?
    
    private lazy var headOccluder = SCNScene()
    private lazy var scene = SCNScene()
    
    // MARK: - Motion properties
    
    private let kMotionUpdateInterval: TimeInterval = 0.1
    private lazy var motionManager = CMMotionManager()
    
    // MARK: - Face Session properties
    
    private var faceSession : GARAugmentedFaceSession?
    private var currentFaceFrame: GARAugmentedFaceFrame?
    private var nextFaceFrame: GARAugmentedFaceFrame?
    
    // MARK: - AR Assets properties
    
    private var arModelURL: URL? // AR Model URL passed from the bridge
    private var arTextureURL: URL? // Face Texture URL passed from the bridge
    private var arFaceImage: UIImage? // Face Image
    private var vtoType: VTOType? // VTO Type pased from bridge
    
    // MARK: - Resources Bundle properties
    private var assetBundle: Bundle?
    private var faceBundle: Bundle?
    
    // MARK: - Some stuff
    
    var positionOffset: simd_float3?
    var shareImage: UIImage?
    var currentSliderIndex = 0
    
    // MARK: - JSON Stuff
    
    let jsonStringURL = "https://www.json-generator.com/api/json/get/cfFtRgyCOG?indent=2" // Sample json from web
    var variantJSON = "" // JSON of the product variant
    
    // MARK: - UI Stuff
    
    // MARK: - Implementation methods
    
    
    override public func viewWillAppear(_ animated: Bool) {
        print("vettonsVTO => viewWillAppear")
        
        
        
        if !isCapturing {
            if !VTOSetup.state {
                print("vettonsVTO => reloading the scene")
                removeCacheImage()
                variantJSON = ARAsset.stringFromRN
                updateCount(fromJSONString: variantJSON)
                updateSliderImages(fromJSONString: variantJSON)
                setupUI()
                setupScene()
                
            }
        } else {
            setupScene()
            isCapturing.toggle()
        }
        
        
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        print("vettonsVTO => viewDidLoad")
        
        removeCacheImage()
        variantJSON = ARAsset.stringFromRN

        updateCount(fromJSONString: variantJSON)
        updateSliderImages(fromJSONString: variantJSON)
        
        setupAssetBundle()
        setupUI()
        setupScene()
        setupCamera()
        setupMotion()
        
        VTOSetup.state = true
        
        do {
            let fieldOfView = captureDevice?.activeFormat.videoFieldOfView ?? 0
            faceSession = try GARAugmentedFaceSession(fieldOfView: fieldOfView)
            faceSession?.delegate = self
        } catch let error as NSError {
            NSLog("Failed to initialize Face Session with error: %@", error.description)
        }
        
        
    }
    
    func removeCacheImage() {
        print("vettonsVTO => removing all cache image")
        
        for n in 0..<VTOSliderItem.count {
            UserDefaults.standard.removeObject(forKey: "VTOImageURL\(n)")
            UserDefaults.standard.removeObject(forKey: "VTOVariantSliderThumb\(n)")
        }
        
        print("\(VTOSliderItem.count) images in cache has been removed")
    }
    
    private func setupAssetBundle(){
        let bundle = Bundle(for: FacesViewController.self)
        
        let assetPath = bundle.path(forResource: "VTOAsset", ofType: "bundle")
        assetBundle = Bundle(path: assetPath!)
        
        let facePath = bundle.path(forResource: "VTOFaceAsset", ofType: "bundle")
        faceBundle = Bundle(path: facePath!)
        
    }
    
    // MARK: - Setup UI
    
    /// Setup UI
    private func setupUI() {
        
        /// An SKScene to use as overlay on top of SceneKit
        let overlayScene = SKScene()
        /// Using an SKScene to overlay the SceneKit so that UIKit could be used.
        sceneView.overlaySKScene = overlayScene
        
        // MARK: - UI | Setup Capture Button
        // Setup capture button
        let buttonCapture = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        buttonCapture.center.x = self.view.center.x
        buttonCapture.center.y = self.view.frame.height - 100
        let buttonCaptureImage = UIImage(named: "AR_View_Camera", in: assetBundle, compatibleWith: nil)
        
        buttonCapture.setImage(buttonCaptureImage, for: .normal)
        buttonCapture.addTarget(self, action: #selector(captureButtonAction(sender:)), for: .touchUpInside)
        buttonCapture.transform = CGAffineTransform(scaleX: -1, y: 1)
        buttonCapture.layer.cornerRadius = 10
        
        // MARK: - UI | Setup Back Button
        // Setup back button
        let buttonBack = UIButton(frame: CGRect(x: self.view.frame.width - 84, y: 60, width: 54, height: 30))
        let buttonBackImage = UIImage(named: "AR_View_Back", in: assetBundle, compatibleWith: nil)
        
        buttonBack.setImage(buttonBackImage, for: .normal)
        buttonBack.addTarget(self, action:#selector(mainBackButtonAction(sender:)), for: .touchUpInside)
        buttonBack.transform = CGAffineTransform(scaleX: -1, y: 1)
        buttonBack.layer.cornerRadius = 10
        
        // MARK: - UI | Setup GradientTop
        let gradientTop = UIImageView(frame: CGRect(x: 0, y: 0, width: 375, height: 150))
        gradientTop.center.x = self.view.center.x
        gradientTop.image = UIImage(named: "TopGradient", in: assetBundle, compatibleWith: nil)
        
        // MARK: - UI | Setup carouselSlider
        
        let frame = CGRect(x: 0, y: 0, width: self.view.frame.width * 0.90, height: 150)
        let carousel = CircularCarousel(frame: frame)
        carousel.center.x = self.view.center.x
        carousel.center.y = self.view.frame.height - 200
        carousel.transform = CGAffineTransform(scaleX: -1, y: 1)
        
        carousel.delegate = self
        carousel.dataSource = self
        carousel.backgroundColor = .clear
        carousel.layer.cornerRadius = 75
        
        // Adding all view to the overlayScene
        
        if VTOSliderItem.count > 1 { // Carousel only available if it is more than one	
            overlayScene.view?.addSubview(carousel)
        }
        overlayScene.view?.addSubview(gradientTop)
        overlayScene.view?.addSubview(buttonBack)
        overlayScene.view?.addSubview(buttonCapture)
        
    }
    
    @objc func captureButtonAction(sender: UIButton!){
        print("vettonsVTO => Capture button pressed")
        isCapturing.toggle()
        RNEventEmitter.sharedInstance.dispatch(name: "onPress", body: ["type": "capture", "data": ["clicked":true]])
        captureImage()
    }
    
    @objc func mainBackButtonAction(sender: UIButton!){
        print("vettonsVTO => Back button pressed")
        RNEventEmitter.sharedInstance.dispatch(name: "onPress", body: ["type": "dismiss", "data": ["clicked":true, "name":"\(VTOSliderItem.name)", "productVariantID":"\(VTOSliderItem.productVariantID)", "index":currentSliderIndex]])
        
        self.dismiss(animated: true, completion: nil)
        cleanup()
        
        
        ARAsset.vtoType = nil
        vtoType = nil
        
        
        
        
        switch ARAsset.vtoType {
        case .glass:
            cleanup()
        default:
            print("nothing")
        }
    }
    
    private func cleanup() {
        print("cleanup")
        
        
        sceneView.gestureRecognizers?.removeAll()
        sceneView.scene!.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        sceneView.delegate = nil
        sceneView.scene = nil
        sceneView.overlaySKScene = nil
        sceneView.removeFromSuperview()
        sceneView = SCNView()
        self.removeFromParent()
        
        self.view.removeFromSuperview()
    }
    
    // MARK: - Setup Scene
    /// Create the scene view from a scene and supporting nodes, and add to the view.
    /// The scene is loaded from 'fox_face.scn' which was created from 'canonical_face_mesh.fbx', the
    /// canonical face mesh asset.
    /// https://developers.google.com/ar/develop/developer-guides/creating-assets-for-augmented-faces
    private func setupScene() {
        
        // MARK: Set VTO Type
        // Get VTO Type from the bridge
        vtoType = ARAsset.vtoType
        
        // MARK: - AR Model URL

        // Get AR Model URL from the bridge.
        arModelURL = ARAsset.modelURL
        
        // MARK: - Face Texture URL
        
        // Get Face Texture URL from the bridge
        arTextureURL = ARAsset.textureURL
        
        arFaceImage = ARAsset.faceImage
        
        // MARK: - Load model from local
        
        // Get the url of the model (usdz file). Load from local asset
        // let pathURL = Bundle.main.path(forResource: "vglass_2", ofType: "usdz", inDirectory: "Face.scnassets")!
        // let localURL = URL(fileURLWithPath: pathURL)
        
        // MARK: - Initialize Scene, Assets
        
        // let modelRoot = scene.rootNode.childNode(withName: "asset", recursively: false)
        
        let sceneURL = faceBundle?.url(forResource: "Face.scnassets/face", withExtension: "scn")
        let headOccluderURL = faceBundle?.url(forResource: "Face.scnassets/headOccluder", withExtension: "scn")
        
        
        guard let defaultFaceImage = UIImage(named: "Face.scnassets/face_texture.png", in: faceBundle, compatibleWith: nil)
            else {
                fatalError("vettonsVTO => Failed to load Face Texture")
        }
        
        // guard let faceImage = arFaceImage else {
           //  fatalError("vettonsVTO => Failed to load Face Image")
        // }
        
        if vtoType == .some(.makeup){
            faceImage = arFaceImage
        } else {
            faceImage = defaultFaceImage
        }
        
        
        guard let arModelNode = SCNReferenceNode(url: arModelURL!)
            else {
                fatalError("vettonsVTO => Failed to load AR Model")
        }
        
        do {
            headOccluder = try SCNScene(url: headOccluderURL!, options: nil)
        } catch {
            fatalError("vettonsVTO => Failed to load headOccluder scene")
        }
        
        do {
            scene = try SCNScene(url: sceneURL!, options: nil)
        } catch {
            fatalError("vettonsVTO => Failed to load face scene")
        }
        
        let modelScale = simd_float3(1,1,1) * 0.01 // Multiply by 0.01 to convert cm models to meter unit
        
        // MARK: - Head Occluder
        
        let headOccluderRootNode = headOccluder.rootNode
        guard let headOccluderNode = headOccluderRootNode.childNode(withName: "MDL_OBJ", recursively: false) else { return }
        headOccluderNode.geometry?.firstMaterial = occlusionMaterial() // set the material as occluder
        headOccluderNode.renderingOrder = -50
        headOccluderRootNode.simdScale = simd_float3(1.1,1.1,1.1) * kCentimetersToMeters
        headOccluderRootNode.name = "headOccluder"
        faceNode.addChildNode(headOccluderRootNode)
        
        // MARK: - AR Model Node loading and transformation
        
        arModelNode.load()
        arModelNode.simdScale = modelScale
        arModelNode.simdPosition = VTARModelType.glass.assetPosition()
        
        
        // Rotate the mesh if done without using the asset ref
        //arModelNode.simdLocalRotate(by: simd_quatf(angle: .pi, axis: simd_float3(0, 1, 0)))
        
        // SceneKit uses meters for units, while the canonical face mesh asset uses centimeters.
        // modelRoot.simdScale = modelScale
        
        // MARK: - Sample Torus Mesh
        let torusNode = SCNNode(geometry: SCNTorus(ringRadius: CGFloat(20 * kCentimetersToMeters), pipeRadius: CGFloat(1 * kCentimetersToMeters)))
        torusNode.geometry?.firstMaterial?.lightingModel = .physicallyBased
        torusNode.geometry?.firstMaterial?.diffuse.contents = UIColor.systemOrange
        torusNode.geometry?.firstMaterial?.roughness.contents = 0.2
        torusNode.geometry?.firstMaterial?.metalness.contents = 0.8
        torusNode.simdPosition = simd_float3(0,3,-10) * kCentimetersToMeters
        // Torus animation
        let animRotate = SCNAction.rotateBy(x: 1, y: 0, z: 0, duration: 1)
        animRotate.timingMode = .linear
        let animRotateLoop = SCNAction.repeatForever(animRotate)
        torusNode.runAction(animRotateLoop)
        // Add Torus
        torusNode.name = "torusNode"
        // faceNode.addChildNode(torusNode)
        
        // MARK: - AR Model Container Node
        // Create a container SCNNode to contain the arModelNode
        containerNode = SCNNode()
        containerNode?.name = "containerNode"
        // scene.rootNode.addChildNode(containerNode!)
        
        // Add the arModelNode into containerNode
        containerNode!.addChildNode(arModelNode)
        
        // MARK: - Face Node & Face Occluders
        faceTextureNode.name = "faceTexture"
        faceOccluderNode.name = "faceOccluder"
        
        faceOccluderNode.simdPosition = simd_float3(0,0,-0.1) * 0.01
        
        faceNode.name = "faceNode"
        // faceNode.addChildNode(faceTextureNode)
        faceNode.addChildNode(faceOccluderNode)
        scene.rootNode.addChildNode(faceNode)
        
        // MARK: - Switch VTO Type
        
        switch vtoType {
        case .sample:
            faceNode.addChildNode(torusNode)
        case .glass:
            scene.rootNode.addChildNode(containerNode!)
            faceTextureNode.removeFromParentNode()
        case .makeup:
            faceNode.addChildNode(faceTextureNode)
            containerNode?.removeFromParentNode()
        case .glassWithMakeup:
            scene.rootNode.addChildNode(containerNode!)
            faceNode.addChildNode(faceTextureNode)
        case .sampleWithMakeup:
            faceNode.addChildNode(torusNode)
            faceNode.addChildNode(faceTextureNode)
        default:
            print("nothing")
        }
        
        // MARK: - Camera Settings
        let cameraNode = SCNNode()
        cameraNode.camera = sceneCamera
        cameraNode.name = "cameraNode"
        scene.rootNode.addChildNode(cameraNode)
        let environmentTex = UIImage(named: "Face.scnassets/photo_studio_01_1k.hdr", in: faceBundle, compatibleWith: nil)
        scene.lightingEnvironment.contents = environmentTex // hdr image to use as IBL
        scene.lightingEnvironment.intensity = 1.0
        
        // let ltranslation = SCNMatrix4MakeTranslation(0, -1, 0)
        // let lrotation = SCNMatrix4MakeRotation(Float.pi / 2, 0, 0, 1)
        // let ltransform = SCNMatrix4Mult(ltranslation, lrotation)

        // scene.lightingEnvironment.contentsTransform = ltransform
        // scene.background.contents = environmentTex // set the hdr as bg
        
        // MARK: - Scene Settings
        sceneView.scene = scene
        sceneView.frame = view.bounds
        sceneView.delegate = self
        sceneView.rendersContinuously = true
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.backgroundColor = .clear
        // sceneView.autoenablesDefaultLighting = true // Not needed for IBL
        view.addSubview(sceneView)
        
        arModelNode.geometry?.firstMaterial?.lightingModel = .physicallyBased
        
        // faceTextureNode.geometry?.firstMaterial?.lightingModel = .physicallyBased
        // faceTextureNode.geometry?.firstMaterial?.metalness.contents = 1.0
        // faceTextureNode.geometry?.firstMaterial?.roughness.contents = 0.0
        
        // MARK: - Face Texture Materials
        // Face texture materials. Can be used for makeups etc.
        faceTextureMaterial.diffuse.contents = faceImage
        // faceTextureMaterial.diffuse.contents = UIColor.white
        // faceTextureMaterial.lightingModel = .physicallyBased
        // faceTextureMaterial.lightingModel = .blinn
        // faceTextureMaterial.metalness.contents = 1.0
        // faceTextureMaterial.roughness.contents = 0.2
        
        // faceTextureMaterial.lightingModel = .blinn
        // faceTextureMaterial.specular.contents = faceImage
        // faceTextureMaterial.shininess = 1.0
        
        // SCNMaterial does not premultiply alpha even with blendMode set to alpha, so do it manually.
        faceTextureMaterial.shaderModifiers =
            [SCNShaderModifierEntryPoint.fragment : "_output.color.rgb *= _output.color.a;"]
        // faceTextureMaterial.shaderModifiers = [SCNShaderModifierEntryPoint.fragment : "_output.color = gl_LastFragData[0] * _output.color"]
        // faceTextureMaterial.blendMode = .multiply
        // faceTextureMaterial.blendMode = .replace
        faceOccluderMaterial = occlusionMaterial()
        faceOccluderNode.renderingOrder = -50
    }
    
    
    /// Setup a camera capture session from the front camera to receive captures.
    private func setupCamera() {
        guard let device =
            AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: device)
            else {
                NSLog("Failed to create capture device from front camera.")
                return
        }
        
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))
        
        let session = AVCaptureSession()
        session.sessionPreset = .high
        session.addInput(input)
        session.addOutput(output)
        captureSession = session
        captureDevice = device

        cameraImageLayer.contentsGravity = .center
        cameraImageLayer.frame = sceneView.bounds
        view.layer.insertSublayer(cameraImageLayer, at: 0)
        
        startCameraCapture()
    }
    
    /// Start receiving motion updates to determine device orientation for use in the face session.
    private func setupMotion() {
        guard motionManager.isDeviceMotionAvailable else {
            NSLog("vettonsVTO => Device does not have motion sensors.")
            return
        }
        motionManager.deviceMotionUpdateInterval = kMotionUpdateInterval
        motionManager.startDeviceMotionUpdates()
    }
    
    /// Start capturing images from the capture session once permission is granted.
    private func startCameraCapture() {
        getVideoPermission(permissionHandler: { granted in
            guard granted else {
                NSLog("vettonsVTO => Permission not granted to use camera.")
                return
            }
            self.captureSession?.startRunning()
        })
    }
    
    /// Get permission to use device camera.
    ///
    /// - Parameters:
    ///   - permissionHandler: The closure to call with whether permission was granted when
    ///     permission is determined.
    private func getVideoPermission(permissionHandler: @escaping (Bool) -> ()) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionHandler(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: permissionHandler)
        default:
            permissionHandler(false)
        }
    }
    
    /// Update a region node's transform with the transform from the face session. Ignore the scale
    /// on the passed in transform to preserve the root level unit conversion.
    ///
    /// - Parameters:
    ///   - transform: The world transform to apply to the node.
    ///   - regionNode: The region node on which to apply the transform.
    ///   - offset: Offset to tweak the position
    private func updateTransform(_ transform: simd_float4x4, for regionNode: SCNNode?,_ offset: SCNVector3? = SCNVector3Zero) {
        guard let node = regionNode else { return }
        
        let localScale = node.simdScale
        node.simdWorldTransform = transform
        node.simdScale = localScale
        node.position = node.position + offset!
        
        // The .scn asset (and the canonical face mesh asset that it is created from) have their
        // 'forward' (Z+) opposite of SceneKit's forward (Z-), so rotate to orient correctly.
        node.simdLocalRotate(by: simd_quatf(angle: .pi, axis: simd_float3(0, 1, 0)))
    }
    
    
    /// Capture image
    private func captureImage() {
        
        /// Blend both feed from camera and sceneView together.
        /// Return as UIImage
        func blendImage() -> UIImage {
            
            var img = convertToUIImage(buffer: currentFaceFrame!.capturedImage)
            img = rotateImage(image: img!)
            
            let topImage = sceneView.snapshot() // SceneView scene
            let bottomImage = img // Image from the current buffer
            
            let size = CGSize(width: (bottomImage?.size.width)!, height: (bottomImage?.size.height)!)
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            bottomImage!.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            topImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            var finalImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // Mirror it back
            finalImage = UIImage(cgImage: (finalImage?.cgImage!)!, scale: 1.0, orientation: .upMirrored)
            return finalImage!
        }
        
        
        // Create a new ViewController to put the captured image. Also to be used for sharing
        let captureVC = UIViewController()
        let capturedImageView = UIImageView(frame: view.frame)
        var img = blendImage()
        // let markImg = UIImage(named: "Vettons", in: assetBundle, compatibleWith: nil)
        // let imgVTMark = util.addWatermark(img, markImage: markImg!, view: view)
        // img = imgVTMark
        
        capturedImageView.clipsToBounds = false
        capturedImageView.contentMode = .scaleAspectFill
        capturedImageView.image = img
        shareImage = img
        
        let buttonShare = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        let buttonShareImage = UIImage(named: "AR_Share_Arrow", in: assetBundle, compatibleWith: nil)
        
        buttonShare.center.x = self.view.center.x
        buttonShare.center.y = self.view.frame.height - 100
        buttonShare.setImage(buttonShareImage, for: .normal)
        buttonShare.addTarget(self, action:#selector(shareButtonAction(sender:)), for: .touchUpInside)
        buttonShare.layer.cornerRadius = 10
        
        let buttonBack = UIButton(frame: CGRect(x: 30, y: 60, width: 54, height: 30))
        let buttonBackImage = UIImage(named: "AR_View_Back", in: assetBundle, compatibleWith: nil)
        
        buttonBack.setImage(buttonBackImage, for: .normal)
        buttonBack.addTarget(self, action:#selector(backButtonAction(sender:)), for: .touchUpInside)
        buttonBack.layer.cornerRadius = 10
        
        let gradientTop = UIImageView(frame: CGRect(x: 0, y: 0, width: 375, height: 150))
        gradientTop.center.x = self.view.center.x
        gradientTop.image = UIImage(named: "TopGradient", in: assetBundle, compatibleWith: nil)
        
        captureVC.view.addSubview(capturedImageView)
        captureVC.view.addSubview(gradientTop)
        captureVC.view.addSubview(buttonShare)
        captureVC.view.addSubview(buttonBack)
        
        captureVC.modalPresentationStyle = .fullScreen
        self.present(captureVC, animated: true, completion: nil)
    }
    
    @objc func backButtonAction(sender : UIButton) {
        print("vettonsVTO => Back button pressed")
        sceneView.overlaySKScene = nil
        sceneView.removeFromSuperview()
        presentedViewController?.dismiss(animated: true, completion: nil)
        
        
    }
    
    @objc func shareButtonAction(sender : UIButton) {
        print("vettonsVTO => Share button pressed")
        
        RNEventEmitter.sharedInstance.dispatch(name: "onPress", body: ["type": "share", "data": ["clicked":true]])
        
        let img = shareImage
        let activityVC = UIActivityViewController(activityItems: [img as Any], applicationActivities: nil)
        presentedViewController!.present(activityVC, animated: true, completion: nil)
    }
    
}

// MARK: - Camera delegate
@available(iOS 12.0, *)
extension FacesViewController : AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let imgBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let deviceMotion = motionManager.deviceMotion
            else { return }
        
        let frameTime = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        
        // Use the device's gravity vector to determine which direction is up for a face. This is the
        // positive counter-clockwise rotation of the device relative to landscape left orientation.
        let rotation =  2 * .pi - atan2(deviceMotion.gravity.x, deviceMotion.gravity.y) + .pi / 2
        let rotationDegrees = (UInt)(rotation * 180 / .pi) % 360
        
        faceSession?.update(
            with: imgBuffer,
            timestamp: frameTime,
            recognitionRotation: rotationDegrees)
    }
    
}

// MARK: - Face Session delegate
@available(iOS 12.0, *)
extension FacesViewController : GARAugmentedFaceSessionDelegate {
    
    public func didUpdate(_ frame: GARAugmentedFaceFrame) {
        // To present the AR content mirrored (as is normal with a front facing camera), pass 'true' to
        // the 'mirrored' param, which flips the projection matrix along the long axis of the
        // 'presentationOrientation'. This requires the winding order to be changed from
        // counter-clockwise to clockwise in order to render correctly. However, due to an issue in
        // SceneKit on iOS >= 12 which causes the renderer to not respect the winding order set, we set
        // 'mirrored' to 'false' and instead flip the sceneView along the same axis.
        // https://openradar.appspot.com/6699866
        sceneCamera.projectionTransform = SCNMatrix4.init(
            frame.projectionMatrix(
                forViewportSize: sceneView.bounds.size,
                presentationOrientation: .portrait,
                mirrored: false,
                zNear: kCameraZNear,
                zFar: kCameraZFar)
        )
        // Flip the sceneView
        sceneView.layer.transform = CATransform3DMakeScale(-1, 1, 1)
        
        nextFaceFrame = frame
    }
    
}

// MARK: - Scene Renderer delegate
@available(iOS 12.0, *)
extension FacesViewController : SCNSceneRendererDelegate {
    
    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard nextFaceFrame != nil && nextFaceFrame != currentFaceFrame else { return }
        
        currentFaceFrame = nextFaceFrame
        
        if let face = currentFaceFrame?.face {
            
            faceTextureNode.geometry = faceMeshConverter.geometryFromFace(face)
            faceTextureNode.geometry?.firstMaterial = faceTextureMaterial
            faceTextureMaterial.diffuse.contents = ARAsset.faceImage
            faceOccluderNode.geometry = faceTextureNode.geometry?.copy() as? SCNGeometry
            faceOccluderNode.geometry?.firstMaterial = faceOccluderMaterial
            
            // Offset value from UI Sliders
            let offsetValue:SCNVector3 = SCNVector3(-pos_sliderY,-pos_sliderX,pos_sliderZ)
            
            faceNode.simdWorldTransform = face.centerTransform
            
            // Sample to update transform for other GARAugmentedFaceRegionType region
            // updateTransform(face.transform(for: .nose), for: noseTipNode)
            // updateTransform(face.transform(for: .foreheadLeft), for: foreheadLeftNode)
            // updateTransform(face.transform(for: .foreheadRight), for: foreheadRightNode)
            
            // Update transform to GARAugmentedFaceRegionType (.nose) with offsetValue controlled by UI Sliders
            updateTransform(face.transform(for: .nose), for: containerNode, offsetValue)
        }
        
        // Only show AR content when a face is detected
        sceneView.scene?.rootNode.isHidden = currentFaceFrame?.face == nil
    }
    
    public func renderer(
        _ renderer: SCNSceneRenderer,
        didRenderScene scene: SCNScene,
        atTime time: TimeInterval
    ) {
        guard let frame = currentFaceFrame else { return }
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        cameraImageLayer.contents = frame.capturedImage as CVPixelBuffer
        cameraImageLayer.setAffineTransform(
            frame.displayTransform(
                forViewportSize: cameraImageLayer.bounds.size,
                presentationOrientation: .portrait,
                mirrored: true)
        )
        CATransaction.commit()
    }
    
}

// MARK: - Extensions and Functions


/// Convert CVPixelBuffer to UIImage
/// - Parameter buffer: CVPixelBuffer
func convertToUIImage(buffer: CVPixelBuffer) -> UIImage?{
    let ciImage = CIImage(cvPixelBuffer: buffer)
    let temporaryContext = CIContext(options: nil)
    if let temporaryImage = temporaryContext.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(buffer), height: CVPixelBufferGetHeight(buffer)))
    {
        let capturedImage = UIImage(cgImage: temporaryImage)
        return capturedImage
    }
    return nil
}

/// Rotate UIImage based on orientation
/// - Parameter image: UIImage
func rotateImage(image:UIImage) -> UIImage
{
    var rotatedImage = UIImage()
    switch image.imageOrientation
    {
    case .right:
        rotatedImage = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: .down)
        
    case .down:
        rotatedImage = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: .left)
        
    case .left:
        rotatedImage = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: .up)
        
    default:
        rotatedImage = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: .right)
    }
    
    return rotatedImage
}

extension SCNVector3 {
    func convertXY() -> SCNVector3 {
        return SCNVector3(y * -1,x * -1,z)
    }
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

@available(iOS 12.0, *)
func occlusionMaterial() -> SCNMaterial {
    let occlusionMaterial = SCNMaterial()
    occlusionMaterial.isDoubleSided = true
    occlusionMaterial.colorBufferWriteMask = []
    occlusionMaterial.readsFromDepthBuffer = true
    occlusionMaterial.writesToDepthBuffer = true
    
    return occlusionMaterial
}

// MARK: - VTO Slider
@available(iOS 12.0, *)
extension FacesViewController: CircularCarouselDelegate, CircularCarouselDataSource {
    // MARK: - Create the slider items
    public func carousel(_: CircularCarousel, viewForItemAt indexPath: IndexPath, reuseView: UIView?) -> UIView {
        
        
        var bg = view as? UIButton

        if bg == nil {
            let content = UIButton(frame: CGRect(x: 2.5, y: 2.5, width: 65, height: 65))
            bg = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
            
            content.setBackgroundImage(ARAsset.sliderImageArray[indexPath.item], for: .normal)
            content.layer.cornerRadius = 32.5
            
            bg?.addSubview(content)
            bg?.backgroundColor = .white
            bg?.layer.shadowRadius = 15
            bg?.layer.shadowOffset = CGSize(width: 0, height: 15)
            bg?.layer.shadowOpacity =  0.2
            
            bg?.layer.cornerRadius = 35
            
        }

        return bg!
    }
    
    public func numberOfItems(inCarousel carousel: CircularCarousel) -> Int {
        return VTOSliderItem.count
    }
    
    public func startingItemIndex(inCarousel carousel: CircularCarousel) -> Int {
        print("==============startingItemIndex=================")
        print("vettonsVTO => VTOSliderItem.index \(VTOSliderItem.index)")
        return VTOSliderItem.index /* Insert starting item index */
    }
    
    struct carouselOption {
        static let itemWidth:CGFloat = 50
        static let scaleMultiplier:CGFloat = 1.0
        static let minScale:CGFloat = 1.0
        static let maxScale:CGFloat = 1.1
        static let minFade:CGFloat = -1
        static let maxFade:CGFloat = 1
        static let fadeRange:CGFloat = 50.0
    }
    
    public func carousel<CGFloat>(_ carousel: CircularCarousel, valueForOption option: CircularCarouselOption, withDefaultValue defaultValue: CGFloat) -> CGFloat {
        switch option {
        case .itemWidth:
            return carouselOption.itemWidth as! CGFloat
        case .maxScale:
            return carouselOption.maxScale as! CGFloat
        case .minScale:
            return carouselOption.minScale as! CGFloat
        case .fadeMin:
            return carouselOption.minFade as! CGFloat
        case .fadeMax:
            return carouselOption.maxFade as! CGFloat
        case .scaleMultiplier:
            return carouselOption.scaleMultiplier as! CGFloat
        case .fadeRange:
            return carouselOption.fadeRange as! CGFloat
        
        /*  Insert one of the following handlers :
        case spacing
        case fadeMin
        case fadeMax
        case fadeRange
        case fadeMinAlpha
        case offsetMultiplier
        case itemWidth
        case scaleMultiplier
        case minScale
        case maxScale
        */
        default:
            return defaultValue
        }
    }
    
    public func carousel(_ carousel: CircularCarousel, didSelectItemAtIndex index: Int) {
        
        currentSliderIndex = index
        
        // Create a string for the output data to send back to RN. Didn't use because we only pass during dismiss
        // VTOSliderItem.outputData = "\(VTOSliderItem.name)|\(VTOSliderItem.url)"
        
        // Uncomment if we want to sent event to RN
        // RNEventEmitter.sharedInstance.dispatch(name: "onCarouselSelected", body: ["name": "\(VTOSliderItem.name)", "data": ["url":"\(VTOSliderItem.faceImage)", "productVariantID":"\(VTOSliderItem.productVariantID)", "test":true]])
    }
    
    public func carousel(_ carousel: CircularCarousel, willBeginScrollingToIndex index: Int) {
        
        updateData(fromJSONString: variantJSON, for: index)
        
        updateImage2(with: VTOSliderItem.faceImage, for: index)
        
        // Create a string for the output data to send back to RN. Didn't use because we only pass during dismiss
        // VTOSliderItem.outputData = "\(VTOSliderItem.name)|\(VTOSliderItem.url)"
        
        // Minor haptic to indicate you have scrolled the slider
        Vibration.light.vibrate()
        
        currentSliderIndex = index
        print("vettonsVTO => VTOSlider | \(currentSliderIndex)")
        
        // Uncomment if we want to sent event to RN
        // RNEventEmitter.sharedInstance.dispatch(name: "onCarouselSelected", body: ["name": "\(VTOSliderItem.name)", "data": ["url":"\(VTOSliderItem.faceImage)", "productVariantID":"\(VTOSliderItem.productVariantID)", "test":true]])
        
    }
    
    public func carousel(_ carousel: CircularCarousel, spacingForOffset offset: CGFloat) -> CGFloat {
        /* Based on the offset from center, adjust the spacing of the item */
        return 2
    }
}

// MARK: - Update Image v2
func updateImage2(with imageURL:String, for index:Int) {
    let url = URL(string: imageURL)
    
    let defaults = UserDefaults.standard
    var storedData = defaults.data(forKey: "VTOImageURL\(index)")
    
    do {
        if storedData != nil {
            // Image is available, use data in persistence
            ARAsset.faceImage = UIImage(data: storedData!)
            
        } else {
            // Image is not available, download and store in persistence
            
            // Download the url and save as data
            let data = try! Data(contentsOf: url!)
            
            // Save data to UserDefaults
            defaults.set(data, forKey: "VTOImageURL\(index)")
            storedData = data
            DispatchQueue.main.async {
                ARAsset.faceImage = UIImage(data: storedData!)
            }
        }
    } catch  {
        fatalError("vettonsVTO => Cannot update ARAsset.faceImage")
    }
}

/// Update ImageDataItem struct with content from JSON String for selected index value
/// - Parameters:
///   - string: JSON String data
///   - index: index of the item
func updateData(fromJSONString string:String, for index:Int) {
    
    let str: String = string
    let stringData: Data = str.data(using: .utf8)!
    let variantDataArray = try! JSONDecoder().decode([VariantData].self, from: stringData)
    
    VTOSliderItem.name = variantDataArray[index].name
    VTOSliderItem.url = variantDataArray[index].faceImage
    
    VTOSliderItem.faceImage = variantDataArray[index].faceImage
    VTOSliderItem.sliderImage = variantDataArray[index].sliderImage
    VTOSliderItem.productVariantID = variantDataArray[index].productVariantID
    
    if (DEBUGMODE) {
        print("vettonsVTO => VTO Slider | variantDataArray => \(variantDataArray)")
        print("vettonsVTO => VTO Slider | VTOSliderItem.name updated to \(variantDataArray[index].name)")
        print("vettonsVTO => VTO Slider | VTOSliderItem.url updated to \(variantDataArray[index].faceImage)")
        print("vettonsVTO => VTO Slider | VTOSliderItem.faceImage updated to \(variantDataArray[index].faceImage)")
        print("vettonsVTO => VTO Slider | VTOSliderItem.faceImage updated to \(variantDataArray[index].faceImage)")
        print("vettonsVTO => VTO Slider | VTOSliderItem.productVariantID updated to \(variantDataArray[index].productVariantID)")
        
    }
    
}

func updateCount(fromJSONString string:String) {
    
    let str: String = string
    let stringData: Data = str.data(using: .utf8)!
    let variantDataArray = try! JSONDecoder().decode([VariantData].self, from: stringData)
    
    
    
    VTOSliderItem.count = variantDataArray.count
    
    if (DEBUGMODE) {
        print("vettonsVTO => VTO Slider | variantDataArray => \(variantDataArray)")
        print("vettonsVTO => VTO Slider | VTOSliderItem.count updated to \(variantDataArray.count)")
    }
    
}

func updateSliderImages(fromJSONString string:String) {
    
    let str: String = string
    let stringData: Data = str.data(using: .utf8)!
    let variantDataArray = try! JSONDecoder().decode([VariantData].self, from: stringData)
    
    for n in 0..<variantDataArray.count {
            let v = variantDataArray[n]
            let imageURL = v.sliderImage
            let url = URL(string: imageURL)
            print("imageURL in sliderImage => \(imageURL)")
            
            let WebPCoder = SDImageWebPCoder.shared
            SDImageCodersManager.shared.addCoder(WebPCoder)
            
            let defaults = UserDefaults.standard
            var storedData = defaults.data(forKey: "VTOVariantSliderThumb\(n)")
            
            do {
                if storedData != nil {
                    print("image is available. using the current stored data")
                    let img = UIImage(data: storedData!)
                    ARAsset.sliderImageArray.append(img!)
                    
                } else {
                    print("image is not yet stored. downloading and storing ..")
                    
                    // Download the url and save as data
                    let data = try! Data(contentsOf: url!)
                    let image = SDImageWebPCoder.shared.decodedImage(with: data, options: nil)
                    
                    let imagePngData = image!.pngData()
                    
                    // Save data to UserDefaults
                    defaults.set(imagePngData, forKey: "VTOVariantSliderThumb\(n)")
                    storedData = imagePngData
                    DispatchQueue.main.async {
                        let img = UIImage(data: storedData!)
                        ARAsset.sliderImageArray.append(img!)
                    }
                }
            } catch  {
                fatalError("vettonsVTO => Cannot add image into ARAsset.sliderImageArray")
            }
        
    }
    
    print("sliderImageArr =>\(ARAsset.sliderImageArray)")
    
}

