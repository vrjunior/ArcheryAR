//
//  GameViewController.swift
//  ArcheryAR
//
//  Created by Valmir Junior on 13/07/18.
//  Copyright © 2018 Valmir Junior. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class GameViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var buttonAddTarget: UIButton!
    @IBOutlet weak var buttonGetBow: UIButton!
    @IBOutlet weak var noticeView: UIView!
    @IBOutlet weak var noticeMessage: UILabel!
    
    // MARK: Private variables and constants
    private let session = ARSession()
    private var sessionConfig = ARWorldTrackingConfiguration()
    
    private var panGesture: UIPanGestureRecognizer!
    private var tapGesture: UITapGestureRecognizer!
    
    private var isPlainDetected: Bool = false
    private var timer = Timer()
    
    private var targetsInScene: [Target] = [] {
        // Control the quantity of targets in Scene
        didSet {
            if self.targetsInScene.count > 10 {
                self.targetsInScene.first?.node.removeFromParentNode()
                self.targetsInScene.removeFirst()
            }
        }
    }
    private var arrowsInScene: [Arrow] = [] {
        // Control the arrows of targets in Scene
        didSet {
            if self.arrowsInScene.count > 10 {
                self.arrowsInScene.first?.node.removeFromParentNode()
                self.arrowsInScene.removeFirst()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.setupScene()
        self.setupARDetection()
        // self.setupDebugger()
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
            action: #selector(GameViewController.addTargetToPlane(withGestureRecognizer:))
        )
        
        self.panGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(GameViewController.throwArrow(withGestureRecognizer:))
        )
    }
    
    fileprivate func setupScene() {
        // set up sceneView
        sceneView.delegate = self
        sceneView.scene.physicsWorld.contactDelegate = self
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
            
            self.session.run(sessionConfig)
            
        } else {
            self.performSegue(withIdentifier: "arkitNotSupported", sender: nil)
        }
    }
    
    fileprivate func setupDebugger() {
        self.sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
    }
    
    
    @objc func throwArrow(withGestureRecognizer recognizer: UIPanGestureRecognizer) {
        
        // Check if gesture ended
        guard recognizer.state == .ended else {
            return
        }
        
        // Retrieve velocity in relation to view
        let velocity = recognizer.velocity(in: self.sceneView)
        
        // If velocity in Y axis is 0 then return
        if velocity.y >= 0 {
            return
        }
        
        // Create an instance of arrow
        let arrow = Arrow()

        // Guarantee that exists a camera in current frame of arkit session
        guard let camera = self.session.currentFrame?.camera else {
            return
        }
        
        // Get position and angle of camera
        let position = camera.transform.columns.3
        let cameraAngle = SCNVector3(camera.eulerAngles)
        
        // sets arrow posision according to camera posision
        arrow.node.position = SCNVector3(position.x, position.y, position.z - 0.5)
        
        // set angles to node with it's corrections in angles (because the model axis)
        arrow.node.eulerAngles.y = cameraAngle.y
        arrow.node.eulerAngles.x = cameraAngle.x - .pi
        arrow.node.eulerAngles.z = cameraAngle.z + .pi / 2
        
        self.sceneView.scene.rootNode.addChildNode(arrow.node)
        self.arrowsInScene.append(arrow)
        
        // fowardForce according to velocity of pan gesture
        let fowardForce = (Float(velocity.y) / 100)
        
        // calculate the force
        let force = simd_make_float4(0, 0, fowardForce, 0)
        let rotatedForce = simd_mul(camera.transform, force)
        let vectorForce = SCNVector3(rotatedForce.x, rotatedForce.y, rotatedForce.z)
        
        arrow.node.physicsBody?.applyForce(vectorForce, asImpulse: true)
    }
    
    @objc func addTargetToPlane(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .estimatedHorizontalPlane)
        
        guard let hitTestResult = hitTestResults.first else { return }
        let translation = hitTestResult.worldTransform.columns.3
        let x = translation.x
        let y = translation.y
        let z = translation.z
        
        
        let target = Target()
        
        // Fix the angle based on camera angle
        // Guarantee that the target always be position on the front of you
        if let cameraAngle = self.session.currentFrame?.camera.eulerAngles {
            target.node.eulerAngles.y = SCNVector3(cameraAngle).y - .pi / 2
        }

        target.node.position = SCNVector3(x, y, z)
        sceneView.scene.rootNode.addChildNode(target.node)
        
        self.targetsInScene.append(target)
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
        
        self.timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { _ in
            self.noticeView.isHidden = true
        })
    }
    
}

extension GameViewController: ARSCNViewDelegate {
        
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        // 1
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        // 3
        plane.materials.first?.diffuse.contents = UIColor.clear
        
        // 4
        let planeNode = SCNNode(geometry: plane)
        
        // 5
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
        planeNode.eulerAngles.x = -.pi / 2
        
        // setup physics
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        planeNode.physicsBody?.categoryBitMask = CategoryMaskType.floor.rawValue
        planeNode.physicsBody?.collisionBitMask = 3
        planeNode.physicsBody?.contactTestBitMask = 3
        
        
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
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }
    
}

extension GameViewController: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        
        // If nodeA is arrow node
        if contact.nodeA.physicsBody?.categoryBitMask == CategoryMaskType.arrow.rawValue {
            
            let arrow = contact.nodeA
            
            self.handleArrowContact(arrowNode: arrow, anotherNode: contact.nodeB)
            
            return
        }
        
        // If nodeB is arrow Node
        if contact.nodeB.physicsBody?.categoryBitMask == CategoryMaskType.arrow.rawValue {
            
            let arrow = contact.nodeB
            
            self.handleArrowContact(arrowNode: arrow, anotherNode: contact.nodeA)
            
            return
        }
        
    }
    
    // Handle arrow contact
    func handleArrowContact(arrowNode: SCNNode, anotherNode: SCNNode) {
        
        if anotherNode.categoryBitMask == CategoryMaskType.floor.rawValue {
            
            self.removeArrowFromScene(arrowNode: arrowNode)
            
            return
        }
        
        if anotherNode.name == "target" {
            
            arrowNode.physicsBody?.type = .kinematic
            
            return
        }
    }
    
    func removeArrowFromScene(arrowNode: SCNNode) {
        
        // remove from scene
        arrowNode.removeFromParentNode()
        
        // remove from array of control
        let arrowsNodeInScene = self.arrowsInScene.map { $0.node }
        
        for (index, arrowNodeToCompare) in arrowsNodeInScene.enumerated()
                                        where arrowNode == arrowNodeToCompare {
            
                self.arrowsInScene.remove(at: index)
        }
    }
    
}
