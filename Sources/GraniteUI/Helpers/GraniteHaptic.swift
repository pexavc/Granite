//
//  GraniteHaptic.swift
//
//
//  Created by PEXAVC on 2/26/21.
//

import Foundation
#if os(iOS)
import UIKit

private func graniteHapticFeedbackDefaultSuccess() {
    let generator = UINotificationFeedbackGenerator()
    generator.prepare()
    generator.notificationOccurred(.success)
}

private func graniteHapticFeedbackImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.prepare()
    generator.impactOccurred()
}
#endif

public enum GraniteHaptic {
    case light
    case none
    
    public func invoke() {
        switch self {
        case .light:
            GraniteHaptic.basic()
        default:
            break
        }
    }
    
    public static func onChangeAppColorScheme() {
        #if os(iOS)
        graniteHapticFeedbackDefaultSuccess()
        #endif
        
    }
    
    public static func onShowGraphIndicator() {
        #if os(iOS)
        graniteHapticFeedbackImpact(style: .heavy)
        #endif
    }
    
    public static func onChangeTimeMode() {
        #if os(iOS)
        graniteHapticFeedbackImpact(style: .light)
        #endif
    }
    
    public static func onChangeLineSegment() {
        #if os(iOS)
        graniteHapticFeedbackImpact(style: .light)
        #endif
    }
    
    public static func basic() {
        #if os(iOS)
        graniteHapticFeedbackImpact(style: .light)
        #endif
    }
}
