//
//  GameViewController.swift
//  MetalPBR macOS
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Cocoa
import MetalKit

// Our macOS specific view controller
class GameViewController: NSViewController {
    
    var renderer: Renderer!
    var mtkView: MTKView!
    var userInt: MacInputDelegate!
    
    var mouseIsInView = false
    
    var mosquitoScene = MosquitoScene()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        guard let mtkView = self.view as? MTKView else {
            print("View attached to GameViewController is not an MTKView")
            return
        }
        
        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }
        
        ResourceManager.device = defaultDevice
        
        mtkView.device = defaultDevice
        
        guard let newRenderer = Renderer(metalKitView: mtkView, scene: mosquitoScene) else {
            print("Renderer cannot be initialized")
            return
        }
        
        renderer = newRenderer
        renderer.initialiseScene()
        
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        
        mtkView.delegate = renderer
        
        let area = NSTrackingArea(rect: mtkView.bounds,
                                  options: NSTrackingArea.Options([.mouseEnteredAndExited,
                                                                   .activeInActiveApp]),
                                  owner: self,
                                  userInfo: nil)
        mtkView.addTrackingArea(area)
        
        self.userInt = (renderer.cameraController as! MacInputDelegate)
        
        // Set a block that fires when a key is pressed
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            (keyEvent) -> NSEvent? in
            if self.keyDown(with: keyEvent) {
                return nil
            } else {
                return keyEvent
            }
        }
        
        // Set a block that fires when a key is released
        NSEvent.addLocalMonitorForEvents(matching: .keyUp) {
            (keyEvent) -> NSEvent? in
            if self.keyUp(with: keyEvent) {
                return nil
            } else {
                return keyEvent
            }
        }
        
        // Set a block that fires when the mouse is moved
        NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) {
            (mouseEvent) -> NSEvent? in
            if self.mouseMoved(with: mouseEvent) {
                return nil
            } else {
                return mouseEvent
            }
        }
        
    }
    
    func keyDown(with event: NSEvent) -> Bool {
        
        userInt.keyDown(key: event.keyCode)
        
        return true
    }
    
    func keyUp(with event: NSEvent) -> Bool {
        
        userInt.keyUp(key: event.keyCode)
        
        return true
    }
    
    func mouseMoved(with event: NSEvent) -> Bool {
        
        if mouseIsInView {
            userInt.mouseMoved(position: event.locationInWindow)
        }
        
        return true
    }
    
    override func mouseEntered(with event: NSEvent) {
        mouseIsInView = true
    }
    
    override func mouseExited(with event: NSEvent) {
        mouseIsInView = false
    }
    
    override func mouseDown(with event: NSEvent) {
        if mouseIsInView {
            userInt.mouseClicked(position: event.locationInWindow)
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        if mouseIsInView {
            userInt.mouseDragged(position: event.locationInWindow)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if mouseIsInView {
            userInt.mouseReleased(position: event.locationInWindow)
        }
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        return true
    }
}
