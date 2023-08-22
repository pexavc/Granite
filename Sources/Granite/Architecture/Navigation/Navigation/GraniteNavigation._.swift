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
        .main.child(key) ?? .main
    }
    
    public static var current: GraniteNavigation {
        .init()
    }
    
    static var mainSet: Bool = false
    static var main: GraniteNavigation = .init()
    private var children: [String : GraniteNavigation] = [:]
    
    var stackCount: Int {
        children.count
    }
    
    internal var isActive = [String : Bool]()
    
    let isMain: Bool
    public init(_ routerKey: String? = nil) {
        id = routerKey ?? "granite.app.main.router"
        isMain = routerKey == nil
        guard GraniteNavigation.mainSet == false else {
            GraniteNavigation.main.addChild(id, navigation: self)
            return
        }
        GraniteNavigation.mainSet = routerKey == nil
    }
    
    var paths: [String: AnyView] = [:]
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
        
        paths[addr] = AnyView(NavigationPassthroughComponent<Component,
                              EmptyGranitePayload>(screen: screen)
            .environment(\.graniteNavigationDestinationStyle, destinationStyle))
        
        isActive[addr] = false
        return addr
    }
    
    func push(_ addr: String) {
        
        isActive[addr] = true
        stack.append(addr)
        
        #if os(macOS)
        if let path = paths[addr] {
            GraniteNavigationWindow.shared.addWindow(title: window.title, style: window.style) {
                path
                    .environment(\.graniteNavigationPassKey, isActive[addr])
            }
        }
        #else
        self.objectWillChange.send()
        #endif
    }
    
    func pop() {
        guard let last = stack.last else { return }
        isActive[last] = false
        stack.removeLast()
        
        if stack.isEmpty {
            releaseStack()
        }
        
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
                            
                            #if os(iOS)
                            self
                                .background(style.backgroundColor)
                            #else
                            self
                                .background(style.backgroundColor)
                            #endif
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
