//
//  File.swift
//  
//
//  Created by PEXAVC on 6/20/23.
//

import Foundation
import SwiftUI

#if os(iOS)
import UIKit
public typealias GraniteMLImage = UIImage
public typealias GraniteMLBaseViewController = UIViewController
public typealias GraniteMLViewType = UIView
public typealias GraniteMLRepresentable = UIViewRepresentable
public typealias GraniteMLRepresentableContext = UIViewRepresentableContext
public typealias GraniteMLWindow = UIWindow
public typealias GraniteMLResponder = UIResponder
public typealias GraniteMLBaseApplicationDelegate = UIApplicationDelegate
#elseif os(OSX)
import AppKit
public typealias GraniteMLImage = NSImage
public typealias GraniteMLBaseViewController = NSViewController
public typealias GraniteMLViewType = NSView
public typealias GraniteMLRepresentable = NSViewRepresentable
public typealias GraniteMLRepresentableContext = NSViewRepresentableContext
public typealias GraniteMLWindow = NSWindow
public typealias GraniteMLResponder = NSObject
public typealias GraniteMLBaseApplicationDelegate = NSApplicationDelegate
#endif
