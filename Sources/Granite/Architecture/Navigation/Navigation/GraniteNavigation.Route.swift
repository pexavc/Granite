//
//  GraniteNavigation.Route.swift
//  
//
//  Created by PEXAVC on 1/25/23.
//

import Foundation
import SwiftUI
import GraniteUI
#if os(iOS)
import UIKit
#endif

extension View {
    public func routeButton<C: View>(title: String = "",
                                     window: GraniteRouteWindowProperties = .init(),
                                     @ViewBuilder component : @escaping (() -> C)) -> some View {
        
        let component = NavigationComponent<C>(component)
        
        let memadd = GraniteNavigation.router(for: component.routerKey).set {
            component
        }
        
        return Button {
            GraniteHaptic.light.invoke()
            GraniteNavigation.router(for: component.routerKey).push(memadd)
        } label: {
            self
        }
    }
    
    public func route<C: View>(title: String = "",
                                window: GraniteRouteWindowProperties = .init(),
                                @ViewBuilder component : @escaping (() -> C)) -> some View {
        
        let component = NavigationComponent<C>(component)
        
        let memadd = GraniteNavigation.router(for: component.routerKey).set {
            component
        }
        
        return self
            .onTapGesture {
                GraniteHaptic.light.invoke()
                GraniteNavigation.router(for: component.routerKey).push(memadd)
            }
    }
    
    public func routeIf<C: View>(_ condition: Bool,
                                 title: String = "",
                                 window: GraniteRouteWindowProperties = .init(),
                                 @ViewBuilder component : @escaping (() -> C)) -> some View {
        return Group {
            if condition {
                self.route(title: title, window: window, component: component)
            } else {
                self
            }
        }
    }
}
