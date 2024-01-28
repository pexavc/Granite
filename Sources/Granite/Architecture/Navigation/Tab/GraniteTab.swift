//
//  GraniteTab.swift
//  Granite
//
//  Created by Ritesh Pakala on 1/17/23.
//  Copyright © 2024 Robin Health Inc. All rights reserved.
//

import Foundation
import SwiftUI

public struct GraniteTabStyle {
    let height: CGFloat
    let background: AnyView
    let noDivider: Bool
    let paddingTabs: EdgeInsets
    let paddingIcons: EdgeInsets
    let paddingContainer: EdgeInsets
    let landscape: Bool
    let enableHaptic: Bool
    
    public init(height: CGFloat = 75,
                backgroundColor: Color = .black,
                paddingTabs: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0),
                paddingIcons: EdgeInsets = .init(top: 0, leading: 0, bottom: 16, trailing: 0),
                paddingContainer: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0),
                landscape: Bool = false,
                enableHaptic: Bool = false,
                noDivider: Bool = false,
                @ViewBuilder background: (() -> some View) = { EmptyView() }) {
        self.height = height
        self.paddingTabs = paddingTabs
        self.paddingIcons = paddingIcons
        self.paddingContainer = paddingContainer
        self.landscape = landscape
        self.enableHaptic = enableHaptic
        self.noDivider = noDivider
        self.background = AnyView(background())
    }
}

private struct GraniteTabStyleKey: EnvironmentKey {
    static let defaultValue: GraniteTabStyle = .init() { }
}

extension EnvironmentValues {
    var graniteTabStyle: GraniteTabStyle {
        get { self[GraniteTabStyleKey.self] }
        set { self[GraniteTabStyleKey.self] = newValue }
    }
}

public struct GraniteTabSelectedKey: EnvironmentKey {
    public static let defaultValue: Bool? = nil
}

extension EnvironmentValues {
    public var graniteTabSelected: Bool? {
        get { self[GraniteTabSelectedKey.self] }
        set { self[GraniteTabSelectedKey.self] = newValue }
    }
}

public struct GraniteTab : Identifiable, Equatable {
    public static func == (lhs: GraniteTab, rhs: GraniteTab) -> Bool {
        lhs.id == rhs.id
    }
    
    
    public let ignoreEdges: Edge.Set
    public let component : AnyView
    public let content : AnyView
    public let split: Bool
    public let last : Bool
    
    public let id: String
    public let action: (() -> Void)?
    
    public init<Content: View, Component: GraniteComponent>(action: (() -> Void)? = nil,
                                                            ignoreEdges: Edge.Set = [],
                                                            split: Bool = false,
                                                            last: Bool = false,
                                                            @ViewBuilder component: @escaping (() -> Component),
                                                            @ViewBuilder icon: @escaping (() -> Content)) {
        let componentBuild = component()
        let iconBuild = icon()
        self.id = String(describing: componentBuild)
        self.action = action
        self.ignoreEdges = ignoreEdges
        self.split = split
        self.last = last
        self.component = AnyView(componentBuild)
        self.content = AnyView(iconBuild)
    }
}

public protocol GraniteTabGroup {
    
    var tabs : [GraniteTab] { get }
    
}

extension GraniteTab : GraniteTabGroup {
    
    public var tabs: [GraniteTab] {
        [self]
    }
    
}

extension Array: GraniteTabGroup where Element == GraniteTab {
    
    public var tabs: [GraniteTab] {
        self
    }
    
}

@resultBuilder public struct GraniteTabBuilder {
    
    public static func buildBlock() -> [GraniteTab] {
        []
    }
    
    public static func buildBlock(_ tab : GraniteTab) -> [GraniteTab] {
        [tab]
    }
    
    public static func buildBlock(_ tabs: GraniteTabGroup...) -> [GraniteTab] {
        tabs.flatMap { $0.tabs }
    }
    
    public static func buildEither(first tab: [GraniteTab]) -> [GraniteTab] {
        tab
    }
    
    public static func buildEither(second tab: [GraniteTab]) -> [GraniteTab] {
        tab
    }
    
    public static func buildOptional(_ tabs: [GraniteTabGroup]?) -> [GraniteTab] {
        tabs?.flatMap { $0.tabs } ?? []
    }
    
}

extension View {
    func GraniteTabs(@GraniteTabBuilder tabs : @escaping () -> [GraniteTab]) -> some View {
        self.modifier(GraniteTabViewModifier(tabs: tabs))
    }
}

public struct GraniteTabViewModifier: ViewModifier {
    
    @Environment(\.graniteTabStyle) var style
    
    let tabs: [GraniteTab]
    @State var currentTab: Int = 0
    
    #if os(iOS)
    let generator = UIImpactFeedbackGenerator(style: .light)
    #endif
    
    init(@GraniteTabBuilder tabs : @escaping () -> [GraniteTab]) {
        let tabList = tabs()
        self.tabs = tabList
    }
    
    func indexOf(_ tab: GraniteTab) -> Int {
        tabs.firstIndex(of: tab) ?? 0
    }
    
    public func body(content: Content) -> some View {
        VStack(spacing: 4) {
            ZStack {
                ForEach(tabs) { tab in
                    tab
                        .component
                        .opacity(indexOf(tab) == currentTab ? 1.0 : 0.0)
                }
            }
            
            VStack {
                HStack {
                    ForEach(tabs) { tab in
                        Spacer()
                        Button(action: {
                            currentTab = indexOf(tab)
                            
                            #if os(iOS)
                            generator.prepare()
                            generator.impactOccurred()
                            #endif
                            
                        }) {
                            tab.content
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    Spacer()
                }
                .padding(.bottom, 16)
            }
            .frame(height: 75)
            .frame(maxWidth: .infinity)
        }
    }
}

public struct GraniteTabView: View {
    let style: GraniteTabStyle
    
    let tabs: [GraniteTab]
    @State var currentTab: Int = 0
    
    #if os(iOS)
    let generator = UIImpactFeedbackGenerator(style: .light)
    #endif
    
    public init(_ style: GraniteTabStyle = .init(),
                currentTab: Int = 0,
                @GraniteTabBuilder tabs : @escaping () -> [GraniteTab]) {
        let tabList = tabs()
        self.style = style
        self.currentTab = currentTab
        self.tabs = tabList
    }
    
    func indexOf(_ tab: GraniteTab) -> Int {
        tabs.firstIndex(of: tab) ?? 0
    }
    
    public var body: some View {
        Group {
            if style.landscape {
                horizontalView
            } else {
                verticalView
            }
        }
    }
    
    public var horizontalView: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                ForEach(tabs) { tab in
                    if tab.split {
                        Spacer()
                    }
                    
                    Button(action: {
                        currentTab = indexOf(tab)
                        
                        guard style.enableHaptic else { return }
                        #if os(iOS)
                        generator.prepare()
                        generator.impactOccurred()
                        #endif
                    }) {
                        tab
                            .content
                            .environment(\.graniteTabSelected, currentTab == indexOf(tab))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.bottom, tab.last ? 0 : style.paddingIcons.bottom)
                }
            }
            .frame(width: style.height)
            .frame(maxHeight: .infinity)
            .padding(.top, style.paddingTabs.top)
            .padding(.bottom, style.paddingTabs.bottom)
            .background(style.background)
            
            if style.noDivider == false {
                Divider()
            }
            
            ZStack {
                ForEach(tabs) { tab in
                    tab
                        .component
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .opacity(indexOf(tab) == currentTab ? 1.0 : 0.0)
                        .environment(\.graniteTabSelected, currentTab == indexOf(tab))
                        .edgesIgnoringSafeArea(tab.ignoreEdges)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(style.paddingContainer)
    }
    
    public var verticalView: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(tabs) { tab in
                    tab
                        .component
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .opacity(indexOf(tab) == currentTab ? 1.0 : 0.0)
                        .environment(\.graniteTabSelected, currentTab == indexOf(tab))
                        .edgesIgnoringSafeArea(tab.ignoreEdges)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if style.noDivider == false {
                Divider()
            }
            
            VStack {
                HStack {
                    ForEach(tabs) { tab in
                        Spacer()
                        Button(action: {
                            currentTab = indexOf(tab)
                            
                            guard style.enableHaptic else { return }
                            #if os(iOS)
                            generator.prepare()
                            generator.impactOccurred()
                            #endif
                        }) {
                            tab
                                .content
                                .environment(\.graniteTabSelected, currentTab == indexOf(tab))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    Spacer()
                }
                .padding(.bottom, style.paddingIcons.bottom)
            }
            .frame(height: style.height)
            .frame(maxWidth: .infinity)
            .background(style.background)
            .padding(style.paddingTabs)
        }
        .padding(style.paddingContainer)
    }
}

extension View {
    public func graniteTabStyle(_ style: GraniteTabStyle = .init()) -> some View {
        self.environment(\.graniteTabStyle, style)
    }
}
