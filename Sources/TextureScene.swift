//
//  MTLTextureScene.swift
//  MetalScope
//
//  Created by Jesly Varghese on 18/09/19.
//  Copyright © 2019 eje Inc. All rights reserved.
//

import UIKit
import Metal

public protocol TextureScene: class {
    var texture: MTLTexture? {get set}
}

@objc public final class MonoSphericalTextureScene: MonoSphericalMediaScene, TextureScene {
    public var texture: MTLTexture? {
        didSet {
            mediaSphereNode.mediaContents = texture;
        }
    }
}
