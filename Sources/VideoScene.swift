//
//  VideoScene.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/19.
//  Copyright © 2017 eje Inc. All rights reserved.
//

#if (arch(i386) || arch(x86_64)) && os(iOS)
    // Not available on iOS Simulator
#else

import SceneKit
import AVFoundation

public protocol VideoSceneProtocol: class {
    var player: AVPlayer? { get set }
}

public final class MonoSphericalVideoScene: MonoSphericalMediaScene, VideoSceneProtocol {
    private var playerTexture: MTLTexture? {
        didSet {
            mediaSphereNode.mediaContents = playerTexture
        }
    }

    private lazy var renderLoop: RenderLoop = {
        return RenderLoop { [weak self] time in
            self?.renderVideo(atTime: time)
        }
    }()

    private let renderer: PlayerRenderer
    private let commandQueue: MTLCommandQueue

    public var player: AVPlayer? {
        didSet {
            renderer.player = player
        }
    }

    public override var isPaused: Bool {
        didSet {
            if isPaused {
                renderLoop.pause()
            } else {
                renderLoop.resume()
            }
        }
    }

    public init(device: MTLDevice, outputSettings: [String: Any]? = nil) throws {
        renderer = try PlayerRenderer(device: device, outputSettings: outputSettings)
        commandQueue = device.makeCommandQueue()
        super.init()
        renderLoop.resume()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateTextureIfNeeded() {
        guard let videoSize = renderer.itemRenderer.playerItem?.presentationSize, videoSize != .zero else {
            return
        }

        let width = Int(videoSize.width)
        let height = Int(videoSize.height)

        if let texture = playerTexture, texture.width == width, texture.height == height {
            return
        }

        let pixelFormat: MTLPixelFormat
        if #available(iOS 10, *) {
            pixelFormat = .bgra8Unorm_srgb
        } else {
            pixelFormat = .bgra8Unorm
        }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: true)
        playerTexture = renderer.itemRenderer.device.makeTexture(descriptor: descriptor)
    }

    public func renderVideo(atTime time: TimeInterval, commandQueue: MTLCommandQueue? = nil) {
        guard renderer.hasNewPixelBuffer(atHostTime: time) else {
            return
        }

        updateTextureIfNeeded()

        guard let texture = playerTexture else {
            return
        }

        do {
            let commandBuffer = (commandQueue ?? self.commandQueue).makeCommandBuffer()
            try renderer.render(atHostTime: time, to: texture, commandBuffer: commandBuffer)
            commandBuffer.commit()
        } catch let error as CVError {
            debugPrint("[MonoSphericalVideoScene] failed to render video with error: \(error)")
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

public final class StereoSphericalVideoScene: StereoSphericalMediaScene, VideoSceneProtocol {
    private var playerTexture: MTLTexture?

    private var leftSphereTexture: MTLTexture? {
        didSet {
            leftMediaSphereNode.mediaContents = leftSphereTexture
        }
    }

    private var rightSphereTexture: MTLTexture? {
        didSet {
            rightMediaSphereNode.mediaContents = rightSphereTexture
        }
    }

    private lazy var renderLoop: RenderLoop = {
        return RenderLoop { [weak self] time in
            self?.renderVideo(atTime: time)
        }
    }()

    private let renderer: PlayerRenderer
    private let commandQueue: MTLCommandQueue

    public var player: AVPlayer? {
        didSet {
            renderer.player = player
        }
    }

    public override var isPaused: Bool {
        didSet {
            if isPaused {
                renderLoop.pause()
            } else {
                renderLoop.resume()
            }
        }
    }

    public init(device: MTLDevice, outputSettings: [String: Any]? = nil) throws {
        renderer = try PlayerRenderer(device: device, outputSettings: outputSettings)
        commandQueue = device.makeCommandQueue()
        super.init()
        renderLoop.resume()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateTexturesIfNeeded() {
        guard let videoSize = renderer.itemRenderer.playerItem?.presentationSize, videoSize != .zero else {
            return
        }

        let width = Int(videoSize.width)
        let height = Int(videoSize.height)

        if let texture = playerTexture, texture.width == width, texture.height == height {
            return
        }

        let device = renderer.device

        let playerTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: width, height: height, mipmapped: true)
        playerTexture = device.makeTexture(descriptor: playerTextureDescriptor)

        let sphereTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: width, height: height / 2, mipmapped: true)
        leftSphereTexture = device.makeTexture(descriptor: sphereTextureDescriptor)
        rightSphereTexture = device.makeTexture(descriptor: sphereTextureDescriptor)
    }

    public func renderVideo(atTime time: TimeInterval, commandQueue: MTLCommandQueue? = nil) {
        guard renderer.hasNewPixelBuffer(atHostTime: time) else {
            return
        }

        updateTexturesIfNeeded()

        guard let playerTexture = playerTexture else {
            return
        }

        let commandBuffer = (commandQueue ?? self.commandQueue).makeCommandBuffer()

        do {
            try renderer.render(atHostTime: time, to: playerTexture, commandBuffer: commandBuffer)

            func copyPlayerTexture(region: MTLRegion, to sphereTexture: MTLTexture) {
                let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
                blitCommandEncoder.copy(
                    from: playerTexture,
                    sourceSlice: 0,
                    sourceLevel: 0,
                    sourceOrigin: region.origin,
                    sourceSize: region.size,
                    to: sphereTexture,
                    destinationSlice: 0,
                    destinationLevel: 0,
                    destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0)
                )
                blitCommandEncoder.endEncoding()
            }

            let halfHeight = playerTexture.height / 2

            if let leftTexture = leftSphereTexture {
                let leftSphereRegion = MTLRegionMake2D(0, 0, playerTexture.width, halfHeight)
                copyPlayerTexture(region: leftSphereRegion, to: leftTexture)
            }

            if let rightTexture = rightSphereTexture {
                let rightSphereRegion = MTLRegionMake2D(0, halfHeight, playerTexture.width, halfHeight)
                copyPlayerTexture(region: rightSphereRegion, to: rightTexture)
            }

            commandBuffer.commit()
        } catch let error as CVError {
            debugPrint("[StereoSphericalVideoScene] failed to render video with error: \(error)")
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

#endif
