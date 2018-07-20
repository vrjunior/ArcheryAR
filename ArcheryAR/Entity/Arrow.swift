//
//  Arrow.swift
//  ArcheryAR
//
//  Created by Valmir Junior on 20/07/18.
//  Copyright © 2018 Valmir Junior. All rights reserved.
//

import Foundation
import SceneKit

class Arrow {
    
    public var node: SCNNode!
    
    init() {
        guard let arrowScene = SCNScene(named: "art.scnassets/arrow.scn"),
            let arrowNode = arrowScene.rootNode.childNode(withName: "arrow", recursively: false) else {
                fatalError("Cannot find arrow node")
        }
        
        self.node = arrowNode
    }
    
}
