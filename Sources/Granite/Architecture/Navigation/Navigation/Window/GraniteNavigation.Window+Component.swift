//
//  GraniteNavigation.Window+Component.swift
//  
//
//  Created by PEXAVC on 8/21/23.
//

import Foundation
import SwiftUI

public struct WindowComponent<Content: View>: GraniteComponent {
    public struct Center: GraniteCenter {
        public struct State: GraniteState {
            public init() {}
        }
        
        @Store public var state: State
        
        public init() {}
    }
    
    @Command public var center: Center
    
    var content: (() -> Content)
    var backgroundColor: Color
    public init(backgroundColor: Color,
                @ViewBuilder content: @escaping (() -> Content)) {
        self.content = content
        self.backgroundColor = backgroundColor
    }
}

extension WindowComponent: View {
    public var view: some View {
        #if os(macOS)
        ZStack {
            Text("Granite Window")
        }
        .onReceive(Granite.App.Lifecycle.didFinishLaunching.publisher) { _ in
            GraniteNavigationWindow.backgroundColor = NSColor(backgroundColor)
            
            GraniteNavigationWindow.shared.addWindow(id: GraniteNavigationWindow.defaultMainWindowId,
                                                     props: .resizable(900, 600).minSize(900, 600),
                                                     isMain: true) {
                content()
            }
        }
        #else
        EmptyView()
        #endif
    }
}
