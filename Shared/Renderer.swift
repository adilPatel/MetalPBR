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

class Renderer: NSObject, MTKViewDelegate, SceneResponderDelegate {
    
    /// A handle to our device (which is the GPU)
    public let device: MTLDevice
    
    /// Controls our camera
    public var cameraController: CameraController!
    
    /// The size of the `MTKView` used to draw into
    let viewSize: CGSize
    
    /// The scene we're rendering
    var scene: Scene
    
    /// The default shader library
    var library: MTLLibrary?
    
    /// The render pipeline state used when drawing opaque meshes
    var meshPipelineState: MTLRenderPipelineState!
    
    /// The render pipeline state used when drawing the back of solid transparent meshes
    var backfacePipelineState: MTLRenderPipelineState!
    
    /// The render pipeline state used when drawing the front of solid transparent meshes
    var frontfacePipelineState: MTLRenderPipelineState!
    
    /// The Metal depth stencil state
    var depthState: MTLDepthStencilState
    
    /// The depth stencil state used when drawing the back of solid transparent meshes
    var backfaceDepthState: MTLDepthStencilState
    
    /// The depth stencil state used when drawing the front of transparent meshes
    var frontfaceDepthState: MTLDepthStencilState
    
    /// The depth stencil state used when drawing opaque object
    var opaqueDepthState: MTLDepthStencilState
        
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
    
    /// A copy of the render colour attachment used to calculate refraction
    var refractorInputTexture: MTLTexture!
    
    /// A copy of the render depth attachment used to calculate attenuation
    var refractorDepthTexture: MTLTexture!
    
    /// The MSAA resolved colour target
    var colourTarget: MTLTexture!
    
    /// The MSAA resolved depth target
    var depthTarget: MTLTexture!
        
    /// The render pipeline state for the final render pass
    var finalRenderPipelineState: MTLRenderPipelineState!
    
    /// The array of opaque game objects we'll draw
    var gameObjects = Array<GameObject>()
    
    /// The array of transparent objects we'll draw
    var transparentObjects = Array<GameObject>()
    
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
        opaqueDepthState = state
        
        // We don't want to write the depth buffer values when rendering the front of translucent objects because
        // we read them in the shader post-rasterisation. In this example, depth buffer writes aren't needed
        // anyways, so let's create another render pipeline state!
        
        let backDepthDescriptor = MTLDepthStencilDescriptor()
        backDepthDescriptor.depthCompareFunction = .less
        backDepthDescriptor.isDepthWriteEnabled = true
        backDepthDescriptor.label = "Backface mesh depth state"
        guard let backDepth = device.makeDepthStencilState(descriptor: backDepthDescriptor) else { return nil }
        backfaceDepthState = backDepth
        
        let frontDepthDescriptor = MTLDepthStencilDescriptor()
        frontDepthDescriptor.depthCompareFunction = .less
        frontDepthDescriptor.isDepthWriteEnabled = false
        frontDepthDescriptor.label = "Frontface mesh depth state"
        guard let frontDepth = device.makeDepthStencilState(descriptor: frontDepthDescriptor) else { return nil }
        frontfaceDepthState = frontDepth
        
        
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
                        colourPixelFormat: colourTarget.pixelFormat,
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
    
    /// This function executes the scene initialiser, allocates uniform buffers, and builds pipeline states
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
        var wrongSide = false
        var rightSide = true
        
        let opaqueConstantValues = MTLFunctionConstantValues()
        opaqueConstantValues.setConstantValue(&wrongSide, type: .bool, index: FunctionConstant.backface.rawValue)
        opaqueConstantValues.setConstantValue(&wrongSide, type: .bool, index: FunctionConstant.frontface.rawValue)
        var opaqueFragmentFunction: MTLFunction?
        do {
            try opaqueFragmentFunction = library?.makeFunction(name: "helloFragmentShader", constantValues: opaqueConstantValues)
        } catch {
            print("ERROR: Could not create opaque fragment function with error: \(error)")
        }
        
        // Here we create the render pipeline state. However, Metal doesn't allow
        // us to create one directly; we must use a descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = opaqueFragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = colourTarget.pixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.vertexDescriptor = gameObjects[0].mesh.vertexDescriptor
        pipelineDescriptor.label = "Main Render Pipeline State"
        
        do {
            try meshPipelineState = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            print("ERROR: Failed to create the main render pipeline state with error:\n\(error)")
        }
        
        // Create the fragment shader for the backface...
        let backfaceConstantValues = MTLFunctionConstantValues()
        backfaceConstantValues.setConstantValue(&rightSide, type: .bool, index: FunctionConstant.backface.rawValue)
        backfaceConstantValues.setConstantValue(&wrongSide, type: .bool, index: FunctionConstant.frontface.rawValue)
        var backfaceFragmentFunction: MTLFunction?
        do {
            try backfaceFragmentFunction = library?.makeFunction(name: "helloFragmentShader", constantValues: backfaceConstantValues)
        } catch {
            print("ERROR: Could not create backface fragment function with error: \(error)")
        }
        
        // Now for the front...
        let frontfaceConstantValues = MTLFunctionConstantValues()
        frontfaceConstantValues.setConstantValue(&wrongSide, type: .bool, index: FunctionConstant.backface.rawValue)
        frontfaceConstantValues.setConstantValue(&rightSide, type: .bool, index: FunctionConstant.frontface.rawValue)
        var frontfaceFragmentFunction: MTLFunction?
        do {
            try frontfaceFragmentFunction = library?.makeFunction(name: "helloFragmentShader", constantValues: frontfaceConstantValues)
        } catch {
            print("ERROR: Could not create frontface fragment function with error: \(error)")
        }
        
        // Constructing the back of solid transparent meshes
        let backfacePipelineDescriptor = MTLRenderPipelineDescriptor()
        backfacePipelineDescriptor.vertexFunction = vertexFunction
        backfacePipelineDescriptor.fragmentFunction = backfaceFragmentFunction
        backfacePipelineDescriptor.colorAttachments[0].pixelFormat = colourTarget.pixelFormat
        backfacePipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        backfacePipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        backfacePipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        backfacePipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        backfacePipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        backfacePipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        backfacePipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        backfacePipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        backfacePipelineDescriptor.vertexDescriptor = gameObjects[0].mesh.vertexDescriptor
        backfacePipelineDescriptor.label = "Backface Pipeline State"
        
        do {
            try backfacePipelineState = device.makeRenderPipelineState(descriptor: backfacePipelineDescriptor)
        } catch let error {
            print("ERROR: Failed to create the backface render pipeline state with error:\n\(error)")
        }
        
        // In the front face, we compute both attenuation and refraction...
        let frontfacePipelineDescriptor = MTLRenderPipelineDescriptor()
        frontfacePipelineDescriptor.vertexFunction = vertexFunction
        frontfacePipelineDescriptor.fragmentFunction = frontfaceFragmentFunction
        frontfacePipelineDescriptor.colorAttachments[0].pixelFormat = colourTarget.pixelFormat
//        frontfacePipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
//        frontfacePipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
//        frontfacePipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
//        frontfacePipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .source1Color
        frontfacePipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        frontfacePipelineDescriptor.vertexDescriptor = gameObjects[0].mesh.vertexDescriptor
        frontfacePipelineDescriptor.label = "Frontface Pipeline State"
        
        do {
            try frontfacePipelineState = device.makeRenderPipelineState(descriptor: frontfacePipelineDescriptor)
        } catch let error {
            print("ERROR: Failed to create the frontface render pipeline state with error:\n\(error)")
        }
        
    }
    
    func addedToScene(object: GameObject, position: SIMD3<Float>) {
        
        // Add the object to the rendering queue along with its position...
        
        let modelMatrix = Maths.createTranslationMatrix(vector: position)
        modelMatrices.append(modelMatrix)
        
        // Then we compute its MV matrix along with its normal matrix...
        var transform = ObjectTransforms()
        transform.modelViewMatrix = cameraController.camera.currentViewMatrix * modelMatrix
        transform.normalMatrix = Maths.createNormalMatrix(fromMVMatrix: transform.modelViewMatrix)
        objectTransforms.append(transform)
        
        gameObjects.append(object)
        
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
            firstPassDescriptor.colorAttachments[0].texture = colourTarget
            firstPassDescriptor.colorAttachments[0].loadAction = .dontCare
            firstPassDescriptor.colorAttachments[0].storeAction = .store
            firstPassDescriptor.depthAttachment.texture = depthTarget
            firstPassDescriptor.depthAttachment.loadAction  = .clear
            firstPassDescriptor.depthAttachment.storeAction = .store
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
            
            firstPassRenderEncoder.pushDebugGroup("Setting local uniforms and per-frame constant")
            firstPassRenderEncoder.setVertexBuffer(constantBuffer, offset: 0, index: BufferIndex.localUniforms.rawValue)
            firstPassRenderEncoder.setVertexBuffer(constantBuffer, offset: 0, index: BufferIndex.perFrameConstants.rawValue)
            firstPassRenderEncoder.setFragmentBuffer(constantBuffer, offset: 0, index: BufferIndex.perFrameConstants.rawValue)
            firstPassRenderEncoder.setFragmentTexture(skybox.texture, index: TextureIndex.irradiance.rawValue)
            firstPassRenderEncoder.popDebugGroup()
            
            
            // Below looks kinda complex, but it really isn't. All we do is iterate though all meshes,
            // bind their constants to the shaders, and then draw them. We increment the buffer offset in each
            // step to select the correct region of the constant buffer
            
            var offset = MemoryLayout<PerFrameConstants>.stride
            let stride = MemoryLayout<ObjectTransforms>.stride
            
            // First we draw the opaque objects...
            firstPassRenderEncoder.pushDebugGroup("Drawing the opaque objects")
            firstPassRenderEncoder.setCullMode(.back) // Cull out the front
            firstPassRenderEncoder.setDepthStencilState(opaqueDepthState)
            for (i, object) in gameObjects.enumerated() {
                firstPassRenderEncoder.pushDebugGroup("Working on \(object.mesh.mtkMesh.name)")
                
                object.draw(atSubmeshIndex: i, usingEncoder: firstPassRenderEncoder, constantBufferOffset: offset)
                
                offset += stride
                firstPassRenderEncoder.popDebugGroup()
            }
            firstPassRenderEncoder.popDebugGroup()
            
            let opaqueOffset = offset
                        
            // Then we draw the back of transparent objects...
            firstPassRenderEncoder.pushDebugGroup("Drawing the back of transparent objects")
            firstPassRenderEncoder.setRenderPipelineState(backfacePipelineState)
            firstPassRenderEncoder.setCullMode(.front) // Cull out the front
            firstPassRenderEncoder.setDepthStencilState(backfaceDepthState)
            for object in gameObjects {
                firstPassRenderEncoder.pushDebugGroup("Working on back of \(object.mesh.mtkMesh.name)")

                object.drawTransparentSubmeshes(usingEncoder: firstPassRenderEncoder, constantBufferOffset: offset)

                offset += stride
                firstPassRenderEncoder.popDebugGroup()
            }
            firstPassRenderEncoder.popDebugGroup()
            
            firstPassRenderEncoder.endEncoding()
            
            // Because we're redrawing the same transparent submeshes (albeit with different states and stuff),
            // we reset the offset back to the one after drawing opaque objects...
            offset = opaqueOffset
            
            // Here we copy the colour and depth attachments into new textures which will be used to calculate
            // attenuation and refraction
            let refractorCopyEncoder = commandBuffer.makeBlitCommandEncoder()!
            refractorCopyEncoder.label = "Refractor Copy Encoder"
            refractorCopyEncoder.pushDebugGroup("Copying the colour rand depth targets into the refractor input")
            refractorCopyEncoder.copy(from: colourTarget, to: refractorInputTexture)
            refractorCopyEncoder.copy(from: depthTarget, to: refractorDepthTexture)
            refractorCopyEncoder.popDebugGroup()
            refractorCopyEncoder.endEncoding()
            
            firstPassDescriptor.colorAttachments[0].loadAction = .load
            firstPassDescriptor.depthAttachment.storeAction = .dontCare

            // Finally, draw the front of the transparent objects...
            let frontfaceEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: firstPassDescriptor)!
            frontfaceEncoder.label = "Frontface Render Command Encoder"
            frontfaceEncoder.pushDebugGroup("Drawing the front of the transparent objects")
            frontfaceEncoder.pushDebugGroup("Encoding the needed stuff")
            frontfaceEncoder.setFrontFacing(.counterClockwise)
            frontfaceEncoder.setCullMode(.back) // Cull out the back
            frontfaceEncoder.setRenderPipelineState(frontfacePipelineState)
            frontfaceEncoder.setDepthStencilState(frontfaceDepthState)
            frontfaceEncoder.setVertexBuffer(constantBuffer, offset: 0, index: BufferIndex.localUniforms.rawValue)
            frontfaceEncoder.setVertexBuffer(constantBuffer, offset: 0, index: BufferIndex.perFrameConstants.rawValue)
            frontfaceEncoder.setFragmentBuffer(constantBuffer, offset: 0, index: BufferIndex.perFrameConstants.rawValue)
            frontfaceEncoder.setFragmentTexture(refractorDepthTexture, index: TextureIndex.depth.rawValue)
            frontfaceEncoder.setFragmentTexture(refractorInputTexture, index: TextureIndex.colour.rawValue)
            frontfaceEncoder.popDebugGroup()
            for object in gameObjects {
                frontfaceEncoder.pushDebugGroup("Working on front of \(object.mesh.mtkMesh.name)")

                object.drawTransparentSubmeshes(usingEncoder: frontfaceEncoder, constantBufferOffset: offset)

                offset += stride
                frontfaceEncoder.popDebugGroup()
            }
            frontfaceEncoder.popDebugGroup()

            frontfaceEncoder.endEncoding()
            
            
            // Now for the final pass, which is post-processing...
            let postRenderPassDescriptor = view.currentRenderPassDescriptor!
            postRenderPassDescriptor.colorAttachments[0].loadAction = .dontCare
            let finalRenderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: postRenderPassDescriptor)!
            
            finalRenderEncoder.pushDebugGroup("Performing the final draw pass")
            finalRenderEncoder.setRenderPipelineState(finalRenderPipelineState)
            finalRenderEncoder.setVertexBytes(MeshGeometry.screenQuadArray,
                                              length: MeshGeometry.screenQuadArray.count * MemoryLayout<Float32>.size,
                                              index: 0)
            finalRenderEncoder.setFragmentTexture(colourTarget, index: 0)
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
        
        
        // Then create the resolved colour render target first
        let colourTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float,
                                                                               width: width,
                                                                               height: height,
                                                                               mipmapped: false)
        colourTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
        colourTextureDescriptor.resourceOptions = .storageModePrivate
        
        colourTarget = device.makeTexture(descriptor: colourTextureDescriptor)
        colourTarget.label = "Colour Resolved Render Target"
        
        let refractorInputDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float,
                                                                                width: width,
                                                                                height: height,
                                                                                mipmapped: false)
        refractorInputDescriptor.usage = .shaderRead
        refractorInputDescriptor.resourceOptions = .storageModePrivate
        refractorInputTexture = device.makeTexture(descriptor: refractorInputDescriptor)
        refractorInputTexture.label = "Refractor Input Texture"
        
        // Finally, the resolved depth texture
        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float,
                                                                              width: width,
                                                                              height: height,
                                                                              mipmapped: false)
        depthTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
        depthTextureDescriptor.resourceOptions = .storageModePrivate
        depthTarget = device.makeTexture(descriptor: depthTextureDescriptor)
        
        let refractorDepthDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float,
                                                                                width: width,
                                                                                height: height,
                                                                                mipmapped: false)
        refractorDepthDescriptor.usage = .shaderRead
        refractorDepthDescriptor.resourceOptions = .storageModePrivate
        refractorDepthTexture = device.makeTexture(descriptor: refractorDepthDescriptor)
        refractorDepthTexture.label = "Refrector Input Depth Texture"
        
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


