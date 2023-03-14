//
//  GraniteRelayNetwork.swift
//  GraniteUI
//
//  Created by PEXAVC on 09/12/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

#if os(iOS)

import Foundation
import UIKit

extension UIApplication {
    
    var topViewController : UIViewController? {
        var topViewController: UIViewController? = nil
        if #available(iOS 13, *) {
            for scene in connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    for window in windowScene.windows {
                        guard window.isUserInteractionEnabled == true else {
                            continue
                        }
                        
                        if window.isKeyWindow {
                            topViewController = window.rootViewController
                        }
                    }
                }
            }
        } else {
            topViewController = keyWindow?.rootViewController
        }
        
        while true {
            if let presented = topViewController?.presentedViewController {
                topViewController = presented
            } else if let navController = topViewController as? UINavigationController {
                topViewController = navController.topViewController
            } else if let tabBarController = topViewController as? UITabBarController {
                topViewController = tabBarController.selectedViewController
            } else {
                break
            }
        }
        
        return topViewController
    }
    
}

#endif
