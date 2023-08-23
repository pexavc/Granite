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
                        .environment(\.graniteRouter, routes.asRouter)
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
                                     @ViewBuilder component : @escaping (() -> C),
                                     with router: @escaping (() -> GraniteNavigation.Router)) -> some View {
        
        let component = NavigationComponent<C>(component)
        let router = router()
        let memadd = router.navigation.set {
            component
        }
        
        return Button {
            //TODO: reusable.
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            router.navigation.push(memadd, window: window)
        } label: {
            self
        }
    }
    
    public func routeButton<C: GraniteNavigationDestination>(title: String = "",
                                                             window: GraniteRouteWindowProperties = .init(),
                                                             @ViewBuilder component : @escaping (() -> C),
                                                             with router: @escaping (() -> GraniteNavigation.Router)) -> some View {
        
        let component = NavigationComponent<C>(component)
        
        let router = router()
        let memadd = router.navigation.set(destinationStyle: component.destinationStyle) {
            component
        }
        
        return Button {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            router.navigation.push(memadd, window: window)
        } label: {
            self
        }
    }
    
    public func route<C: View>(title: String = "",
                               window: GraniteRouteWindowProperties = .init(),
                               @ViewBuilder component : @escaping (() -> C),
                               with router: @escaping (() -> GraniteNavigation.Router)) -> some View {
        
        let component = NavigationComponent<C>(component)
        
        let router = router()
        let memadd = router.navigation.set {
            component
        }
        
        return self
            .onTapGesture {
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
                router.navigation.push(memadd, window: window)
            }
    }
    
    public func route<C: GraniteNavigationDestination>(title: String = "",
                                                       window: GraniteRouteWindowProperties = .init(),
                                                       @ViewBuilder component : @escaping (() -> C),
                                                       with router: @escaping (() -> GraniteNavigation.Router)) -> some View {
        
        let component = NavigationComponent<C>(component)
        
        let router = router()
        let memadd = router.navigation.set {
            component
        }
        
        return self
            .onTapGesture {
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
                router.navigation.push(memadd, window: window)
            }
    }
    
    public func routeIf<C: View>(_ condition: Bool,
                                 title: String = "",
                                 window: GraniteRouteWindowProperties = .init(),
                                 @ViewBuilder component : @escaping (() -> C),
                                 with router: @escaping (() -> GraniteNavigation.Router)) -> some View {
        return Group {
            if condition {
                self.route(title: title, window: window, component: component, with: router)
            } else {
                self
            }
        }
    }
    
    public func routeIf<C: GraniteNavigationDestination>(_ condition: Bool,
                                                         title: String = "",
                                                         window: GraniteRouteWindowProperties = .init(),
                                                         @ViewBuilder component : @escaping (() -> C),
                                                         with router: @escaping (() -> GraniteNavigation.Router)) -> some View {
        return Group {
            if condition {
                self.route(title: title, window: window, component: component, with: router)
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
        
        self.main.push(destinationStyle: destinationStyle, window: window, component)
    }
    
    func push<Component: View>(destinationStyle: GraniteNavigationDestinationStyle = .init(),
                                      window: GraniteRouteWindowProperties = .init(),
                                      @ViewBuilder _ component: @escaping (() -> Component)) {
        
        let component = NavigationComponent<Component>(component)
        
        let memadd = GraniteNavigation.main.set {
            component
        }
        
        GraniteNavigation.main.push(memadd, window: window)
    }
    
    @MainActor
    static func push<Component: GraniteNavigationDestination>(window: GraniteRouteWindowProperties = .init(),
                                                              @ViewBuilder _ component: @escaping (() -> Component)) {
        
        self.main.push(window: window, component)
    }
    
    func push<Component: GraniteNavigationDestination>(window: GraniteRouteWindowProperties = .init(),
                                                              @ViewBuilder _ component: @escaping (() -> Component)) {
        
        let component = NavigationComponent<Component>(component)
        
        let memadd = GraniteNavigation.main.set(destinationStyle: component.destinationStyle) {
            component
        }
        
        GraniteNavigation
            .main
            .push(memadd, window: window)
    }
}
