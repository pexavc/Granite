import Foundation
import SceneKit
import SceneKit.ModelIO
import SwiftUI

#if os(OSX)
import AppKit
public struct SceneKitView : NSViewRepresentable {
    
    let scnView: SCNView = .init()
    let scene = SCNScene.init()
    let action: SCNAction = SCNAction.repeatForever(SCNAction.rotateBy(x: -2, y: 2, z: 0, duration: 57))
    let actionWarmer: SCNAction = SCNAction.rotateBy(x: -2, y: 2, z: 0, duration: 1.0)
    
    let nodes: [SCNNode]
    let bgColor: Color
    public init(nodes: [SCNNode], bgColor: Color) {
        self.nodes = nodes
        self.bgColor = bgColor
    }
    
    public func makeNSView(context: NSViewRepresentableContext<SceneKitView>) -> SCNView {
        
        for node in nodes {
            scene.rootNode.addChildNode(node)
        }
    
        scnView.scene = scene
        
        return scnView
    }

    public func updateNSView(_ scnView: SCNView, context: Context) {
        scnView.allowsCameraControl = true
        scnView.backgroundColor = NSColor(bgColor)
    }
    
    public func run() {
        scene.rootNode.runAction(action)
    }
    
    public func clear() {
        scene.rootNode.removeAllActions()
        scene.rootNode.cleanup()
    }
}

#else
import UIKit

public struct SceneKitView : UIViewRepresentable {
    
    let scene = SCNScene.init()
    let action: SCNAction = SCNAction.repeatForever(SCNAction.rotateBy(x: -2, y: 2, z: 0, duration: 57))

    let nodes: [SCNNode]
    let bgColor: Color
    
    public init(nodes: [SCNNode], bgColor: Color) {
        self.nodes = nodes
        self.bgColor = bgColor
    }
    
    public func makeUIView(context: UIViewRepresentableContext<SceneKitView>) -> SCNView {
   
        for node in nodes {
            scene.rootNode.addChildNode(node)
        }
        
        let scnView = SCNView()
        scnView.scene = scene
        return scnView
    }

    public func updateUIView(_ scnView: SCNView, context: Context) {
        scnView.allowsCameraControl = true
        
        if #available(iOS 14.0, *) {
            scnView.backgroundColor = .init(bgColor)
        } else {
            scnView.backgroundColor = .black
        }
    }
    
    public func run() {
        scene.rootNode.runAction(action)
    }
    
    public func clear() {
        scene.rootNode.removeAllActions()
        scene.rootNode.cleanup()
    }
}
#endif

extension SCNNode {
    public func cleanup() {
        for child in childNodes {
            child.cleanup()
        }
        geometry = nil
        removeFromParentNode()
    }
}
