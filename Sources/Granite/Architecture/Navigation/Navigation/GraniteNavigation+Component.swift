//
//  GraniteNavigation+Component.swift
//  
//
//  Created by PEXAVC on 8/21/23.
//

import Foundation
import SwiftUI

struct NavigationComponent<Content: View>: GraniteComponent {
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

extension NavigationComponent: View {
    public var view: some View {
        content()
    }
}
