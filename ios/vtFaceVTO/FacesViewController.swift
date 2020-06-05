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

// Filter Test
import CoreImage

@available(iOS 12.0, *)
var facesVC = FacesViewController()

var pos_sliderX: Float = 0
var pos_sliderY: Float = 0
var pos_sliderZ: Float = 0
var isCapturing: Bool = false

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
    private var faceTextureMaterial = SCNMaterial()
    private var faceOccluderMaterial = SCNMaterial()
    
    private lazy var headOccluderNode = SCNNode()
    private var containerNode: SCNNode?
    private var arModelNode: SCNReferenceNode?
    private var faceImage: UIImage?
    
    private var headOccluder = SCNScene()
    private var scene = SCNScene()
    
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
    
    // MARK: - VTO General Properties
    
    // MARK: - Resources Bundle properties
    private var assetBundle: Bundle?
    private var faceBundle: Bundle?
    
    
    
    // MARK: - Some stuff
    
    var positionOffset: simd_float3?
    var shareImage: UIImage?
    
    // MARK: - UI Stuff
    
    var skScene: SKScene = aSKScene()
    
    // MARK: - Implementation methods
    
    
    override public func viewWillAppear(_ animated: Bool) {
        print("vettonsVTO => viewWillAppear")
        
        if !VTOSetup.state {
            print("vettonsVTO => reloading the scene")
            setupScene()
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        print("vettonsVTO => viewDidLoad")
        
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
        
        let overlayScene = SKScene()
        /// Using an SKScene to overlay the SceneKit so that UIKit could be used.
        sceneView.overlaySKScene = overlayScene
        
        // Setup capture button
        let buttonCapture = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        buttonCapture.center.x = self.view.center.x
        buttonCapture.center.y = self.view.frame.height - 50
        let buttonCaptureImage = UIImage(named: "AR_View_Camera", in: assetBundle, compatibleWith: nil)
        
        buttonCapture.setImage(buttonCaptureImage, for: .normal)
        // buttonCapture.backgroundColor = UIColor.systemTeal
        // buttonCapture.setTitle("SNAP", for: .normal)
        // buttonCapture.setTitleColor(UIColor.white, for: .normal)
        buttonCapture.addTarget(self, action: #selector(captureButtonAction(sender:)), for: .touchUpInside)
        buttonCapture.transform = CGAffineTransform(scaleX: -1, y: 1)
        buttonCapture.layer.cornerRadius = 10
        
        // Setup back button
        let buttonBack = UIButton(frame: CGRect(x: self.view.frame.width - 84, y: 30, width: 54, height: 30))
        let buttonBackImage = UIImage(named: "AR_View_Back", in: assetBundle, compatibleWith: nil)
        
        buttonBack.setImage(buttonBackImage, for: .normal)
        // buttonBack.backgroundColor = UIColor.systemTeal
        // buttonBack.setTitle("<", for: .normal)
        // buttonBack.setTitleColor(UIColor.white, for: .normal)
        buttonBack.addTarget(self, action:#selector(mainBackButtonAction(sender:)), for: .touchUpInside)
        buttonBack.transform = CGAffineTransform(scaleX: -1, y: 1)
        buttonBack.layer.cornerRadius = 10
        
        // Setup gradientTop
        
        let gradientTop = UIImageView(frame: CGRect(x: 0, y: 0, width: 375, height: 150))
        gradientTop.center.x = self.view.center.x
        gradientTop.image = UIImage(named: "TopGradient", in: assetBundle, compatibleWith: nil)
        
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
        RNEventEmitter.sharedInstance.dispatch(name: "onPress", body: ["type": "dismiss", "data": ["clicked":true]])
        self.dismiss(animated: true, completion: nil)
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
        sceneView.gestureRecognizers?.removeAll()
        sceneView.scene!.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        sceneView.removeFromSuperview()
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
        
        // MARK: - Face Texture Materials
        // Face texture materials. Can be used for makeups etc.
        faceTextureMaterial.diffuse.contents = faceImage
        // SCNMaterial does not premultiply alpha even with blendMode set to alpha, so do it manually.
        faceTextureMaterial.shaderModifiers =
            [SCNShaderModifierEntryPoint.fragment : "_output.color.rgb *= _output.color.a;"]
        
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
        let markImg = UIImage(named: "Vettons", in: assetBundle, compatibleWith: nil)
        let imgVTMark = util.addWatermark(img, markImage: markImg!, view: view)
        img = imgVTMark
        
        
        // Apply image filters to image
        // let imageFX = photoFX.random()
        // img = applyCIFilter(img, with: imageFX)
        // img = applyLUT(img, named: "lutTest.png")
        // img = applyCIFilter(img, with: "CIEdges")
        // print("vettonsVTO => imageFX : \(imageFX) applied")
        
        capturedImageView.image = img
        shareImage = img
        
        let buttonShare = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        let buttonShareImage = UIImage(named: "AR_Share_Arrow", in: assetBundle, compatibleWith: nil)
        
        buttonShare.center.x = self.view.center.x
        buttonShare.center.y = self.view.frame.height - 50
        buttonShare.setImage(buttonShareImage, for: .normal)
        // buttonShare.backgroundColor = UIColor.systemTeal
        // buttonShare.setTitle("SHARE", for: .normal)
        // buttonShare.setTitleColor(UIColor.white, for: .normal)
        buttonShare.addTarget(self, action:#selector(shareButtonAction(sender:)), for: .touchUpInside)
        buttonShare.layer.cornerRadius = 10
        
        let buttonBack = UIButton(frame: CGRect(x: 30, y: 30, width: 54, height: 30))
        let buttonBackImage = UIImage(named: "AR_View_Back", in: assetBundle, compatibleWith: nil)
        
        buttonBack.setImage(buttonBackImage, for: .normal)
        // buttonBack.backgroundColor = UIColor.systemTeal
        // buttonBack.setTitle("<", for: .normal)
        // buttonBack.setTitleColor(UIColor.white, for: .normal)
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
        
        //faceTextureMaterial.blendMode = .alpha
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

// Apply CIFilter on UIImage
func applyCIFilter(_ img:UIImage,with filter:String) -> UIImage {
    
    let context = CIContext()
    
    if let currentFilter = CIFilter(name: filter) {
        let beginImage = CIImage(image: img)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        
        let inputKeys = currentFilter.inputKeys.description
        
        if currentFilter.inputKeys.count > 1 {
        print("vettonsVTO => CIFilter does have more than one input")
        print("vettonsVTO => CIFilter Inputs : \(currentFilter.inputKeys)")
            
            if inputKeys.contains("inputIntensity") {
                currentFilter.setValue(1, forKey: kCIInputIntensityKey)
                print("inputIntensity applied")
            }
            
            if inputKeys.contains("inputNoiseLevel") {
                currentFilter.setValue(5, forKey: "inputNoiseLevel")
                print("inputNoiseLevel applied")
            }
            
            if inputKeys.contains("inputSharpness") {
                currentFilter.setValue(10, forKey: kCIInputSharpnessKey)
                print("inputSharpness applied")
            }
            
            if inputKeys.contains("inputRadius") {
                currentFilter.setValue(1, forKey: "inputRadius")
                print("inputRadius applied")
            }
        }
        
        
        if let cgimg = context.createCGImage(currentFilter.outputImage!, from: currentFilter.outputImage!.extent) {
            let processedImage = UIImage(cgImage: cgimg)
            return processedImage
        }
    }
    print("vettonsVTO => CIFilter was not applied to the UIImage")
    return img
}

func applyLUT(_ img:UIImage,named lutImage:String) -> UIImage {

    let context = CIContext()
    let lutFilter = lutFX.colorCubeFilterFromLUT(imageName: lutImage)
    
    if let currentFilter = lutFilter {
        let beginImage = CIImage(image: img)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        
        if currentFilter.inputKeys.count > 1 {
        print("vettonsVTO => CIFilter does have more than one input")
        print("vettonsVTO => CIFilter Inputs : \(currentFilter.inputKeys)")
            
        }

        if let cgimg = context.createCGImage(currentFilter.outputImage!, from: currentFilter.outputImage!.extent) {
            let processedImage = UIImage(cgImage: cgimg)
            return processedImage
        }
    }
    print("vettonsVTO => LUT was not applied to the UIImage")
    return img
}

func applyCIFilterBuffer(buffer:CVPixelBuffer) -> CVPixelBuffer {
    let context = CIContext()
    
    if let currentFilter = CIFilter(name: "CISepiaTone") {
        let beginImage = CIImage(cvPixelBuffer: buffer)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        currentFilter.setValue(1.0, forKey: kCIInputIntensityKey)
        
        if let cgimg = context.createCGImage(currentFilter.outputImage!, from: currentFilter.outputImage!.extent) {
            let processedImage = UIImage(cgImage: cgimg)
            // do something interesting with the processed image
            let newBuffer = bufferUIImage(from: processedImage)!
            return newBuffer
        }
    }
    
    return buffer
}

func bufferUIImage(from image: UIImage) -> CVPixelBuffer? {
    let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
    var pixelBuffer : CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
    guard (status == kCVReturnSuccess) else {
        return nil
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
    
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
    
    context?.translateBy(x: 0, y: image.size.height)
    context?.scaleBy(x: 1.0, y: -1.0)
    
    UIGraphicsPushContext(context!)
    image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
    UIGraphicsPopContext()
    CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    
    return pixelBuffer
}

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

// MARK: - SKScene for all the UI Stuff

class aSKScene: SKScene {
    
    /*
    let kCentimetersToMeters:Float = 0.01
    
    let sliderX = UISlider(frame: CGRect(x: 50, y: 60, width: 250, height: 30))
    let sliderY = UISlider(frame: CGRect(x: 50, y: 120, width: 250, height: 30))
    let sliderZ = UISlider(frame: CGRect(x: 50, y: 180, width: 250, height: 30))
    
    let labelX = UILabel(frame: CGRect(x: 310, y: 60, width: 150, height: 30))
    let labelY = UILabel(frame: CGRect(x: 310, y: 120, width: 150, height: 30))
    let labelZ = UILabel(frame: CGRect(x: 310, y: 180, width: 150, height: 30))
    
    override func didMove(to view: SKView) {
        // loadSliderX()
        // loadSliderY()
        // loadSliderZ()
        // loadLabels()
        // loadButtons()
    }
    
    override func update(_ currentTime: TimeInterval) {
        DispatchQueue.main.async { // Run on Main Thread
            self.labelX.text = " X = \(self.sliderX.value)"
            self.labelY.text = " Y = \(self.sliderY.value)"
            self.labelZ.text = " Z = \(self.sliderZ.value)"
        }
    }
    
    @objc func valueXChanged(sender: UISlider) {
        // print("sliderX value => \(sender.value * kCentimetersToMeters)")
        pos_sliderX = sender.value * kCentimetersToMeters
    }
    @objc func valueYChanged(sender: UISlider) {
        // print("sliderY value => \(sender.value * kCentimetersToMeters)")
        pos_sliderY = sender.value * kCentimetersToMeters
    }
    @objc func valueZChanged(sender: UISlider) {
        // print("sliderZ value => \(sender.value * kCentimetersToMeters)")
        pos_sliderZ = sender.value * kCentimetersToMeters
    }
    
    func loadLabels(){
        labelX.textColor = UIColor.white
        labelX.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        labelX.text = " Slider X : \(sliderX.value)"
        labelX.transform = CGAffineTransform(scaleX: -1, y: 1)
        
        labelY.textColor = UIColor.white
        labelY.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        labelY.text = " Slider Y : \(sliderY.value)"
        labelY.transform = CGAffineTransform(scaleX: -1, y: 1)
        
        labelZ.textColor = UIColor.white
        labelZ.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        labelZ.text = " Slider Z : \(sliderZ.value)"
        labelZ.transform = CGAffineTransform(scaleX: -1, y: 1)
        
        view?.addSubview(labelX)
        view?.addSubview(labelY)
        view?.addSubview(labelZ)
    }
    
    func loadSliderX() {
        sliderX.maximumValue = 10
        sliderX.minimumValue = -10
        sliderX.tintColor = UIColor.gray
        sliderX.isUserInteractionEnabled = true
        sliderX.addTarget(self, action: #selector(valueXChanged(sender:)), for: .valueChanged)
        sliderX.transform = CGAffineTransform(scaleX: -1, y: 1)
        view?.addSubview(sliderX)
    }
    func loadSliderY() {
        sliderY.maximumValue = 10
        sliderY.minimumValue = -10
        sliderY.tintColor = UIColor.gray
        sliderY.isUserInteractionEnabled = true
        sliderY.addTarget(self, action: #selector(valueYChanged(sender:)), for: .valueChanged)
        sliderY.transform = CGAffineTransform(scaleX: -1, y: 1)
        view?.addSubview(sliderY)
    }
    func loadSliderZ() {
        sliderZ.maximumValue = 10
        sliderZ.minimumValue = -10
        sliderZ.tintColor = UIColor.gray
        sliderZ.isUserInteractionEnabled = true
        sliderZ.addTarget(self, action: #selector(valueZChanged(sender:)), for: .valueChanged)
        sliderZ.transform = CGAffineTransform(scaleX: -1, y: 1)
        view?.addSubview(sliderZ)
    }
     */
    
}
