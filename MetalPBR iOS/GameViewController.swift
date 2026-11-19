//
//  GameViewController.swift
//  MetalPBR iOS
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import UIKit
import MetalKit
import OSLog

// Our iOS specific view controller
final class GameViewController: UIViewController {
    
    var renderer: Renderer?
    var userInt: TouchInputDelegate?
    
    var mosquitoScene = MosquitoScene()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let mtkView = view as? MTKView else {
            Logger.renderer.error("The view of GameViewController is not an MTKView")
            return
        }
        
        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            Logger.renderer.error("Metal is not supported on this device")
            return
        }
        
        ResourceManager.device = defaultDevice
        
        mtkView.device = defaultDevice
        mtkView.backgroundColor = .black
        mtkView.isMultipleTouchEnabled = true
        
        guard let renderer = Renderer(metalKitView: mtkView, scene: mosquitoScene) else {
            Logger.renderer.error("Renderer cannot be initialised")
            return
        }
        
        self.renderer = renderer
        renderer.initialiseScene()
        
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        
        mtkView.delegate = renderer
        
        userInt = renderer.cameraController as? TouchInputDelegate
        
        let panGestureRecogniser = UIPanGestureRecognizer(target: self, action: #selector(panned))
        view.addGestureRecognizer(panGestureRecogniser)
        
    }
    
    @objc func panned(recogniser: UIPanGestureRecognizer) {
        userInt?.panned(gestureRecogniser: recogniser, in: view)
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
    
    
    // On devices without a Home button, this hides the home indicator (that line at the bottom)
    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }
    
    // Replaces the legacy UIStatusBarHidden Info.plist key
    override var prefersStatusBarHidden: Bool {
        true
    }
    
}
