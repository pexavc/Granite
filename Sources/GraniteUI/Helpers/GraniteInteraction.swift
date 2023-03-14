//
//  GraniteInteraction.swift
//
//
//  Created by PEXAVC on 2/26/21.
//

import Foundation
import SwiftUI

public struct GraniteInteraction {
    
    public struct Tranlate {
        public let point: CGPoint
        
        public static var publisher = NotificationCenter.default.publisher(for: Notification.Name(rawValue: "granite_interaction_translate"))
    }
}

#if os(OSX)
import AppKit
public struct GraniteTranslationEventView : NSViewRepresentable {
    
    public class MouseView : NSView {
        public override var acceptsFirstResponder: Bool {
            true
        }
        
        public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
            return true
        }
                
        public override func scrollWheel(with event: NSEvent) {
            NotificationCenter.default.post(name: Notification.Name("granite_interaction_translate"),
                                            object: GraniteInteraction.Tranlate.init(point: .init(x: event.deltaX, y: event.deltaY)))
        }
    }
    
    public func makeNSView(context: Context) -> some NSView {
        let view = MouseView()
        
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }
    
    public func updateNSView(_ nsView: NSViewType, context: Context) {
        
    }
}
#else

#endif
