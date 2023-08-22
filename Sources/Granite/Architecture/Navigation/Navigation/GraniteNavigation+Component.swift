//
//  GraniteNavigation+Component.swift
//  
//
//  Created by PEXAVC on 8/21/23.
//

import Foundation
import SwiftUI

struct NavigationComponent<Content: View>: GraniteComponent {
    @Environment(\.graniteNavigationRouterKey) var routerKey: String
    @Environment(\.graniteNavigationDestinationStyle) var destinationStyle: GraniteNavigationDestinationStyle
    
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
    public init(backgroundColor: Color = .clear,
                @ViewBuilder _ content: @escaping (() -> Content),
                _ provider: ((String, Self) -> Void)? = nil) {
        self.content = content
        self.backgroundColor = backgroundColor
        provider?(routerKey, self)
    }
}

extension NavigationComponent: View {
    public var view: Content {
        content()
    }
}
