//
//  GraniteNavigation.Route.swift
//  
//
//  Created by PEXAVC on 1/25/23.
//

import Foundation
import SwiftUI

extension View {
    public func route<C: GraniteComponent, O: GranitePayload>(payload: O? = nil,
                                                              @ViewBuilder component : @escaping (() -> C)) -> some View {
        let modifier = NavigationRouteComponentModifier<C, O>(component: component, payload: payload)
        
        return self.modifier(modifier)
    }
    
    public func routeIf<C: View>(_ condition: Bool,
                                 @ViewBuilder component : @escaping (() -> C)) -> some View {
        Group {
            if condition {
                let modifier = NavigationRouteViewModifier<C>(component: component)
                
                self.modifier(modifier)
            } else {
                self
            }
        }
    }
    
    public func route<C: View>(@ViewBuilder component : @escaping (() -> C)) -> some View {
        let modifier = NavigationRouteViewModifier<C>(component: component)
        
        return self.modifier(modifier)
    }
}

//MARK: Component
public struct NavigationRouteComponentModifier<Component: GraniteComponent, Payload: GranitePayload>: ViewModifier {
    
    //    var routePayload: RoutePayload<Payload>
    @State var isActive: Bool = false
    @State fileprivate var screen: NavigationPassthroughComponent<Component, Payload>.Screen<Component, Payload>
    
    init(@ViewBuilder component: @escaping (() -> Component), payload: Payload? = nil) {
        self._screen = .init(initialValue: .init(component, payload))
        //        routePayload = .init(payload)
        //        isActive = payload != nil
    }
    
    public func body(content: Content) -> some View {
        #if os(iOS)
        NavigationLink(isActive: $isActive) {
            if isActive {
                NavigationPassthroughComponent(isActive: $isActive,
                                      screen: screen)
            } else {
                EmptyView()
                    .onAppear {
                        self.screen.clean()
                    }
            }
        } label: {
            content
                .onTapGesture {
                    isActive = true
                }
        }.isDetailLink(false)//TODO: should be customizable
        #else
        NavigationLink(isActive: $isActive) {
            if isActive {
                NavigationPassthroughComponent(isActive: $isActive,
                                      screen: screen)
            } else {
                EmptyView()
                    .onAppear {
                        self.screen.clean()
                    }
            }
        } label: {
            content
                .onTapGesture {
                    isActive = true
                    GraniteNavigationWindow.shared.addWindow(title: "") {
                        NavigationPassthroughComponent(isActive: $isActive,
                                                       screen: screen)
                    }
                }
        }
        #endif
    }
}

//MARK: View
public struct NavigationRouteViewModifier<Component: View>: ViewModifier {
    
    //    var routePayload: RoutePayload<Payload>
    @State var isActive: Bool = false
    @State fileprivate var screen: NavigationPassthroughView<Component>.Screen<Component>
    
    init(@ViewBuilder component: @escaping (() -> Component)) {
        self._screen = .init(initialValue: .init(component))
        //        routePayload = .init(payload)
        //        isActive = payload != nil
    }
    
    public func body(content: Content) -> some View {
        //TODO: onPush fires after onAppear. Should be before
        #if os(iOS)
        NavigationLink(isActive: $isActive) {
            if isActive {
                NavigationPassthroughView(isActive: $isActive,
                                          screen: screen)
            } else {
                EmptyView()
                    .onAppear {
                        self.screen.clean()
                    }
            }
        } label: {
            content
                .onTapGesture {
                    isActive = true
                }
        }.isDetailLink(false)//TODO: should be customizable
        #else
        content
            .onTapGesture {
                isActive = true
                GraniteNavigationWindow.shared.addWindow(title: "") {
                    NavigationPassthroughView(isActive: $isActive,
                                              screen: screen)
                }
            }
        #endif
    }
}
