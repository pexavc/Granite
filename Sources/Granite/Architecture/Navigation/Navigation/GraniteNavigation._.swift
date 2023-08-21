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
    public func graniteNavigation(backgroundColor: Color = .black, disable: Bool = false) -> some View {
        #if os(iOS)
        //UINavigationBar.appearance().isUserInteractionEnabled = false
        UINavigationBar.appearance().backgroundColor = .clear
        UINavigationBar.appearance().barTintColor = .clear
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().tintColor = .clear
        UINavigationBar.appearance().isOpaque = true
        
        if #available(iOS 15, *) {
            //TODO: customizable prop
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
        
        return Group {
            if disable {
                self
                    .environment(\.graniteNavigationStyle,
                                  .init(backgroundColor: backgroundColor))
            } else {
                if #available(macOS 13.0, iOS 16.0, *) {
                    NavigationStack {
                        ZStack(alignment: .top) {
                            backgroundColor
                                .ignoresSafeArea()
                                .frame(maxWidth: .infinity,
                                       maxHeight: .infinity)
                            
                            #if os(iOS)
                            self
                                .background(backgroundColor)
                            #else
                            self
                                .background(backgroundColor)
                            #endif
                        }
                    }
                    .environment(\.graniteNavigationStyle,
                                  .init(backgroundColor: backgroundColor))
                } else {
                    NavigationView {
                        ZStack(alignment: .top) {
                            backgroundColor
                                .ignoresSafeArea()
                                .frame(maxWidth: .infinity,
                                       maxHeight: .infinity)
                            
                            #if os(iOS)
                            self
                                .background(backgroundColor)
                                .navigationViewStyle(.stack)
                            #else
                            self
                                .background(backgroundColor)
                            #endif
                        }
                    }
                    .environment(\.graniteNavigationStyle,
                                  .init(backgroundColor: backgroundColor))
                }
            }
        }
    }
    
    public func graniteNavigation(backgroundColor: Color = .black,
                                  disable: Bool = false,
                                  @ViewBuilder leadingItem: @escaping () -> some View) -> some View {
        
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
        
        return Group {
            if disable {
                self
                    .environment(\.graniteNavigationStyle,
                                  .init(backgroundColor: backgroundColor))
            } else {
                //TODO: a full path based data structure 
//                if #available(macOS 13.0, iOS 16.0, *) {
//                    NavigationStack {
//                        #if os(iOS)
//                        ZStack(alignment: .top) {
//                            backgroundColor
//                                .ignoresSafeArea()
//                                .frame(maxWidth: .infinity,
//                                       maxHeight: .infinity)
//                            self
//                                .background(backgroundColor)
//                        }
//                        .navigationBarTitle("", displayMode: .inline)
//                        .navigationBarHidden(true)
//                        #else
//                        ZStack(alignment: .top) {
//                            backgroundColor
//                                .ignoresSafeArea()
//                                .frame(maxWidth: .infinity,
//                                       maxHeight: .infinity)
//                            self
//                                .background(backgroundColor)
//                        }
//                        #endif
//                    }
//                    .environment(\.graniteNavigationStyle,
//                                  .init(leadingButtonKind: .customView,
//                                        backgroundColor: backgroundColor,
//                                        leadingItem: leadingItem))
//                } else {
                    NavigationView {
                        #if os(iOS)
                        ZStack(alignment: .top) {
                            backgroundColor
                                .ignoresSafeArea()
                                .frame(maxWidth: .infinity,
                                       maxHeight: .infinity)
                            self
                                .background(backgroundColor)
                                .navigationViewStyle(.stack)
                        }
                        .navigationBarTitle("", displayMode: .inline)
                        .navigationBarHidden(true)
                        #else
                        ZStack(alignment: .top) {
                            backgroundColor
                                .ignoresSafeArea()
                                .frame(maxWidth: .infinity,
                                       maxHeight: .infinity)
                            self
                                .background(backgroundColor)
                        }
                        #endif
                    }
                    .environment(\.graniteNavigationStyle,
                                  .init(leadingButtonKind: .customView,
                                        backgroundColor: backgroundColor,
                                        leadingItem: leadingItem))
//                }
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
