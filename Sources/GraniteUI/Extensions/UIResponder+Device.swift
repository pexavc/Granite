//
//  UIResponder+Device.swift
//  
//
//  Created by PEXAVC on 9/14/20.
//

import Foundation

#if os(iOS)
import UIKit
extension UIResponder {
    public var orientation: UIDeviceOrientation {
        UIDevice.current.orientation
    }
    
    public var interface: UIUserInterfaceIdiom {
        UIDevice.current.userInterfaceIdiom
    }
    
    public var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    public var orientationIsIPhonePortrait: Bool {
        orientation == .portrait && isIPhone
    }
    
    public var orientationIsIPhoneLandscape: Bool {
        orientation.isLandscape && isIPhone
    }
}
#endif
