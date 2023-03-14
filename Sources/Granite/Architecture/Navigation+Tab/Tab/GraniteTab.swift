//
//  GraniteTab.swift
//  
//
//  Created by PEXAVC on 1/17/23.
//

import Foundation
import SwiftUI

public struct GraniteTabStyle {
    let height: CGFloat
    let background: AnyView
    let paddingTabs: EdgeInsets
    let paddingIcons: EdgeInsets
    
    public init(height: CGFloat = 75,
                backgroundColor: Color = .black,
                paddingTabs: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0),
                paddingIcons: EdgeInsets = .init(top: 0, leading: 0, bottom: 16, trailing: 0),
                @ViewBuilder background: (() -> some View) = { EmptyView() }) {
        self.height = height
        self.paddingTabs = paddingTabs
        self.paddingIcons = paddingIcons
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
    
    public let component : AnyView
    public let content : AnyView
    
    public let id: String
    public let action: (() -> Void)?
    
    public init<Content: View, Component: GraniteComponent>(action: (() -> Void)? = nil,
                                                            @ViewBuilder component: @escaping (() -> Component),
                                                            @ViewBuilder icon: @escaping (() -> Content)) {
        let componentBuild = component()
        let iconBuild = icon()
        self.id = String(describing: iconBuild)
        self.action = action
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
    func graniteTabs(@GraniteTabBuilder tabs : @escaping () -> [GraniteTab]) -> some View {
        self.modifier(GraniteTabViewModifier(tabs: tabs))
    }
}

public struct GraniteTabViewModifier: ViewModifier {
    
    @Environment(\.graniteTabStyle) var style
    
    let tabs: [GraniteTab]
    @State var currentTab: Int = 0
    
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
                        }) {
                            tab.content
                        }
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
    
    public init(_ style: GraniteTabStyle = .init(),
                @GraniteTabBuilder tabs : @escaping () -> [GraniteTab]) {
        let tabList = tabs()
        self.style = style
        self.tabs = tabList
    }
    
    func indexOf(_ tab: GraniteTab) -> Int {
        tabs.firstIndex(of: tab) ?? 0
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            ZStack {
                ForEach(tabs) { tab in
                    tab
                        .component
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .opacity(indexOf(tab) == currentTab ? 1.0 : 0.0)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack {
                HStack {
                    ForEach(tabs) { tab in
                        Spacer()
                        Button(action: {
                            currentTab = indexOf(tab)
                        }) {
                            tab
                                .content
                                .environment(\.graniteTabSelected, currentTab == indexOf(tab))
                        }
                    }
                    Spacer()
                }
                .padding(.bottom, style.paddingIcons.bottom)
            }
            .frame(height: style.height)
            .frame(maxWidth: .infinity)
            .background(style.background)
        }
    }
    
}

extension View {
    public func graniteTabStyle(_ style: GraniteTabStyle = .init()) -> some View {
        self.environment(\.graniteTabStyle, style)
    }
}
