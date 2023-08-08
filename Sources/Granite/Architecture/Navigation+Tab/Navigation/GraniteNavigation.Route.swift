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

extension View {
    public func route<C: GraniteComponent, O: GranitePayload>(title: String = "",
                                                              style: GraniteNavigationWindowStyle = .default,
                                                              payload: O? = nil,
                                                              @ViewBuilder component : @escaping (() -> C)) -> some View {
        let modifier = NavigationRouteComponentModifier<C, O>(title: title, style: style, component: component, payload: payload)
        
        return self.modifier(modifier)
    }
    
    public func routeIf<C: View>(_ condition: Bool,
                                 title: String = "",
                                 style: GraniteNavigationWindowStyle = .default,
                                 @ViewBuilder component : @escaping (() -> C)) -> some View {
        Group {
            if condition {
                let modifier = NavigationRouteViewModifier<C>(title: title, style: style, component: component)
                
                self.modifier(modifier)
            } else {
                self
            }
        }
    }
    
    public func routeTarget<C: View>(_ condition: Binding<Bool>,
                                 title: String = "",
                                 style: GraniteNavigationWindowStyle = .default,
                                 @ViewBuilder component : @escaping (() -> C)) -> some View {
        let modifier = NavigationRouteViewModifier<C>(isTargetActive: condition, useTarget: true, title: title, style: style, component: component)
        
        return self.modifier(modifier)
    }
    
    public func route<C: View>(title: String = "",
                               window: GraniteRoute<AnyView>.WindowProperties = .init(),
                               @ViewBuilder component : @escaping (() -> C)) -> some View {
        let modifier = NavigationRouteViewModifier<C>(title: title, style: window.style, component: component)
        
        return self.modifier(modifier)
    }
}

//MARK: Component
public struct NavigationRouteComponentModifier<Component: GraniteComponent, Payload: GranitePayload>: ViewModifier {
    #if os(iOS)
    private func graniteHapticFeedbackDefaultSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    private func graniteHapticFeedbackImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    #endif
    //    var routePayload: RoutePayload<Payload>
    @State var isActive: Bool = false
    @State fileprivate var screen: NavigationPassthroughComponent<Component, Payload>.Screen<Component, Payload>
    
    let title: String
    let style: GraniteNavigationWindowStyle
    
    init(title: String = "",
         style: GraniteNavigationWindowStyle,
         @ViewBuilder component: @escaping (() -> Component), payload: Payload? = nil) {
        self.title = title
        self.style = style
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
                    graniteHapticFeedbackImpact(style: .light)
                    isActive = true
                }
        }
        .isDetailLink(false)//TODO: should be customizable
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
                    GraniteNavigationWindow.shared.addWindow(title: self.title) {
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
    #if os(iOS)
    private func graniteHapticFeedbackDefaultSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    private func graniteHapticFeedbackImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    #endif
    //    var routePayload: RoutePayload<Payload>
    @Binding var isTargetActive: Bool
    @State var isActive: Bool = false
    @State fileprivate var screen: NavigationPassthroughView<Component>.Screen<Component>
    var useTarget: Bool
    let title: String
    let style: GraniteNavigationWindowStyle
    
    init(isTargetActive: Binding<Bool> = .constant(false),
         useTarget: Bool = false,
         title: String = "",
         style: GraniteNavigationWindowStyle,
         @ViewBuilder component: @escaping (() -> Component)) {
        self._isTargetActive = isTargetActive
        self.useTarget = useTarget
        self.title = title
        self.style = style
        self._screen = .init(initialValue: .init(component))
        //        routePayload = .init(payload)
        //        isActive = payload != nil
    }
    
    public func body(content: Content) -> some View {
        #if os(iOS)
        if useTarget {
            NavigationLink(isActive: $isTargetActive) {
                NavigationPassthroughView(isActive: $isTargetActive,
                                          screen: screen)
            } label: {
                content
            }
            .isDetailLink(false)//TODO: should be customizable
        } else {
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
                        graniteHapticFeedbackImpact(style: .light)
                        isActive = true
                    }
            }
            .isDetailLink(false)//TODO: should be customizable
        }
        
        #else
        if useTarget {
            content
                .onChange(of: isTargetActive) { value in
                    guard isTargetActive else { return }
                    GraniteNavigationWindow.shared.addWindow(title: self.title, style: style) {
                        NavigationPassthroughView(isActive: $isTargetActive,
                                                  screen: screen)
                    }
                    isTargetActive = false
                }
        } else {
            
            content
                .onTapGesture {
                    isActive = true
                    GraniteNavigationWindow.shared.addWindow(title: self.title, style: style) {
                        NavigationPassthroughView(isActive: $isActive,
                                                  screen: screen)
                    }
                }
        }
        #endif
    }
}

public struct GraniteRoute<Component: View>: View {
    public struct WindowProperties {
        public let title: String
        public let style: GraniteNavigationWindowStyle
        
        public init(title: String = "", style: GraniteNavigationWindowStyle = .default) {
            self.title = title
            self.style = style
        }
        
        public static func resizable(size: CGSize) -> WindowProperties {
            return .init(style: .init(size: size, styleMask: .resizable))
        }
        
        public static func resizable(_ width: CGFloat, _ height: CGFloat) -> WindowProperties {
            return .init(style: .init(size: .init(width: width, height: height), styleMask: .resizable))
        }
    }
    
    
    @Binding var isActive: Bool
    @State fileprivate var screen: NavigationPassthroughView<Component>.Screen<Component>
    let window: WindowProperties
    public init(_ condition: Binding<Bool>,
                window: WindowProperties = .init(),
                @ViewBuilder component: @escaping (() -> Component)){
        self._isActive = condition
        self._screen = .init(initialValue: .init(component))
        self.window = window
    }
    
    public var body: some View {
        #if os(iOS)
        Button {
        
        } label : {
            NavigationLink(isActive: $isActive) {
                NavigationPassthroughView(isActive: $isActive,
                                          screen: screen)
            } label: {
                Color.clear
                    .frame(width: 0, height: 0)
                    .onAppear {
                        //GraniteLog("Cleaned route screen", level: .debug)
                        self.screen.clean()
                    }
            }
            .isDetailLink(false)
        }.buttonStyle(.plain)
        #else
        EmptyView()
        .onChange(of: isActive) { value in
            guard value else { return }
            GraniteNavigationWindow.shared.addWindow(title: window.title, style: window.style) {
                NavigationPassthroughView(isActive: $isActive,
                                          screen: screen)
            }
            isActive = false
        }
        #endif
    }
}
