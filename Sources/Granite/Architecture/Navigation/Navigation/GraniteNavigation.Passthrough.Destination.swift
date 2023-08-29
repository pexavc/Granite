//
//  File.swift
//  
//
//  Created by PEXAVC on 8/25/23.
//

import Foundation
import SwiftUI

extension View {
    public func graniteNavigationDestination(title: LocalizedStringKey = .init(""),
                                             font: Font = .headline,
                                             fullWidth: Bool = false) -> some View {
        return self.modifier(NavigationDestionationViewModifier<EmptyView>(title: title, font: font, fullWidth: fullWidth, trailingItems: nil))
    }
    
    public func graniteNavigationDestination(title: LocalizedStringKey = .init(""),
                                             font: Font = .headline,
                                             fullWidth: Bool = false,
                                             @ViewBuilder trailingItems: @escaping () -> some View) -> some View {
        return self.modifier(NavigationDestionationViewModifier(title: title, font: font, fullWidth: fullWidth, trailingItems: trailingItems))
    }
    
    public func graniteNavigationDestinationIf(_ condition: Bool,
                                               title: LocalizedStringKey = .init(""),
                                               font: Font = .headline,
                                               fullWidth: Bool = false,
                                               @ViewBuilder trailingItems: @escaping () -> some View) -> some View {
        Group {
            if condition {
                self.modifier(NavigationDestionationViewModifier(title: title, font: font, fullWidth: fullWidth, trailingItems: trailingItems))
            } else {
                self.modifier(NavigationDestionationViewModifier<EmptyView>(title: title, font: font, fullWidth: fullWidth, trailingItems: nil))
            }
        }
    }
}

//MARK: Destination
public struct NavigationDestionationViewModifier<TrailingContent: View>: ViewModifier {
    
    @Environment(\.graniteNavigationStyle) var style
    
    var title: LocalizedStringKey
    var font: Font
    let fullWidth: Bool
    let trailingItems: (() -> TrailingContent)?
    
    init(title: LocalizedStringKey,
         font: Font,
         fullWidth: Bool = false,
         trailingItems: (() -> TrailingContent)?) {
        self.title = title
        self.font = font
        self.fullWidth = fullWidth
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
        VStack(spacing: 0) {
            if self.trailingItems != nil {
                HStack {
                    if !fullWidth {
                        Spacer()
                    }
                    trailingView
                        .frame(height: style.barStyle.height)
                        .padding(style.barStyle.edges)
                        //.background(style.backgroundColor)
                }
            }
            content
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity)
        }
    }
}
