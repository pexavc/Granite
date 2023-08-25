//
//  GraniteNavigation.swift
//
//
//  Created by PEXAVC on 2/26/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI


//MARK: GraniteNavigation
//Main stack
public final class GraniteNavigation: ObservableObject {
    
    public struct Router {
        public let id: String
        public init(id: String) {
            self.id = id
        }
        
        public var navigation: GraniteNavigation {
            GraniteNavigation.router(for: id)
        }
        
        public func push<C: View>(@ViewBuilder _ content: @escaping () -> C) {
            self.navigation.push(content)
        }
        
        public func push<C: GraniteNavigationDestination>(@ViewBuilder _ content: @escaping () -> C) {
            self.navigation.push(content)
        }
        
        public func pop() {
            self.navigation.pop()
        }
    }
    public var asRouter: Router {
        .init(id: self.id)
    }
    
    func address(o: UnsafePointer<Void>) -> Int {
        return unsafeBitCast(o, to: Int.self)
    }

    func addressHeap<T: AnyObject>(o: T) -> Int {
        return unsafeBitCast(o, to: Int.self)
    }
    
    public static var initialValue: GraniteNavigation {
        GraniteNavigation.main
    }
    
    var id: String
    
    public static func router(for key: String) -> GraniteNavigation {
        //TODO: Wont work on tablet
        .main.child(key) ?? .main
    }
    
    static var mainSet: Bool = false
    public static var main: GraniteNavigation = .init(isMain: true)
    private var children: [String : GraniteNavigation] = [:]
    
    var stackCount: Int {
        children.count
    }
    
    internal var isActive = [String : Bool]()
    
    let isMain: Bool
    public init(isMain: Bool) {
        let key: String
        if isMain {
            key = "granite.app.main.router"
            GraniteNavigation.mainSet = true
        } else {
            key = "granite.app.main.router.child_\(GraniteNavigation.main.stackCount)"
        }
        self.id = key
        self.isMain = isMain
        
        if !isMain {
            GraniteNavigation.main.addChild(key, navigation: self)
        }
    }
    
    var paths: [String: () -> AnyView] = [:]
    var stack: [String] = []
    
    var level: Int {
        stack.count
    }
    
    func addChild(_ key: String, navigation: GraniteNavigation) {
        children[key] = navigation
    }
    
    @discardableResult
    func removeChild(_ key: String) -> GraniteNavigation? {
        let navigation = children[key]
        children[key] = nil
        return navigation
    }
    
    func child(_ key: String) -> GraniteNavigation? {
        children[key]
    }
    
    //TODO: remove GranitePayload requirement
    @discardableResult
    func set<Component : GraniteComponent>(destinationStyle: GraniteNavigationDestinationStyle = .init(),
                                           @ViewBuilder _ component: @escaping (() -> Component)) -> String {
        
        let screen = NavigationPassthroughComponent<Component, EmptyGranitePayload>.Screen<Component, EmptyGranitePayload>.init(component)
        let addr = NSString(format: "%p", addressHeap(o: screen)) as String
        
        paths[addr] = { AnyView(NavigationPassthroughComponent<Component,
                                EmptyGranitePayload>(screen: screen)
            .environment(\.graniteNavigationDestinationStyle, destinationStyle)) }
        
        isActive[addr] = false
        return addr
    }
    
    func push(_ addr: String,
              window: GraniteRouteWindowProperties? = nil) {
        
        GraniteLog("nav stack pushing into: \(self.id)")
        
        
        #if os(macOS)
        if let window {
            if let path = paths[addr] {
                GraniteNavigationWindow
                    .shared
                    .addWindow(props: window) {
                        path()
                            .environment(\.graniteNavigationWindowDestinationStyle, .newWindow)
                            .graniteNavigation(backgroundColor: Color.clear)
                            .frame(minWidth: window.style.minSize.width,
                                   minHeight: window.style.minSize.height)
                    }
                
                isActive[addr] = nil
                paths[addr] = nil
            }
        } else {
            isActive[addr] = true
            stack.append(addr)
            self.objectWillChange.send()
        }
        #else
        isActive[addr] = true
        stack.append(addr)
        self.objectWillChange.send()
        #endif
    }
    
    func pop() {
        guard let last = stack.last else { return }
        isActive[last] = false
        stack.removeLast()
        
        #if os(iOS)
        self.objectWillChange.send()
        #endif
    }
    
    func releaseStack() {
        guard self.isMain == false else { return }
        DispatchQueue.main.async { [weak self] in
            self?.stack.removeAll()
            self?.paths.removeAll()
            self?.isActive.removeAll()
            
            if let id = self?.id {
                GraniteNavigation.main.removeChild(id)
                GraniteLog("Navigation Stack Released", level: .debug)
            }
        }
    }
}

extension View {
    public func graniteNavigation(backgroundColor: Color = .black,
                                  disable: Bool = false) -> some View {
        
        self.initUINavigation(backgroundColor)
        
        return self.initNavigationView(disable: disable,
                                       style: .init(backgroundColor: backgroundColor))
    }
    
    public func graniteNavigation(backgroundColor: Color = .black,
                                  disable: Bool = false,
                                  @ViewBuilder leadingItem: @escaping () -> some View) -> some View {
        
        self.initUINavigation(backgroundColor)
        
        return self.initNavigationView(disable: disable,
                                       style: .init(leadingButtonKind: .customView,
                                                    backgroundColor: backgroundColor,
                                                    leadingItem: leadingItem))
    }
    
    private func initUINavigation(_ backgroundColor: Color) {
        #if os(iOS)
        //        UINavigationBar.appearance().isUserInteractionEnabled = false
        UINavigationBar.appearance().backgroundColor = UIColor(backgroundColor)
        //        UINavigationBar.appearance().barTintColor = .clear
        //        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        //        UINavigationBar.appearance().tintColor = .clear
        //        UINavigationBar.appearance().isOpaque = true

        if #available(iOS 15, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.shadowColor = .clear
            appearance.shadowImage = UIImage()
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.backgroundColor = UIColor(backgroundColor)
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
        #endif
    }
    
    private func initNavigationView(disable: Bool,
                                    disableiOS16: Bool = true,
                                    style: GraniteNavigationStyle) -> some View {
        Group {
            if disable {
                self
                    .environment(\.graniteNavigationStyle, style)
            } else {
                if !disableiOS16,
                   #available(macOS 13.0, iOS 16.0, *) {
                    NavigationStack {//WIP
                        ZStack(alignment: .top) {
                            style.backgroundColor
                                .ignoresSafeArea()
                                .frame(maxWidth: .infinity,
                                       maxHeight: .infinity)
                            self
                                .background(style.backgroundColor)
                        }
                    }
                    .environment(\.graniteNavigationStyle, style)
                } else {
                    GraniteNavigationView {
                        self
                    }
                    .environment(\.graniteNavigationStyle, style)
                }
            }
        }
    }
    
    public func graniteNavigationDestination(title: LocalizedStringKey = .init(""),
                                             font: Font = .headline) -> some View {
        return self.modifier(NavigationDestionationViewModifier<EmptyView>(title: title, font: font, trailingItems: nil))
    }
    
    public func graniteNavigationDestination(title: LocalizedStringKey = .init(""),
                                             font: Font = .headline,
                                             @ViewBuilder trailingItems: @escaping () -> some View) -> some View {
        return self.modifier(NavigationDestionationViewModifier(title: title, font: font, trailingItems: trailingItems))
    }
    
    public func graniteNavigationDestinationIf(_ condition: Bool,
                                               title: LocalizedStringKey = .init(""),
                                             font: Font = .headline,
                                             @ViewBuilder trailingItems: @escaping () -> some View) -> some View {
        Group {
            if condition {
                self.modifier(NavigationDestionationViewModifier(title: title, font: font, trailingItems: trailingItems))
            } else {
                self.modifier(NavigationDestionationViewModifier<EmptyView>(title: title, font: font, trailingItems: nil))
            }
        }
    }
}

//MARK: Destination
public struct NavigationDestionationViewModifier<TrailingContent: View>: ViewModifier {
    
    @Environment(\.graniteNavigationStyle) var style
    
    var title: LocalizedStringKey
    var font: Font
    let trailingItems: (() -> TrailingContent)?
    
    init(title: LocalizedStringKey,
         font: Font,
         trailingItems: (() -> TrailingContent)?) {
        self.title = title
        self.font = font
        self.trailingItems = trailingItems
    }
    
    var trailingView : some View {
        Group {
            if let trailingItems {
                trailingItems()
            } else {
                EmptyView()
            }
        }
    }
    
    var titleView: Text {
        Text(title)
            .font(font)
    }
    
    public func body(content: Content) -> some View {
            
        #if os(iOS)
        ZStack {
            style.backgroundColor
                .ignoresSafeArea()
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity)
            
            content
                .navigationBarBackButtonHidden(true)
                .navigationBarItems(trailing: trailingView)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack {
                            titleView
                        }
                    }
                }
        }
        #else
        VStack(spacing: 0) {
            if self.trailingItems != nil {
                HStack {
                    trailingView
                }
                .frame(height: 24)
                .padding(.horizontal, 16)
            }
            
            content
                .ignoresSafeArea()
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity)
        }
        #endif
    }
}
