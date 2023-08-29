//
//  GraniteNavigation.Passthrough.swift
//  
//
//  Created by PEXAVC on 1/25/23.
//

import Foundation
import SwiftUI

public protocol GraniteNavigationDestination: View {
    var destinationStyle: GraniteNavigationDestinationStyle { get }
}

public extension GraniteNavigationDestinationStyle {
    var destinationStyle: GraniteNavigationDestinationStyle {
        .init()
    }
}

//MARK: Component
public struct NavigationPassthroughComponent<Component: GraniteComponent, Payload: GranitePayload>: View {
    
    class Screen<Component: GraniteComponent, Payload: GranitePayload> {
        
        var component: (() -> Component)
        var view: AnyView? = nil
        var payload: Payload?
        var style: GraniteNavigationDestinationStyle?
        
        init(_ component: @escaping (() -> Component), _ payload: Payload? = nil) {
            
            self.component = component
            self.payload = payload
        }
        
        func build(completion: (() -> Void)? = nil) {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                let componentBuilt = self?.component()
                
                //TODO: remove payload building logic, in favor of EnvironmentValues
                //fire once
                //componentBuilt?.locate?.command.build(.dependency(self?.payload))
                
                GraniteLog("building screen")
                
                DispatchQueue.main.async { [weak self] in
                    guard let componentFinal = componentBuilt else { return }
                    
                    if let gnds = componentFinal.view as? (any GraniteNavigationDestination) {
                        self?.style = gnds.destinationStyle
                    }
                    self?.view = AnyView(componentFinal)
                    
                    GraniteLog("applying style and setting screen")
                    completion?()
                }
            }
        }
        
        func clean() {
            self.view = nil
        }
    }
    
    @Environment(\.graniteRouter) var router
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.graniteNavigationStyle) var style
    @Environment(\.graniteNavigationDestinationStyle) var destinationStyle
    @Environment(\.graniteNavigationWindowDestinationStyle) var windowStyle
    
    fileprivate var screen: Screen<Component, Payload>
    @State var loaded: Bool = false
    
    //Simulate slide in nav stack anim
    //should be customizable via destination style
    @State var isShowing: Bool = false
    
    init(screen: Screen<Component, Payload>) {
        self.screen = screen
    }
    
    var destinationStyleFinal: GraniteNavigationDestinationStyle {
        self.screen.style ?? destinationStyle
    }
    
    func dismiss() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        router.navigation.pop()
        self.screen.clean()
        self.loaded = false
    }
    
    var leadingItem: some View {
        Button(action: {
            dismiss()
        }) {
            switch style.leadingButtonKind {
            case .customSystem, .back, .close:
                Image(systemName: style.leadingButtonImageName)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white)
            case .customView:
                style.leadingItem
            default:
                Image(style.leadingButtonImageName)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var navBar : some View {
        HStack(spacing: 0) {
            leadingItem
            if destinationStyleFinal.fullWidth == false {
                Spacer()
            }
            destinationStyleFinal
                .trailingItem()
                .frame(maxWidth: destinationStyleFinal.fullWidth ? .infinity : nil)
        }
        .frame(height: style.barStyle.height)
        .padding(style.barStyle.edges)
        .background(style.backgroundColor)
    }
    
    public var body: some View {
        Group {
            #if os(iOS)
            SlideAnimationContainerView($isShowing,
                      loaded: $loaded) {
                mainView
            }
            #else
            mainView
                .environment(\.graniteNavigationShowingKey, loaded)
                .environment(\.graniteNavigationAnimationKey, false)
            #endif
        }
        .onDisappear {
            self.screen.clean()
            self.loaded = false
            GraniteLog("Navigation Stack Window released", level: .debug)
        }
        .onAppear {
            self.screen.build {
                loaded = true
                GraniteLog("Navigation Stack Window loaded, isPresented: \(presentationMode.wrappedValue.isPresented)", level: .debug)
            }
        }
        .onChange(of: isShowing) { state in
            guard !state else { return }
            GraniteLog("Navigated view dismissed via sliding")
            dismiss()
        }
    }
    
    public var mainView: some View {
        ZStack {
            
            if loaded,
               let view = screen.view {
                //Only available when a new window is pushed
                if let windowStyle,
                   #available(iOS 15.0, macOS 12.0, *) {
                    view
                        .onAppear {
                            GraniteLog("screen appeared")
                        }
                        .overlay(alignment: .top) {
                            destinationStyleFinal
                                .navBarBGColor
                                .ignoresSafeArea(.all)
                                .frame(maxWidth: .infinity)
                                //TODO: seems hackish
                                //but, on a simple window that has a transparent title window bar, a height:1 sets the whole region automatically to the default titlebarheight
                                .frame(height: 1)
                        }
                } else {
                    if destinationStyleFinal.isCustomTrailing {
                        ZStack(alignment: .top) {
                            if destinationStyleFinal.hideLeadingView == false {
                                navBar
                                    .background(destinationStyleFinal.navBarBGColor)
                            }
                            view
                        }
                    } else {
                        VStack(spacing: 0) {
                            navBar
                                .background(destinationStyleFinal.navBarBGColor)
                            view
                        }
                        .onAppear {
                            GraniteLog("screen appeared")
                        }
                    }
                }
            }
            
            if loaded == false {
                VStack {
                    Spacer()
#if os(iOS)
                    ProgressView()
#else
                    ProgressView()
                        .scaleEffect(0.6)
#endif
                    Spacer()
                }
            }
        }
    }
}

