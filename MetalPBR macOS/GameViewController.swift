//
//  GameViewController.swift
//  MetalPBR macOS
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import AppKit
import MetalKit
import OSLog

// Our macOS specific view controller
final class GameViewController: NSViewController {
    
    var renderer: Renderer?
    var userInt: MacInputDelegate?
    
    var mouseIsInView = false
    
    var mosquitoScene = MosquitoScene()
    
    /// The tokens returned when installing our local event monitors, so we can remove them later
    private var eventMonitors = [Any]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let mtkView = view as? MTKView else {
            Logger.renderer.error("The view attached to GameViewController is not an MTKView")
            return
        }
        
        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            Logger.renderer.error("Metal is not supported on this device")
            return
        }
        
        ResourceManager.device = defaultDevice
        
        mtkView.device = defaultDevice
        
        guard let renderer = Renderer(metalKitView: mtkView, scene: mosquitoScene) else {
            Logger.renderer.error("Renderer cannot be initialised")
            return
        }
        
        self.renderer = renderer
        renderer.initialiseScene()
        
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        
        mtkView.delegate = renderer
        
        // `.inVisibleRect` keeps the tracking area in sync with the view's bounds as the window resizes
        let area = NSTrackingArea(rect: .zero,
                                  options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect],
                                  owner: self,
                                  userInfo: nil)
        mtkView.addTrackingArea(area)
        
        userInt = renderer.cameraController as? MacInputDelegate
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        installEventMonitors()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        removeEventMonitors()
    }
    
    private func installEventMonitors() {
        
        guard eventMonitors.isEmpty else { return }
        
        // Set a block that fires when a key is pressed
        if let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { [weak self] keyEvent in
            (self?.keyDown(with: keyEvent) ?? false) ? nil : keyEvent
        }) {
            eventMonitors.append(monitor)
        }
        
        // Set a block that fires when a key is released
        if let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyUp, handler: { [weak self] keyEvent in
            (self?.keyUp(with: keyEvent) ?? false) ? nil : keyEvent
        }) {
            eventMonitors.append(monitor)
        }
        
        // Set a block that fires when the mouse is moved
        if let monitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved, handler: { [weak self] mouseEvent in
            (self?.mouseMoved(with: mouseEvent) ?? false) ? nil : mouseEvent
        }) {
            eventMonitors.append(monitor)
        }
        
    }
    
    private func removeEventMonitors() {
        eventMonitors.forEach(NSEvent.removeMonitor)
        eventMonitors.removeAll()
    }
    
    func keyDown(with event: NSEvent) -> Bool {
        
        userInt?.keyDown(key: event.keyCode)
        
        return true
    }
    
    func keyUp(with event: NSEvent) -> Bool {
        
        userInt?.keyUp(key: event.keyCode)
        
        return true
    }
    
    func mouseMoved(with event: NSEvent) -> Bool {
        
        if mouseIsInView {
            userInt?.mouseMoved(position: event.locationInWindow)
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
            userInt?.mouseClicked(position: event.locationInWindow)
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        if mouseIsInView {
            userInt?.mouseDragged(position: event.locationInWindow)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if mouseIsInView {
            userInt?.mouseReleased(position: event.locationInWindow)
        }
    }
    
    override var acceptsFirstResponder: Bool {
        true
    }
    
    override func becomeFirstResponder() -> Bool {
        true
    }
    
    override func resignFirstResponder() -> Bool {
        true
    }
}
