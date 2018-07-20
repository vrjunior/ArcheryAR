//
//  Target.swift
//  ArcheryAR
//
//  Created by Valmir Junior on 20/07/18.
//  Copyright © 2018 Valmir Junior. All rights reserved.
//

import Foundation
import SceneKit

class Target {
    
    public var node: SCNNode!
    
    init() {
        guard let targetScene = SCNScene(named: "art.scnassets/target.scn"),
            let targetNode = targetScene.rootNode.childNode(withName: "target", recursively: false) else {
                fatalError("Cannot find target node")
        }
        
        self.node = targetNode
        
        //physics
       // self.node.physicsBody?.categoryBitMask = CategoryMaskType.target.rawValue
    }
    
}
