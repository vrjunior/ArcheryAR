//
//  SKButton.swift
//  PepperJourney
//
//  Created by Valmir Junior on 13/12/17.
//  Copyright © 2017 Valmir Junior. All rights reserved.
//

import Foundation
import SpriteKit

protocol SKButtonDelegate {
    func buttonPressed(target: SKButton)
    func buttonReleased(target: SKButton)
}

extension SKButtonDelegate {
    func buttonReleased(target: SKButton) { }
}

class SKButton : SKSpriteNode {
    
    public var delegate : SKButtonDelegate?
    public let defaultColorBlendFactor: CGFloat = 0.2
    private var _numberOfTouches = 1
    public var numberOfTouches: Int {
        set {
            if newValue > 0 {
                self._numberOfTouches = newValue
            }
        }
        get {
            return _numberOfTouches
        }
    }
    
    var isPausedControls: Bool = false {
        didSet {
            if isPausedControls {
                self.isHidden = true
            } else {
                self.isHidden = false
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.isUserInteractionEnabled = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count <= numberOfTouches  {
            self.delegate?.buttonPressed(target: self)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count <= numberOfTouches  {
            self.delegate?.buttonReleased(target: self)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count <= numberOfTouches  {
            self.delegate?.buttonReleased(target: self)
        }
    }
    
}
