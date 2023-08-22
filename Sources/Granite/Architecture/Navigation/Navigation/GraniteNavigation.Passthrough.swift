//
//  GraniteNavigation.Passthrough.swift
//  
//
//  Created by PEXAVC on 1/25/23.
//

import Foundation
import SwiftUI
import GraniteUI

//MARK: Component
public struct NavigationPassthroughComponent<Component: GraniteComponent, Payload: GranitePayload>: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.graniteNavigationPassKey) var isActive
    
    class Screen<Component: GraniteComponent, Payload: GranitePayload> {
        
        var component: (() -> Component)
        var screen: AnyView? = nil
        var payload: Payload?
        
        init(_ component: @escaping (() -> Component), _ payload: Payload? = nil) {
            
            self.component = component
            self.payload = payload
        }
        
        func build(completion: (() -> Void)? = nil) {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                let componentBuilt = self?.component()
                componentBuilt?.locate?.command.build(.dependency(self?.payload))
                
                DispatchQueue.main.async { [weak self] in
                    guard let componentFinal = componentBuilt else { return }
                    self?.screen = AnyView(componentFinal)
                    completion?()
                }
            }
        }
        
        func clean() {
            self.screen = nil
        }
    }
    
    @Environment(\.graniteNavigationStyle) var style
    
    fileprivate var screen: Screen<Component, Payload>
    @State var loaded: Bool = false
    
    init(screen: Screen<Component, Payload>) {
        self.screen = screen
    }
    
    var leadingView : some View {
        Button(action: {
            GraniteHaptic.light.invoke()
            GraniteNavigation.routes.pop()
        }) {
            HStack {
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
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    public var body: some View {
#if os(iOS)
        Group {
            if isActive {
                ZStack {
                    style.backgroundColor
                        .ignoresSafeArea()
                        .frame(maxWidth: .infinity,
                               maxHeight: .infinity)
                    
                    if loaded,
                       let screen = screen.screen {
                        VStack(spacing: 0) {
                            leadingView
                                .padding(.horizontal, 24)
                            screen
                                //.graniteNavigation()
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
                .onAppear {
                    loaded = false
                    self.screen.build {
                        loaded = true
                    }
                }
//                .navigationBarBackButtonHidden(true)
//                .navigationBarItems(leading: leadingView)
                .onChange(of: isActive) { state in
                    if !state {
                        self.screen.clean()
                    }
                }
            } else {
                EmptyView()
            }
        }
        #else
        ZStack {}
        #endif
    }
}

//MARK: View
public struct NavigationPassthroughView<Component: View>: View {
    @Environment(\.graniteNavigationPassKey) var isActive
    class Screen<Component: View> {
        
        var component: (() -> Component)
        var screen: AnyView? = nil
        
        init(_ component: @escaping (() -> Component)) {
            
            self.component = component
        }
        
        func build(completion: (() -> Void)? = nil) {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                let componentBuilt = self?.component()
                
                DispatchQueue.main.async { [weak self] in
                    guard let componentFinal = componentBuilt else { return }
                    self?.screen = AnyView(componentFinal)
                    completion?()
                }
            }
        }
        
        func clean() {
            self.screen = nil
        }
    }
    
    @Environment(\.graniteNavigationStyle) var style
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    #if os(iOS)
    let generator = UIImpactFeedbackGenerator(style: .light)
    #endif
    
    fileprivate var screen: Screen<Component>
    @State var loaded: Bool = false
    
    init(screen: Screen<Component>) {
        self.screen = screen
    }
    
    var leadingView : some View {
        Button(action: {
            #if os(iOS)
            generator.prepare()
            generator.impactOccurred()
            #endif
            GraniteNavigation.routes.pop()
        }) {
            HStack {
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
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
        .animation(nil)
    }
    
    public var body: some View {
        #if os(iOS)
        Group {
            if isActive {
                ZStack {
                    style.backgroundColor
                        .ignoresSafeArea()
                        .frame(maxWidth: .infinity,
                               maxHeight: .infinity)
                    
                    if loaded,
                       let screen = screen.screen {
                        VStack(spacing: 0) {
                            leadingView
                                .padding(.horizontal, 24)
                            screen
                                //.graniteNavigation()
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
                .onAppear {
                    loaded = false
                    self.screen.build {
                        loaded = true
                    }
                }
                .onChange(of: isActive) { state in
                    if !state {
                        self.screen.clean()
                    }
                }
                .navigationBarBackButtonHidden(true)
                .navigationBarItems(leading: leadingView)
            } else {
                EmptyView()
            }
        }
        #else
        ZStack {
            style.backgroundColor
                .ignoresSafeArea()
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity)
            
            if loaded,
               let screen = screen.screen {
                screen
            }
            
            if loaded == false {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .onAppear {
            loaded = false
            self.screen.build {
                loaded = true
            }
        }
        #endif
    }
}

struct GraniteNavigationPassthroughEventKey: EnvironmentKey {
    public static var defaultValue: Bool = false
}

extension EnvironmentValues {
    var graniteNavigationPassKey: Bool {
        get { self[GraniteNavigationPassthroughEventKey.self] }
        set { self[GraniteNavigationPassthroughEventKey.self] = newValue }
    }
}

#if os(iOS)
extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
#endif
