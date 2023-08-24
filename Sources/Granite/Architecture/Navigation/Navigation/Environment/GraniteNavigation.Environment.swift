//
//  GraniteNavigation.Environment.swift
//  
//
//  Created by Ritesh Pakala on 8/23/23.
//

import Foundation
import SwiftUI

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
