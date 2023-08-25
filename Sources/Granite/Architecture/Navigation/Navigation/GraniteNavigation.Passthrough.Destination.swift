//
//  File.swift
//  
//
//  Created by Ritesh Pakala on 8/25/23.
//

import Foundation
import SwiftUI

extension View {
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
        VStack(spacing: 0) {
            if self.trailingItems != nil {
                HStack {
                    Spacer()
                    trailingView
                        .frame(height: style.barStyle.height)
                        .padding(style.barStyle.edges)
                        .background(style.backgroundColor)
                }
            }
            content
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity)
        }
    }
}
