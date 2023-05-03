//
//  GraniteNavigation.swift
//
//
//  Created by PEXAVC on 2/26/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI

extension View {
    public func graniteNavigation(backgroundColor: Color = .black) -> some View {
        #if os(iOS)
        UINavigationBar.appearance().isUserInteractionEnabled = false
        UINavigationBar.appearance().backgroundColor = .clear
        UINavigationBar.appearance().barTintColor = .clear
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().tintColor = .clear
        #endif
        
        return NavigationView {
            ZStack(alignment: .top) {
                backgroundColor
                    .ignoresSafeArea()
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity)
                
                self
                    .background(backgroundColor)
            }
        }
        .environment(\.graniteNavigationStyle,
                      .init(backgroundColor: backgroundColor))
    }
    
    public func graniteNavigation(backgroundColor: Color = .black,
                                  @ViewBuilder leadingItem: @escaping () -> some View) -> some View {
        
        #if os(iOS)
        UINavigationBar.appearance().isUserInteractionEnabled = false
        UINavigationBar.appearance().backgroundColor = .clear
        UINavigationBar.appearance().barTintColor = .clear
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().tintColor = .clear
        #endif
        
        return NavigationView {
            #if os(iOS)
            ZStack(alignment: .top) {
                backgroundColor
                    .ignoresSafeArea()
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity)
                
                self
                    .background(backgroundColor)
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarHidden(true)
            #endif
        }
        .environment(\.graniteNavigationStyle,
                      .init(leadingButtonKind: .customView,
                            backgroundColor: backgroundColor,
                            leadingItem: leadingItem))
    }
    
    public func graniteNavigationDestination(title: LocalizedStringKey = .init(""),
                                             font: Font = .headline) -> some View {
        return self.modifier(NavigationDestionationViewModifier(title: title, font: font, trailingItems: {}))
    }
    
    public func graniteNavigationDestination(title: LocalizedStringKey = .init(""),
                                             font: Font = .headline,
                                             @ViewBuilder trailingItems: @escaping () -> some View) -> some View {
        return self.modifier(NavigationDestionationViewModifier(title: title, font: font, trailingItems: trailingItems))
    }
}

//MARK: Destination
public struct NavigationDestionationViewModifier<TrailingContent: View>: ViewModifier {
    
    @Environment(\.graniteNavigationStyle) var style
    
    var title: LocalizedStringKey
    var font: Font
    let trailingItems: () -> TrailingContent
    
    init(title: LocalizedStringKey,
         font: Font,
         @ViewBuilder trailingItems: @escaping () -> TrailingContent) {
        self.title = title
        self.font = font
        self.trailingItems = trailingItems
    }
    
    var trailingView : some View {
        trailingItems()
    }
    
    var titleView: Text {
        Text(title)
            .font(font)
    }
    
    public func body(content: Content) -> some View {
        ZStack {
            style.backgroundColor
                .ignoresSafeArea()
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity)
            
            #if os(iOS)
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
            #endif
        }
    }
}
