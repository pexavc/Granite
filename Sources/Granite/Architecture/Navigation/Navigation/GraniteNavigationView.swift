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
    
    @ObservedObject var routes: GraniteNavigation
    
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
        
        if GraniteNavigation.mainSet {
            _routes = .init(initialValue: .init(isMain: false))
        } else {
            _routes = .init(initialValue: .main)
        }
        
        GraniteLog("Navigation initializing with \(routes.id)", level: .debug)
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
                    .onDisappear {
                        GraniteLog("releasing: \(routes.id)", level: .debug)
                        routes.releaseStack()
                    }
                #else
                content()
                    .background(style.backgroundColor)
                #endif
                
                GraniteRouter()
                    .environmentObject(routes)
            }
            .environment(\.graniteNavigationRouterKey, routes.id)
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarHidden(true)
        }
    }
}
