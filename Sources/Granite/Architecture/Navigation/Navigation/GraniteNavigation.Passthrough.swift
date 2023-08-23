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
    
    @Environment(\.graniteRouter) var router
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.graniteNavigationStyle) var style
    @Environment(\.graniteNavigationDestinationStyle) var destinationStyle
    
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
                .trailingItem
                .frame(maxWidth: destinationStyleFinal.fullWidth ? .infinity : nil)
        }
        .frame(height: style.barStyle.height)
        .padding(style.barStyle.edges)
        .background(style.backgroundColor)
    }
    
    public var body: some View {
#if os(iOS)
        Group {
            #if os(iOS)
            SlideView($isShowing,
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
#else
        ZStack {}
#endif
    }
    
    public var mainView: some View {
        ZStack {
            
            if loaded,
               let screen = screen.screen {
                VStack(spacing: 0) {
                    navBar
                        .background(destinationStyle.navBarBGColor)
                    screen
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

struct GraniteNavigationPassthroughEventKey: EnvironmentKey {
    public static var defaultValue: Bool = false
}

extension EnvironmentValues {
    var graniteNavigationPassKey: Bool {
        get { self[GraniteNavigationPassthroughEventKey.self] }
        set { self[GraniteNavigationPassthroughEventKey.self] = newValue }
    }
}

public struct GraniteNavigationRouterKey: EnvironmentKey {
    public static var defaultValue: GraniteNavigation.Router = GraniteNavigation.main.asRouter
}

public extension EnvironmentValues {
    var graniteRouter: GraniteNavigation.Router {
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

public struct GraniteNavigationAnimationKey: EnvironmentKey {
    public static var defaultValue: Bool = false
}

public extension EnvironmentValues {
    var graniteNavigationAnimationKey: Bool {
        get { self[GraniteNavigationAnimationKey.self] }
        set { self[GraniteNavigationAnimationKey.self] = newValue }
    }
}

public struct GraniteNavigationShowingKey: EnvironmentKey {
    #if os(iOS)
    public static var defaultValue: Bool = false
    #else
    //TODO: maybe needs more thought or more properties exposed to give navigation context
    public static var defaultValue: Bool = true
    #endif
}

public extension EnvironmentValues {
    var graniteNavigationShowingKey: Bool {
        get { self[GraniteNavigationShowingKey.self] }
        set { self[GraniteNavigationShowingKey.self] = newValue }
    }
}

//MARK: Slide in /swipe
struct SlideView<MenuContent: View>: View {
    @Environment(\.graniteNavigationStyle) var style
    
    @Binding var isShowing: Bool
    @Binding var loaded: Bool
    
    let animationDuration: CGFloat
    
    var startThreshold: CGFloat = 0.05
    var activeThreshold: CGFloat = 0.6
    var viewingThreshold: CGFloat = 1
    
    var startWidth: CGFloat
    var width: CGFloat
    
    @State var offsetX: CGFloat = 0
    
    //First load only
    @State var hasShown: Bool = false
    
    var opacity: CGFloat {
        (offsetX / width) * 0.8
    }
    
    private let menuContent: () -> MenuContent
    
    init(_ isShowing: Binding<Bool>,
         loaded: Binding<Bool>,
         animationDuration: CGFloat = 0.6,
         @ViewBuilder _ menuContent: @escaping () -> MenuContent) {
        _isShowing = isShowing
        _loaded = loaded
#if os(iOS)
        let viewingWidth: CGFloat = UIScreen.main.bounds.width * viewingThreshold
#else
        let viewingWidth: CGFloat = 350
#endif
        self._offsetX = .init(initialValue: viewingWidth)
        self.width = viewingWidth
        self.startWidth = viewingWidth * startThreshold
        self.menuContent = menuContent
        self.animationDuration = animationDuration
    }
    
    var body: some View {
        let drag = DragGesture()
            .onChanged { value in
                guard abs(value.translation.width) >= startWidth else {
                    return
                }
                DispatchQueue.main.async {
                    
                    //isShowing = 0
                    
                    //!isShowing = width
                    
                    let translation = (value.translation.width - (startWidth * (isShowing ? 1 : -1))) + (isShowing ? 0 : width)
                    self.offsetX = max(0, min(translation, width))
                }
            }
            .onEnded { event in
                DispatchQueue.main.async {
                    if offsetX > activeThreshold * width {
                        withAnimation {
                            self.isShowing = false
                            self.offsetX = width
                        }
                    } else{
                        
                        withAnimation {
                            self.isShowing = true
                            self.offsetX = 0
                        }
                    }
                }
            }
        
        return ZStack(alignment: .leading) {
            style.backgroundColor
                .ignoresSafeArea()
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity)
                .opacity(1.0 - (self.offsetX / width))
            
            menuContent()
                .offset(x: self.offsetX)
                .environment(\.graniteNavigationShowingKey, self.hasShown)
                .environment(\.graniteNavigationAnimationKey, self.offsetX != 0)
        }
        .simultaneousGesture(drag)
        .onChange(of: loaded) { state in
            guard state else { return }
            
            //TODO: duration should be customizable from granite destination
            withAnimation(.interactiveSpring(blendDuration: animationDuration)) {
                self.isShowing = true
                self.offsetX = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                self.hasShown = true
            }
        }
    }
}
