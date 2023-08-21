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
    
    let title: String
    let leadingButtonImageName: String
    let leadingButtonKind: LeadingButtonKind
    let backgroundColor: Color
    let leadingItem: AnyView
    
    public init(title: String = "",
                leadingButtonKind: LeadingButtonKind = .back,
                backgroundColor: Color = .black,
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
        self.leadingItem = AnyView(leadingItem())
    }
    
    public init(leadingButtonKind: LeadingButtonKind = .back,
                backgroundColor: Color = .black) {
        
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
        self.leadingItem = AnyView(EmptyView())
    }
    
    public init(title: String,
                leadingButtonKind: LeadingButtonKind = .back,
                backgroundColor: Color = .black) {
        
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
