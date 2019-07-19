//
//  PanoramaPinchGestureManager.swift
//  MetalScope
//
//  Created by Jesly Varghese on 17/07/19.
//  Copyright © 2019 eje Inc. All rights reserved.
//

import UIKit
import SceneKit

final class PanoramaPinchGestureManager: NSObject {
    let camera: SCNCamera?
    var minimumZoom: CGFloat
    var maximumZoom: CGFloat
    var lastScale: CGFloat
    
    lazy var gestureRecognizer: UIPinchGestureRecognizer = {
        let recognizer = UIPinchGestureRecognizer()
        recognizer .addTarget(self, action: #selector(handlePanGesture(_:)))
        return recognizer
    }()
    
    @objc func handlePanGesture(_ sender: UIPinchGestureRecognizer) {
        var fieldOfView: CGFloat
        switch sender.state {
        case .began, .changed:
            let scale = sender.scale
            fieldOfView =  camera!.fieldOfView - (scale*(sender.velocity * 1.1))
            if fieldOfView < minimumZoom {
                fieldOfView = minimumZoom
            }
            if fieldOfView > maximumZoom {
                fieldOfView = maximumZoom
            }
            if fieldOfView.isInfinite || fieldOfView.isNaN {
                fieldOfView = 60
            }
            SCNTransaction.lock()
            SCNTransaction.begin()
            SCNTransaction.disableActions = true
            camera!.fieldOfView = fieldOfView
            SCNTransaction.commit()
            SCNTransaction.unlock()
        case .ended:
            gestureRecognizer.scale = 1;
        default:
            break
        }
    }
    
    init(camera: SCNCamera?) {
        self.camera = camera
        self.minimumZoom = 25
        self.maximumZoom = 120
        self.lastScale = 1
    }
}
