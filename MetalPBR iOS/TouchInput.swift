//
//  TouchInput.swift
//  MetalPBR iOS
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Foundation
import UIKit

protocol TouchInputDelegate {
    
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView)
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView)
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView)
    func panned(gestureRecogniser: UIPanGestureRecognizer, in view: UIView)
    
}

extension TouchInputDelegate {
    
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) {}
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) {}
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) {}
    func panned(gestureRecogniser: UIPanGestureRecognizer, in view: UIView) {}
}
