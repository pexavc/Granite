//
//  GraniteNavigation.swift
//
//
//  Created by PEXAVC on 2/26/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI

public final class GraniteNavigation: SharableObject {
    func address(o: UnsafePointer<Void>) -> Int {
        return unsafeBitCast(o, to: Int.self)
    }

    func addressHeap<T: AnyObject>(o: T) -> Int {
        return unsafeBitCast(o, to: Int.self)
    }
    
    public static var initialValue: GraniteNavigation {
        GraniteNavigation.routes
    }
    
    var id: String {
        "granite.app.main.router"
    }
    
    public static var routes: GraniteNavigation = .init()
    
    internal var isActive = [String : Bool]()
    
    private init() {
        
    }
    
    var paths: [String: AnyView] = [:]
    @Published var stack: [String] = []
    
    var level: Int {
        stack.count
    }
    
    @discardableResult
    func setComponent<Component : GraniteComponent>(@ViewBuilder _ component: @escaping (() -> Component)) -> String {
        var screen = NavigationPassthroughComponent<Component, EmptyGranitePayload>.Screen<Component, EmptyGranitePayload>.init(component)
        let addr = NSString(format: "%p", address(o: &screen)) as String
        paths[addr] = AnyView(NavigationPassthroughComponent<Component, EmptyGranitePayload>(screen: screen))
        isActive[addr] = false
        return addr
    }
    
    @discardableResult
    func set<Component : View>(@ViewBuilder _ component: @escaping (() -> Component)) -> String {
        var screen = NavigationPassthroughView<Component>.Screen<Component>.init(component)
        let addr = NSString(format: "%p", address(o: &screen)) as String
        paths[addr] = AnyView(NavigationPassthroughView<Component>(screen: screen))
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
        #endif
    }
    
    func pop() {
        guard let last = stack.last else { return }
//        paths[last] = nil
        isActive[last] = false
        stack.removeLast()
//        isActive[last] = nil
        
    }
}

public extension GraniteNavigation {
    @MainActor
    static func push<Component: View>(@ViewBuilder _ component: @escaping (() -> Component)) {
        GraniteNavigation.routes.push(GraniteNavigation.routes.set(component))
    }
}


struct GraniteRouter: View {
    @SharedObject("granite.app.main.router") var routes: GraniteNavigation
    
    var keys: [String] {
        routes.isActive.keys.map { "\($0)" }
    }
    
    func isActive(_ id: String) -> Binding<Bool> {
        .init(get: {
            GraniteLog("GranitePath isActive detected \(keys.count)", level: .debug)
            return routes.isActive[id] == true
        }, set: { state in
            routes.isActive[id] = state
        })
    }
    
    var body: some View {
        Group {
            #if os(iOS)
            ForEach(Array(routes.isActive.keys), id: \.self) { id in
                if let path = routes.paths[id] {
                    path
                    .environment(\.graniteNavigationPassKey,
                                  isActive(id).wrappedValue)
                }
                
//                NavigationLink(isActive: isActive(id)) {
//                    if let path = routes.paths[id] {
//                        path
//                            .environment(\.graniteNavigationPassKey, isActive(id).wrappedValue)
//                    }
//                } label: {
//                    EmptyView()
//                }
//                .isDetailLink(false)
            }
            
            Text("Level: \(routes.level), last addr: \(routes.stack.last ?? "")")
            #else
            EmptyView()
            #endif
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
                    NavigationStack {
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
                    NavigationView {
                        #if os(iOS)
                        ZStack(alignment: .top) {
                            
                            style.backgroundColor
                                .ignoresSafeArea()
                                .frame(maxWidth: .infinity,
                                       maxHeight: .infinity)
                            self
                                .background(style.backgroundColor)
                                .navigationViewStyle(.stack)
                            
                            GraniteRouter()
                        }
                        .navigationBarTitle("", displayMode: .inline)
                        .navigationBarHidden(true)
                        #else
                        ZStack(alignment: .top) {
                            style.backgroundColor
                                .ignoresSafeArea()
                                .frame(maxWidth: .infinity,
                                       maxHeight: .infinity)
                            self
                                .background(style.backgroundColor)
                        }
                        #endif
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
