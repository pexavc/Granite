//
//  Functions._.swift
//
//
//  Created by PEXAVC on 2/26/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import SwiftUI
#if os(iOS)
import UIKit
public typealias GraniteImage = UIImage
public typealias GraniteBaseViewController = UIViewController
public typealias GraniteViewType = UIView
public typealias GraniteRepresentable = UIViewRepresentable
public typealias GraniteRepresentableContext = UIViewRepresentableContext
//public typealias GraniteWindow = UIWindow
public typealias GraniteResponder = UIResponder
public typealias GraniteBaseApplicationDelegate = UIApplicationDelegate
#elseif os(OSX)
import AppKit
public typealias GraniteImage = NSImage
public typealias GraniteBaseViewController = NSViewController
public typealias GraniteViewType = NSView
public typealias GraniteRepresentable = NSViewRepresentable
public typealias GraniteRepresentableContext = NSViewRepresentableContext
//public typealias GraniteWindow = NSWindow
public typealias GraniteResponder = NSObject
public typealias GraniteBaseApplicationDelegate = NSApplicationDelegate
#endif
