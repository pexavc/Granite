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
        var screen: AnyView? = nil
        var payload: Payload?
        var style: GraniteNavigationDestinationStyle?
        
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
                    
                    if let gnds = componentFinal.view as? (any GraniteNavigationDestination) {
                        self?.style = gnds.destinationStyle
                    }
                    self?.screen = AnyView(componentFinal)
                    completion?()
                }
            }
        }
        
        func clean() {
            self.screen = nil
        }
    }
    #if os(iOS)
    let generator = UIImpactFeedbackGenerator(style: .light)
    #endif
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.graniteNavigationRouterKey) var routerKey: String
    @Environment(\.graniteNavigationStyle) var style
    @Environment(\.graniteNavigationDestinationStyle) var destinationStyle
    
    fileprivate var screen: Screen<Component, Payload>
    @State var loaded: Bool = false
    
    init(screen: Screen<Component, Payload>) {
        self.screen = screen
    }
    
    var destinationStyleFinal: GraniteNavigationDestinationStyle {
        self.screen.style ?? destinationStyle
    }
    
    var leadingItem: some View {
        Button(action: {
            generator.impactOccurred()
            GraniteNavigation.router(for: routerKey).pop()
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
                .trailingItem
                .frame(maxWidth: destinationStyleFinal.fullWidth ? .infinity : nil)
        }
        .frame(height: style.barStyle.height)
        .padding(style.barStyle.edges)
    }
    
    public var body: some View {
#if os(iOS)
        Group {
            ZStack {
                style.backgroundColor
                    .ignoresSafeArea()
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity)
                
                if loaded,
                   let screen = screen.screen {
                    VStack(spacing: 0) {
                        navBar
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
        #else
        ZStack {}
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

struct GraniteNavigationRouterKey: EnvironmentKey {
    public static var defaultValue: String = ""
}

extension EnvironmentValues {
    var graniteNavigationRouterKey: String {
        get { self[GraniteNavigationRouterKey.self] }
        set { self[GraniteNavigationRouterKey.self] = newValue }
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
