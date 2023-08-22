//
//  GraniteNavigation.Style.swift
//  
//
//  Created by PEXAVC on 1/25/23.
//

import Foundation
import SwiftUI

//MARK: Environment & Style
public struct GraniteNavigationStyle {
    public enum LeadingButtonKind {
        case close
        case back
        case customSystem(String)
        case custom(String)
        case customView
    }
    
    public struct BarStyle {
        public let edges: EdgeInsets
        public let height: CGFloat
        
        public init(edges: EdgeInsets = .init(top: 4,
                                              leading: 16,
                                              bottom: 4,
                                              trailing: 16),
                    height: CGFloat = 48) {
            self.edges = edges
            self.height = height
        }
    }
    
    let title: String
    let leadingButtonImageName: String
    let leadingButtonKind: LeadingButtonKind
    let backgroundColor: Color
    let barStyle: BarStyle
    let leadingItem: AnyView
    
    public init(title: String = "",
                leadingButtonKind: LeadingButtonKind = .back,
                backgroundColor: Color = .black,
                barStyle: BarStyle = .init(),
                @ViewBuilder leadingItem: @escaping () -> some View) {
        
        switch leadingButtonKind {
        case .close, .customView:
            leadingButtonImageName = "xmark"
        case .back:
            leadingButtonImageName = "chevron.backward"
        case .customSystem(let name),
                .custom(let name):
            leadingButtonImageName = name
        }
        self.title = title
        self.leadingButtonKind = leadingButtonKind
        self.backgroundColor = backgroundColor
        self.barStyle = barStyle
        self.leadingItem = AnyView(leadingItem())
    }
    
    public init(leadingButtonKind: LeadingButtonKind = .back,
                backgroundColor: Color = .black,
                barStyle: BarStyle = .init()) {
        
        switch leadingButtonKind {
        case .close, .customView:
            leadingButtonImageName = "xmark"
        case .back:
            leadingButtonImageName = "chevron.backward"
        case .customSystem(let name),
                .custom(let name):
            leadingButtonImageName = name
        }
        self.title = ""
        self.leadingButtonKind = leadingButtonKind
        self.backgroundColor = backgroundColor
        self.barStyle = barStyle
        self.leadingItem = AnyView(EmptyView())
    }
    
    public init(title: String,
                leadingButtonKind: LeadingButtonKind = .back,
                backgroundColor: Color = .black,
                barStyle: BarStyle = .init()) {
        
        switch leadingButtonKind {
        case .close, .customView:
            leadingButtonImageName = "xmark"
        case .back:
            leadingButtonImageName = "chevron.backward"
        case .customSystem(let name),
                .custom(let name):
            leadingButtonImageName = name
        }
        self.title = title
        self.leadingButtonKind = leadingButtonKind
        self.backgroundColor = backgroundColor
        self.barStyle = barStyle
        self.leadingItem = AnyView(EmptyView())
    }
}

private struct GraniteNavigationStyleKey: EnvironmentKey {
    static let defaultValue: GraniteNavigationStyle = .init() { }
}

extension EnvironmentValues {
    var graniteNavigationStyle: GraniteNavigationStyle {
        get { self[GraniteNavigationStyleKey.self] }
        set { self[GraniteNavigationStyleKey.self] = newValue }
    }
}

public struct GraniteNavigationDestinationStyle {
    var trailingItem: AnyView
    var fullWidth: Bool
    
    public init<Content: View>(fullWidth: Bool = false,
                               @ViewBuilder _ content: () -> Content = { EmptyView() }) {
        self.fullWidth = fullWidth
        self.trailingItem = AnyView(content())
    }
}

private struct GraniteNavigationDestinationStyleKey: EnvironmentKey {
    static let defaultValue: GraniteNavigationDestinationStyle = .init()
}

public extension EnvironmentValues {
    var graniteNavigationDestinationStyle: GraniteNavigationDestinationStyle {
        get { self[GraniteNavigationDestinationStyleKey.self] }
        set { self[GraniteNavigationDestinationStyleKey.self] = newValue }
    }
}

public extension View {
    func graniteDestinationTrailingView<Content: View>(fullWidth: Bool = false, @ViewBuilder _ content: () -> Content) -> some View {
        
        self
            .environment(\.graniteNavigationDestinationStyle,
                          .init(fullWidth: fullWidth, content))
    }
    
    func graniteDestinationTrailingViewIf<Content: View>(_ condition: Bool, fullWidth: Bool = false, @ViewBuilder _ content: () -> Content) -> some View {
        
        Group {
            if condition {
                self
                    .environment(\.graniteNavigationDestinationStyle,
                                  .init(fullWidth: fullWidth, content))
            } else {
                self
            }
        }
    }
}
