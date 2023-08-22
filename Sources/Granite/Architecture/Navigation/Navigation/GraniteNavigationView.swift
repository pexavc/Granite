//
//  GraniteNavigationView.swift
//  
//
//  Created by PEXAVC on 8/21/23.
//

import Foundation
import SwiftUI

//MARK: GraniteNavigationView
struct GraniteNavigationView<Content: View>: View {
    @Environment(\.graniteNavigationStyle) var style
    
    let routerKey: String
    
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
        
        if GraniteNavigation.mainSet {
            let key = "granite.app.main.router.child_\(GraniteNavigation.main.stackCount)"
            routerKey = GraniteNavigation(key).id
        } else {
            routerKey = GraniteNavigation.main.id
        }
        GraniteLog("Navigation initializing with \(routerKey)", level: .debug)
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                
                style.backgroundColor
                    .ignoresSafeArea()
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity)
                
                #if os(iOS)
                content()
                    .background(style.backgroundColor)
                    .navigationViewStyle(.stack)
                #else
                content()
                    .background(style.backgroundColor)
                #endif
                
                GraniteRouter(routerKey)
            }
            .environment(\.graniteNavigationRouterKey, routerKey)
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarHidden(true)
        }
    }
}
