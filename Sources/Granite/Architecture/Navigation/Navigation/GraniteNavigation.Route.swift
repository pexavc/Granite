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
    public func route<C: GraniteComponent, O: GranitePayload>(title: String = "",
                                                              window: GraniteRouteWindowProperties = .init(),
                                                              payload: O? = nil,
                                                              @ViewBuilder component : @escaping (() -> C)) -> some View {
        let memadd = GraniteNavigation.routes.setComponent(component)
        
        return self
            .onTapGesture {
                GraniteHaptic.light.invoke()
                GraniteNavigation.routes.push(memadd)
            }
    }
    
    
    public func route<C: View>(title: String = "",
                                window: GraniteRouteWindowProperties = .init(),
                                @ViewBuilder component : @escaping (() -> C)) -> some View {
        
        let memadd = GraniteNavigation.routes.set(component)
        
        return self
            .onTapGesture {
                GraniteHaptic.light.invoke()
                GraniteNavigation.routes.push(memadd)
            }
    }
    
    public func routeIf<C: GraniteComponent>(_ condition: Bool,
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
    
    public func routeTarget<C: View>(_ condition: Binding<Bool>,
                                     title: String = "",
                                     window: GraniteRouteWindowProperties = .resizable(size: GraniteNavigationWindowStyle.defaultSize),
                                     @ViewBuilder component : @escaping (() -> C)) -> some View {
        let memadd = GraniteNavigation.routes.set(component)
        return Group {
            self
                .onChange(of: condition.wrappedValue) { value in
                    guard value else { return }
                    condition.wrappedValue = false
                    GraniteNavigation.routes.push(memadd)
                }
        }
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
                NavigationPassthroughComponent(screen: screen)
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
                NavigationPassthroughView(screen: screen)
            } label: {
                content
            }
            .isDetailLink(false)//TODO: should be customizable
        } else {
            NavigationLink(isActive: $isActive) {
                if isActive {
                    NavigationPassthroughView(screen: screen)
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

public struct GraniteRouteWindowProperties {
    public let title: String
    public let style: GraniteNavigationWindowStyle
    
    public init(title: String = "", style: GraniteNavigationWindowStyle = .default) {
        self.title = title
        self.style = style
    }
    
    public static func resizable(size: CGSize) -> GraniteRouteWindowProperties {
        return .init(style: .init(size: size, styleMask: .resizable))
    }
    
    public static func resizable(_ width: CGFloat, _ height: CGFloat) -> GraniteRouteWindowProperties {
        return .init(style: .init(size: .init(width: width, height: height), styleMask: .resizable))
    }
}
