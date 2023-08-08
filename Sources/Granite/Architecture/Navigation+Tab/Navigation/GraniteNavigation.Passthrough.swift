//
//  GraniteNavigation.Passthrough.swift
//  
//
//  Created by PEXAVC on 1/25/23.
//

import Foundation
import SwiftUI

//MARK: Component
public struct NavigationPassthroughComponent<Component: GraniteComponent, Payload: GranitePayload>: View {
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
    
    @Binding var isActive: Bool
    
    @Environment(\.graniteNavigationStyle) var style
    
    fileprivate var screen: Screen<Component, Payload>
    @State var loaded: Bool = false
    
    init(isActive: Binding<Bool>, screen: Screen<Component, Payload>) {
        self._isActive = isActive
        self.screen = screen
    }
    
    var leadingView : some View {
        Button(action: {
            self.$isActive.wrappedValue = false
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
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: leadingView)
        #else
        ZStack {}
        #endif
    }
}

//MARK: View
public struct NavigationPassthroughView<Component: View>: View {
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
    
    @Binding var isActive: Bool
    
    @Environment(\.graniteNavigationStyle) var style
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    #if os(iOS)
    let generator = UIImpactFeedbackGenerator(style: .light)
    #endif
    
    fileprivate var screen: Screen<Component>
    @State var loaded: Bool = false
    
    init(isActive: Binding<Bool>, screen: Screen<Component>) {
        self._isActive = isActive
        self.screen = screen
    }
    
    var leadingView : some View {
        Button(action: {
            #if os(iOS)
            generator.prepare()
            generator.impactOccurred()
            presentationMode.wrappedValue.dismiss()
            #endif
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
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: leadingView)
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
