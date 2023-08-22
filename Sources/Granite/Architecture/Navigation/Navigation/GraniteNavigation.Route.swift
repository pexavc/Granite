//
//  GraniteNavigation.Route.swift
//  
//
//  Created by PEXAVC on 1/25/23.
//

import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

//MARK: GraniteRouter
struct GraniteRouter: View {
    @EnvironmentObject var routes: GraniteNavigation
    
    var keys: [String] {
        routes.isActive.keys.map { "\($0)" }
    }
    
    func isActive(_ id: String) -> Binding<Bool> {
        .init(get: {
            if routes.isActive[id] == true {
                GraniteLog("GranitePath isActive detected \(keys.count)", level: .debug)
            }
            return routes.isActive[id] == true
        }, set: { state in
            routes.isActive[id] = state
        })
    }
    
    var body: some View {
        Group {
#if os(iOS)
            ForEach(Array(routes.stack), id: \.self) { id in
                if let path = routes.paths[id] {
                    path
                        .environment(\.graniteNavigationRouterKey, routes.id)
                }
            }
            
            //Text("\(routes.id)")
            //Text("Level: \(routes.level), last addr: \(routes.stack.last ?? "")")
#else
            EmptyView()
#endif
        }
        .onAppear {
            GraniteLog("New Stack Appeared: \(routes.id)", level: .debug)
        }
        .onDisappear {
            routes.releaseStack()
            GraniteLog("Navigation GraniteRouter Disappeared", level: .debug)
        }
    }
}

extension View {
    
    public func routeButton<C: View>(title: String = "",
                                     window: GraniteRouteWindowProperties = .init(),
                                     @ViewBuilder component : @escaping (() -> C)) -> some View {
        
        let component = NavigationComponent<C>(component)
        
        let memadd = GraniteNavigation.router(for: component.routerKey).set {
            component
        }
        
        return Button {
            //TODO: reusable.
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            GraniteNavigation
                .router(for: component.routerKey)
                .push(memadd, window: window)
        } label: {
            self
        }
    }
    
    public func routeButton<C: GraniteNavigationDestination>(title: String = "",
                                     window: GraniteRouteWindowProperties = .init(),
                                     @ViewBuilder component : @escaping (() -> C)) -> some View {
        
        let component = NavigationComponent<C>(component)
        
        let memadd = GraniteNavigation
            .router(for: component.routerKey)
            .set(destinationStyle: component.destinationStyle) {
            component
        }
        
        return Button {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            GraniteNavigation
                .router(for: component.routerKey)
                .push(memadd, window: window)
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
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
                GraniteNavigation
                    .router(for: component.routerKey)
                    .push(memadd, window: window)
            }
    }
    
    public func route<C: GraniteNavigationDestination>(title: String = "",
                                                       window: GraniteRouteWindowProperties = .init(),
                                                       @ViewBuilder component : @escaping (() -> C)) -> some View {
        
        let component = NavigationComponent<C>(component)
        
        let memadd = GraniteNavigation.router(for: component.routerKey).set {
            component
        }
        
        return self
            .onTapGesture {
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
                GraniteNavigation
                    .router(for: component.routerKey)
                    .push(memadd, window: window)
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
    
    public func routeIf<C: GraniteNavigationDestination>(_ condition: Bool,
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

public extension GraniteNavigation {
    @MainActor
    static func push<Component: View>(destinationStyle: GraniteNavigationDestinationStyle = .init(),
                                      window: GraniteRouteWindowProperties = .init(),
                                      @ViewBuilder _ component: @escaping (() -> Component)) {
        
        let component = NavigationComponent<Component>(component)
        
        let memadd = GraniteNavigation.router(for: component.routerKey).set {
            component
        }
        
        GraniteNavigation.router(for: component.routerKey).push(memadd, window: window)
    }
    
    @MainActor
    static func push<Component: GraniteNavigationDestination>(window: GraniteRouteWindowProperties = .init(),
                                                              @ViewBuilder _ component: @escaping (() -> Component)) {
        
        let component = NavigationComponent<Component>(component)
        
        let memadd = GraniteNavigation.router(for: component.routerKey).set(destinationStyle: component.destinationStyle) {
            component
        }
        
        GraniteNavigation
            .router(for: component.routerKey)
            .push(memadd, window: window)
    }
}
