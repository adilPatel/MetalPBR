//
//  GameViewController.swift
//  MetalPBR iOS
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import UIKit
import MetalKit

// Our iOS specific view controller
class GameViewController: UIViewController {
    
    var renderer: Renderer!
    var mtkView: MTKView!
    var userInt: TouchInputDelegate!
    
    var mosquitoScene = MosquitoScene()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let mtkView = view as? MTKView else {
            print("View of Gameview controller is not an MTKView")
            return
        }
        
        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported")
            return
        }
        
        ResourceManager.device = defaultDevice
        
        mtkView.device = defaultDevice
        mtkView.backgroundColor = UIColor.black
        mtkView.isMultipleTouchEnabled = true
        
        guard let newRenderer = Renderer(metalKitView: mtkView, scene: mosquitoScene) else {
            print("Renderer cannot be initialized")
            return
        }
        
        renderer = newRenderer
        renderer.initialiseScene()
        
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        
        mtkView.delegate = renderer
        
        self.userInt = (renderer.cameraController as! TouchInputDelegate)
        
        let panGestureRecogniser = UIPanGestureRecognizer(target: self, action: #selector(panned))
        view.addGestureRecognizer(panGestureRecogniser)
        
    }
    
    @objc func panned(recogniser: UIPanGestureRecognizer) {
        userInt.panned(gestureRecogniser: recogniser, in: view)
    }
    
    //    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    //        super.touchesBegan(touches, with: event)
    //        userInt.touchesBegan(touches, with: event, in: view)
    //    }
    //
    //    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    //        super.touchesMoved(touches, with: event)
    //        userInt.touchesMoved(touches, with: event, in: view)
    //    }
    //
    //    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    //        super.touchesEnded(touches, with: event)
    //        userInt.touchesEnded(touches, with: event, in: view)
    //
    //    }
    
    
    // If you're using an iPhone X, this hides the home indicator (that line at the bottom)
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
}
