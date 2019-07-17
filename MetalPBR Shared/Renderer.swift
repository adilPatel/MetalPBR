//
//  Renderer.swift
//  MetalPBR Shared
//
//  Created by Adil Patel on 14/09/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

// Our platform independent renderer class

import Metal
import MetalKit
import simd

enum RendererError: Error {
    case badVertexDescriptor
}

let buffersInFlight = 3

#if os(iOS)
let sampleCount = 2
#else
let sampleCount = 4
#endif

class Renderer: NSObject, MTKViewDelegate, SceneResponderDelegate {
    
    /// A handle to our device (which is the GPU)
    public let device: MTLDevice
    
    /// Controls our camera
    public var cameraController: CameraController!
    
    let viewSize: CGSize
    
    /// The scene we're rendering
    var scene: Scene
    
    var library: MTLLibrary?
    
    /// The Metal render pipeline state
    var meshPipelineState: MTLRenderPipelineState!
    
    /// The Metal depth stencil state
    var depthState: MTLDepthStencilState
    
    /// The Metal command queue
    let commandQueue: MTLCommandQueue
    
    /// The array of buffers used
    var constantBuffers = Array<MTLBuffer>()
    
    /// The index of the current buffer being written to and binded
    var constantBufferIndex = 0
    
    /// The data which is constant across all objects in a single frame
    var frameConstants = PerFrameConstants()
    
    /// The texture sampler which will be passed on to Metal
    var sampler: Sampler
    
    /// All the meshes present in this scene
    var meshes = Array<Mesh>()
    
    /// All the per-object transforms expressed as data structs
    var objectTransforms = Array<ObjectTransforms>()
    
    /// This is similar to the above, but only for the skybox
    var skyboxTransforms: [SkyboxTransforms]!
    
    /// A handle to our skybox
    var skybox: Skybox!
    
    /// All the model matrices for each object
    var modelMatrices = Array<float4x4>()
    
    /// The textures for each object
    var textures = Array<Texture>()
    
    /// This is the colour render target containing multiple samples
    var colourMultisampleTarget: MTLTexture!
    
    /// This is the depth render target containing multiple samples
    var depthMultisampleTarget: MTLTexture!
    
    /// The MSAA resolved colour target
    var colourResolvedTarget: MTLTexture!
    
    /// The MSAA resolved depth target
    var depthResolvedTarget: MTLTexture!
    
    /// The render pipeline state for the final render pass
    var finalRenderPipelineState: MTLRenderPipelineState!
    
    /// The array full of game objects we'll draw
    var gameObjects = Array<GameObject>()
    
    /// The texture of the environment that'll reflect off the object
    var environmentTexture: Texture!
    
    /// The texture loader for the material textures of the objects
    let materialTextureLoader: MTKTextureLoader
    
    /// Our semaphore for triple buffering
    var semaphore = DispatchSemaphore(value: buffersInFlight)
    
    init?(metalKitView: MTKView, scene: Scene) {
        // Initialising the crucial view, device, and command queue parameters
        device = metalKitView.device!
        
        viewSize = metalKitView.drawableSize
        
        self.scene = scene
        
        guard let queue = device.makeCommandQueue() else {
            return nil
        }
        commandQueue = queue
        
        metalKitView.colorPixelFormat = .bgra8Unorm_srgb
        metalKitView.depthStencilPixelFormat = .depth32Float_stencil8
        
        // Depth testing
        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.depthCompareFunction = .less
        depthStateDesciptor.isDepthWriteEnabled = true
        depthStateDesciptor.label = "Main Depth State"
        guard let state = device.makeDepthStencilState(descriptor:depthStateDesciptor) else { return nil }
        depthState = state
        
        sampler = Sampler(descriptor: createSamplerDescriptor(), device: device)
        
        
        materialTextureLoader = Texture.createTextureLoader(device: device)
        
        library = device.makeDefaultLibrary()
        super.init()
        
        // These are used for blank material textures...
        Texture.blackColour = Texture.createBlankTexture(colour: [0, 0, 0, 255], device: device)
        Texture.whiteColour = Texture.createBlankTexture(colour: [255, 255, 255, 255], device: device)
        Texture.blankNormalMap = Texture.createBlankNormalMap(device: device)
        
        createRenderTargets(view: metalKitView)
        
        
        let skyboxVertexFunction = library?.makeFunction(name: "SkyboxVertexShader")
        let skyboxFragmentFunction = library?.makeFunction(name: "SkyboxFragmentShader")
        // And now the skybox
        skybox = Skybox(device: device,
                        vertexFunction: skyboxVertexFunction,
                        fragmentFunction: skyboxFragmentFunction,
                        colourPixelFormat: colourResolvedTarget.pixelFormat,
                        depthStencilPixelFormat: .depth32Float)
        
        
        let finalVertexFunction = library?.makeFunction(name: "PostProcessVertexShader")
        let finalFragmentFunction = library?.makeFunction(name: "PostProcessFragmentShader")
        let finalPipelineDescriptor = MTLRenderPipelineDescriptor()
        finalPipelineDescriptor.vertexFunction = finalVertexFunction
        finalPipelineDescriptor.fragmentFunction = finalFragmentFunction
        finalPipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        finalPipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        finalPipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        
        do {
            try finalRenderPipelineState = device.makeRenderPipelineState(descriptor: finalPipelineDescriptor)
        } catch let error {
            print("ERROR: Failed to create the final render pipeline state with error:\n\(error)")
            return nil
        }
        
        self.scene.sceneResponder = self
        
    }
    
    func initialiseScene() {
        
        scene.sceneInit()
        
        modelMatrices.append(matrix_identity_float4x4)
        
        // At this point, we only have an array full of model view matrices. We have to create the object
        // transform structures
        for modelMatrix in modelMatrices {
            var transform = ObjectTransforms()
            transform.modelViewMatrix = cameraController.camera.currentViewMatrix * modelMatrix
            transform.normalMatrix = Maths.createNormalMatrix(fromMVMatrix: transform.modelViewMatrix)
            objectTransforms.append(transform)
        }
        
        // Here we update all buffer constants...
        var bufferLength = MemoryLayout<PerFrameConstants>.stride
        bufferLength += MemoryLayout<ObjectTransforms>.stride * objectTransforms.count
        for _ in 0..<buffersInFlight {
            
            if let buffer = device.makeBuffer(length: bufferLength, options: .cpuCacheModeWriteCombined) {
                updateAllConstants(buffer)
                constantBuffers.append(buffer)
            }
            
        }
        
        // We're creating handles to the shaders...
        let vertexFunction = library?.makeFunction(name: "helloVertexShader")
        let fragmentFunction = library?.makeFunction(name: "helloFragmentShader")
        
        // Here we create the render pipeline state. However, Metal doesn't allow
        // us to create one directly; we must use a descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = colourResolvedTarget.pixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.vertexDescriptor = gameObjects[0].mesh.vertexDescriptor
        pipelineDescriptor.sampleCount = sampleCount
        pipelineDescriptor.label = "Main Render Pipeline State"
        
        do {
            try meshPipelineState = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            print("ERROR: Failed to create the render pipeline state with error:\n\(error)")
        }
        
    }
    
    func addedToScene(object: GameObject, position: SIMD3<Float>) {
        
        // Add the object to the rendering queue along with its position...
        gameObjects.append(object)
        let modelMatrix = Maths.createTranslationMatrix(vector: position)
        modelMatrices.append(modelMatrix)
        
        // Then we compute its MV matrix along with its normal matrix...
        var transform = ObjectTransforms()
        transform.modelViewMatrix = cameraController.camera.currentViewMatrix * modelMatrix
        transform.normalMatrix = Maths.createNormalMatrix(fromMVMatrix: transform.modelViewMatrix)
        objectTransforms.append(transform)
        
    }
    
    func orbitCameraWasSet(withRadius radius: Float, azimuth: Float, elevation: Float, origin: SIMD3<Float>) {
        
        let aspectRatio = Float(viewSize.width) / Float(viewSize.height)
        
        let camera = OrbitCamera(fovy: Maths.degreesToRadians(degrees: 65.0),
                                 aspectRatio: aspectRatio,
                                 nearZ: 0.1,
                                 farZ: 100.0,
                                 radius: radius,
                                 azimuth: azimuth,
                                 elevation: elevation,
                                 origin: origin)
        
        cameraController = OrbitCameraController(camera: camera)
        
        let projectionMatrix = cameraController.camera.projectionMatrix
        
        // Then the frame constants (which are consistent across all objects)
        frameConstants.projectionMatrix = projectionMatrix
        frameConstants.cameraPosition = cameraController.camera.position
        
        // Allocate the skybox constant buffers. We'll also use 3 in case of triple-buffering
        var skyConstants = SkyboxTransforms()
        skyConstants.modelViewProjectionMatrix = projectionMatrix * camera.rotationMatrix
        skyboxTransforms = Array<SkyboxTransforms>(repeating: skyConstants, count: buffersInFlight)
        
    }
    
    /// This function is called each frame to update per-object and  per-frame data before rendering
    func updateGameState() {
        
        // Update the camera position
        cameraController.camera.updateState()
        frameConstants.cameraPosition = cameraController.camera.position
        
        let projectionMatrix = cameraController.camera.projectionMatrix
        let viewMatrix = cameraController.camera.currentViewMatrix
        
        // Next we update all the per-object constants in the array
        for (i, modelMatrix) in modelMatrices.enumerated() {
            
            let modelViewMatrix = viewMatrix * modelMatrix
            let normalMatrix = Maths.createNormalMatrix(fromMVMatrix: modelViewMatrix)
            var transforms = ObjectTransforms()
            transforms.modelViewMatrix = modelViewMatrix
            transforms.normalMatrix = normalMatrix
            
            objectTransforms[i] = transforms
            
        }
        
        // After which, we store them in the active constant buffer
        updateAllConstants(constantBuffers[constantBufferIndex])
        
        // Then the skybox. It keeps the scene alive... it's the real MVP :')
        let skyMVP = projectionMatrix * cameraController.camera.rotationMatrix
        skyboxTransforms[constantBufferIndex].modelViewProjectionMatrix = skyMVP
        
    }
    
    
    func draw(in view: MTKView) {
        /// Per frame updates hare
        
        // Halt the execution of this function until the semaphore is signalled
        let _ = semaphore.wait(timeout: .distantFuture)
        
        // So now we need a command buffer...
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            
            commandBuffer.label = "Application Command Buffer"
            updateGameState()
            
            // First pass, which is render the geometry to a texture...
            // Configure the render pass descriptor to use our colour and depth textures
            // We need to be explicit because we don't have an MTKView that provides our descriptor
            let firstPassDescriptor = MTLRenderPassDescriptor()
            firstPassDescriptor.colorAttachments[0].texture = colourMultisampleTarget
            firstPassDescriptor.colorAttachments[0].resolveTexture = colourResolvedTarget
            firstPassDescriptor.colorAttachments[0].loadAction = .dontCare
            firstPassDescriptor.colorAttachments[0].storeAction = .storeAndMultisampleResolve
            firstPassDescriptor.depthAttachment.texture = depthMultisampleTarget
            firstPassDescriptor.depthAttachment.resolveTexture = depthResolvedTarget
            firstPassDescriptor.depthAttachment.loadAction  = .clear
            firstPassDescriptor.depthAttachment.storeAction = .storeAndMultisampleResolve
            firstPassDescriptor.depthAttachment.clearDepth = 1.0
            
            // Then we encode commands like we did before
            let firstPassRenderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: firstPassDescriptor)!
            firstPassRenderEncoder.label = "First pass render command encoder"
            firstPassRenderEncoder.pushDebugGroup("Setting the cull mode")
            firstPassRenderEncoder.setFrontFacing(.counterClockwise)
            firstPassRenderEncoder.setCullMode(.back)
            firstPassRenderEncoder.popDebugGroup()
            
            firstPassRenderEncoder.pushDebugGroup("Tackling the Skybox")
            let skyboxConstantBuffer = skyboxTransforms[constantBufferIndex]
            skybox.draw(encoder: firstPassRenderEncoder, constants: skyboxConstantBuffer)
            firstPassRenderEncoder.popDebugGroup()
            
            firstPassRenderEncoder.pushDebugGroup("Assigning render and depth states")
            firstPassRenderEncoder.setRenderPipelineState(meshPipelineState)
            firstPassRenderEncoder.setDepthStencilState(depthState)
            firstPassRenderEncoder.popDebugGroup()
            
            let constantBuffer = constantBuffers[constantBufferIndex]
            
            firstPassRenderEncoder.setVertexBuffer(constantBuffer, offset: 0, index: BufferIndex.localUniforms.rawValue)
            firstPassRenderEncoder.setVertexBuffer(constantBuffer, offset: 0, index: BufferIndex.perFrameConstants.rawValue)
            firstPassRenderEncoder.setFragmentBuffer(constantBuffer, offset: 0, index: BufferIndex.perFrameConstants.rawValue)
            firstPassRenderEncoder.setFragmentTexture(skybox.texture, index: TextureIndex.irradiance.rawValue)
            
            // Below looks kinda complex, but it really isn't. All we do is iterate though all meshes,
            // bind their constants to the shaders, and then draw them. We increment the buffer offset in each
            // step to select the correct region of the constant buffer
            var offset = MemoryLayout<PerFrameConstants>.stride
            let stride = MemoryLayout<ObjectTransforms>.stride
            for (_, object) in gameObjects.enumerated() {
                firstPassRenderEncoder.pushDebugGroup("Working on \(object.mesh.mtkMesh.name)")
                
                object.draw(usingEncoder: firstPassRenderEncoder, constantBufferOffset: offset)
                
                offset += stride
                firstPassRenderEncoder.popDebugGroup()
            }
            
            firstPassRenderEncoder.endEncoding()
            
            
            // Now for the second pass, after rendering
            let postRenderPassDescriptor = view.currentRenderPassDescriptor!
            postRenderPassDescriptor.colorAttachments[0].loadAction = .dontCare
            let finalRenderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: postRenderPassDescriptor)!
            
            finalRenderEncoder.pushDebugGroup("Performing the final draw pass")
            finalRenderEncoder.setRenderPipelineState(finalRenderPipelineState)
            finalRenderEncoder.setVertexBytes(MeshGeometry.screenQuadArray,
                                              length: MeshGeometry.screenQuadArray.count * MemoryLayout<Float32>.size,
                                              index: 0)
            finalRenderEncoder.setFragmentTexture(colourResolvedTarget, index: 0)
            finalRenderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            finalRenderEncoder.endEncoding()
            finalRenderEncoder.popDebugGroup()
            
            commandBuffer.present(view.currentDrawable!)
            finalRenderEncoder.label = "Final render command encoder"
            
            commandBuffer.addCompletedHandler {_ in
                self.semaphore.signal()
            }
            commandBuffer.commit()
            constantBufferIndex = (constantBufferIndex + 1) % buffersInFlight
            
        }
        
    }
    
    /// A function used to update all values in the `MTLBuffer` containing the per-frame and per-object data
    /// - Parameter buffer: The buffer we want to update the contents of
    func updateAllConstants(_ buffer: MTLBuffer) {
        
        // This is the pointer to the beginning of the buffer contents
        var ptr = buffer.contents()
        
        // Populate the frame constants
        ptr.copyMemory(from: &frameConstants, byteCount: MemoryLayout<PerFrameConstants>.stride)
        ptr += MemoryLayout<PerFrameConstants>.stride
        
        // Then the per-object constants. We constantly offset the pointer to change the region
        // of the buffer, after which we copy the data for each object
        let stride = MemoryLayout<ObjectTransforms>.stride
        for (i, _) in objectTransforms.enumerated() {
            ptr.copyMemory(from: &objectTransforms[i], byteCount: stride)
            ptr += stride
        }
        
    }
    
    /// Creates the render targets for the initial and final rendering pass
    /// - Parameter view: The view which will be drawn into
    func createRenderTargets(view: MTKView) {
        
        let width = Int(view.drawableSize.width)
        let height = Int(Int(view.drawableSize.height))
        
        let multiSampleTextureDescriptor = MTLTextureDescriptor()
        multiSampleTextureDescriptor.width = width
        multiSampleTextureDescriptor.height = height
        multiSampleTextureDescriptor.pixelFormat = .rgba16Float
        multiSampleTextureDescriptor.textureType = .type2DMultisample
        multiSampleTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
        multiSampleTextureDescriptor.resourceOptions = .storageModePrivate
        multiSampleTextureDescriptor.sampleCount = sampleCount
        
        colourMultisampleTarget = device.makeTexture(descriptor: multiSampleTextureDescriptor)
        
        // Then create the resolved colour render target first
        let colourTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float,
                                                                               width: width,
                                                                               height: height,
                                                                               mipmapped: false)
        colourTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
        colourTextureDescriptor.resourceOptions = .storageModePrivate
        
        colourResolvedTarget = device.makeTexture(descriptor: colourTextureDescriptor)
        
        // Then the depth multisample target for its pass
        let depthMultisampleDescriptor = MTLTextureDescriptor()
        depthMultisampleDescriptor.width = width
        depthMultisampleDescriptor.height = height
        depthMultisampleDescriptor.pixelFormat = .depth32Float
        depthMultisampleDescriptor.textureType = .type2DMultisample
        depthMultisampleDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
        depthMultisampleDescriptor.resourceOptions = .storageModePrivate
        depthMultisampleDescriptor.sampleCount = sampleCount
        
        depthMultisampleTarget = device.makeTexture(descriptor: depthMultisampleDescriptor)
        
        // Finally, the resolved depth texture
        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float,
                                                                              width: width,
                                                                              height: height,
                                                                              mipmapped: false)
        depthTextureDescriptor.usage = .renderTarget
        depthTextureDescriptor.resourceOptions = .storageModePrivate
        depthResolvedTarget = device.makeTexture(descriptor: depthTextureDescriptor)
        
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        /// Respond to drawable size or orientation changes here
        
        let aspect = Float(size.width) / Float(size.height)
        cameraController.camera.projectionMatrix = Maths.createProjectionMatrix(fovy: Maths.degreesToRadians(degrees: 65.0),
                                                               aspectRatio: aspect,
                                                               nearZ: 0.1,
                                                               farZ: 100.0)
        frameConstants.projectionMatrix = cameraController.camera.projectionMatrix
        
    }
    
    
}


