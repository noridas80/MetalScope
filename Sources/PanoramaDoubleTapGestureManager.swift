//
//  PanoramaDoubleTapGestureRecognizer.swift
//  MetalScope
//
//  Created by Jesly Varghese on 17/07/19.
//  Copyright © 2019 eje Inc. All rights reserved.
//

import UIKit
import SceneKit

class PanoramaDoubleTapGestureManager: NSObject {
    let camera: SCNCamera?
    
    lazy var gestureRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer()
        recognizer.numberOfTapsRequired = 2
        recognizer .addTarget(self, action: #selector(handleTapGesture(_:)))
        return recognizer
    }()
    
    @objc func handleTapGesture(_ sender: UIPinchGestureRecognizer) {
        SCNTransaction.lock()
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(controlPoints: 0.165, 0.84, 0.44, 1)
        self.camera?.fieldOfView = 60
        SCNTransaction.commit()
        SCNTransaction.unlock()
    }
        
        
    init(camera: SCNCamera?) {
        self.camera = camera
    }
}
