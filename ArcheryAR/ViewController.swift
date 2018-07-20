//
//  ViewController.swift
//  ArcheryAR
//
//  Created by Valmir Junior on 13/07/18.
//  Copyright © 2018 Valmir Junior. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var buttonAddTarget: UIButton!
    @IBOutlet weak var buttonGetBow: UIButton!
    @IBOutlet weak var noticeView: UIView!
    @IBOutlet weak var noticeMessage: UILabel!
    
    // MARK: - ARKit / ARSCNView
    let session = ARSession()
    var sessionConfig = ARWorldTrackingConfiguration()
    
    private var panGesture: UIPanGestureRecognizer!
    private var tapGesture: UITapGestureRecognizer!
    
    private var isPlainDetected: Bool = false
    private var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.setupScene()
        self.setupARDetection()
        self.setupDebugger()
        self.setupGestures()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.session.run(sessionConfig)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.showNotice(message: "Move around your phone to detect the floor", seconds: 4)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func setupGestures() {
        self.tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(ViewController.addTargetToPlane(withGestureRecognizer:))
        )
        
        self.panGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(ViewController.throwArrow(withGestureRecognizer:))
        )
    }
    
    fileprivate func setupScene() {
        // set up sceneView
        sceneView.delegate = self
        sceneView.session = session
        sceneView.antialiasingMode = .multisampling4X
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        sceneView.preferredFramesPerSecond = 60
        sceneView.contentScaleFactor = 1.3
        //sceneView.showsStatistics = true
        
    
        if let camera = sceneView.pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
            camera.exposureOffset = -1
            camera.minimumExposure = -1
        }
        
        
    }
    
    fileprivate func setupARDetection() {
        if ARConfiguration.isSupported {
            //starts plane detection
            self.sessionConfig.planeDetection = [.horizontal] // .vertical
            
            self.sessionConfig.worldAlignment = .gravity
            
            self.session.delegate = self
            self.session.run(sessionConfig)
            
        } else {
            self.performSegue(withIdentifier: "arkitNotSupported", sender: nil)
        }
    }
    
    fileprivate func setupDebugger() {
        self.sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
    }
    
    
    @objc func throwArrow(withGestureRecognizer recognizer: UIPanGestureRecognizer) {
        
        guard recognizer.state == .ended else {
            return
        }
        
        let velocity = recognizer.velocity(in: self.sceneView)
        print("x: \(velocity.x); y: \(velocity.y)")
        
        if velocity.y >= 0 {
            return
        }
        
        guard let arrowScene = SCNScene(named: "art.scnassets/arrow.scn"),
            let arrowNode = arrowScene.rootNode.childNode(withName: "arrow", recursively: false) else {
            return
        }

        guard let camera = self.session.currentFrame?.camera else {
            return
        }

        
        
        let position = camera.transform.columns.3
        let cameraAngle = SCNVector3(camera.eulerAngles)
        
        arrowNode.position = SCNVector3(position.x, position.y, position.z - 0.5)
        
        // set angles to node with it's corrections in angles (because the model axis)
        arrowNode.eulerAngles.y = cameraAngle.y
        arrowNode.eulerAngles.x = cameraAngle.x - .pi
        arrowNode.eulerAngles.z = cameraAngle.z + .pi / 2
        
        self.sceneView.scene.rootNode.addChildNode(arrowNode)
        
        let fowardForce = (Float(velocity.y) / 100)
        
        // calculate the force
        let force = simd_make_float4(0, 0, fowardForce, 0)
        let rotatedForce = simd_mul(camera.transform, force)
        let vectorForce = SCNVector3(rotatedForce.x, rotatedForce.y, rotatedForce.z)
        
        arrowNode.physicsBody?.applyForce(vectorForce, asImpulse: true)
    }
    
    @objc func addTargetToPlane(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .estimatedHorizontalPlane)
        
        guard let hitTestResult = hitTestResults.first else { return }
        let translation = hitTestResult.worldTransform.columns.3
        let x = translation.x
        let y = translation.y
        let z = translation.z
        
        
        guard let targetScene = SCNScene(named: "art.scnassets/target.scn"),
            let targetNode = targetScene.rootNode.childNode(withName: "target", recursively: false)
            else { return }
        
        // Fix the angle based on camera angle
        // Guarantee that the target always be position on the front of you
        if let cameraAngle = self.session.currentFrame?.camera.eulerAngles {
            targetNode.eulerAngles.y = SCNVector3(cameraAngle).y - .pi / 2
        }

        targetNode.position = SCNVector3(x, y, z)
        sceneView.scene.rootNode.addChildNode(targetNode)
    }
    
    @IBAction func performChangeControls(_ sender: UIButton) {
        if sender == self.buttonAddTarget {
            self.buttonAddTarget.isEnabled = false
            self.buttonGetBow.isEnabled = true
            self.sceneView.removeGestureRecognizer(self.panGesture)
            self.sceneView.addGestureRecognizer(self.tapGesture)
            
        } else if sender == self.buttonGetBow {
            self.buttonGetBow.isEnabled = false
            self.buttonAddTarget.isEnabled = true
            self.sceneView.removeGestureRecognizer(self.tapGesture)
            self.sceneView.addGestureRecognizer(self.panGesture)
            self.showNotice(message: "You get the bow, try swipe up to shoot an arrow!", seconds: 3)
        }
    }
    
    func showNotice(message: String, seconds: TimeInterval) {
        
        self.noticeMessage.text = message
        
        self.timer.invalidate()
        
        self.noticeView.isHidden = false
        
        self.timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { (timer) in
            self.noticeView.isHidden = true
        })
    }
    
}

extension ViewController: ARSCNViewDelegate {
    
    // MARK: - ARSCNViewDelegate
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        // 1
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        // 3
        plane.materials.first?.diffuse.contents = UIColor.grayTransparent
        
        // 4
        let planeNode = SCNNode(geometry: plane)
        
        // 5
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
        planeNode.eulerAngles.x = -.pi / 2
        
        // 6
        node.addChildNode(planeNode)
        
        if !self.isPlainDetected {
            self.isPlainDetected = true
            
            DispatchQueue.main.sync {
                self.showNotice(message: "Plain Detected! Try to add a add a target around you", seconds: 4)
                self.performChangeControls(self.buttonAddTarget)
            }
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // guarantee that gets a plane
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        
        // 3
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
}

extension ViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        
    }
    
}

//extension ViewController: SCNPhysicsContactDelegate {
//    
//    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
//        
//        if contact.nodeA ==   {
//            
//            
//            
//        }
//        
//        if let arrow = contact.nodeB {
//            
//            
//        }
//        
//        
//    }
//    
//}
