//
//  MTLTextureLoadable.swift
//  MetalScope
//
//  Created by Jesly Varghese on 18/09/19.
//  Copyright © 2019 eje Inc. All rights reserved.
//
import SceneKit
import UIKit

public protocol TextureLoadable {
    func load(_ texture: MTLTexture)
}

extension TextureLoadable where Self: SceneLoadable {
    public func load(_ texture: MTLTexture) {
        scene = TextureSceneLoader().load(texture)
    }
}

public struct TextureSceneLoader {
    public init() {}
    
    public func load(_ texture: MTLTexture) -> SCNScene {
        let scene: TextureScene
        scene = MonoSphericalTextureScene()
        scene.texture = texture
        return scene as! SCNScene
    }
}
