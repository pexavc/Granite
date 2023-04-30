//
//  GraniteComponent+Lifecycle.swift
//  Granite
//
//  Created by PEXAVC on 12/8/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI

/*
 Primarily used for Component/Service lifecycle debugging
 and observation. 
*/
enum GraniteLifecycle: String, Equatable, Codable {
    case attached
    case deAttached
    
    case appeared
    case disappeared
    case deLink
    
    case none
    
    var isAvailable: Bool {
        switch self {
        case .attached, .appeared:
            return true
        default:
            return false
        }
    }
}

extension GraniteComponent {
    func lifecycle<Body : View>(_ view : Body) -> some View {
        return view
            .onAppear {
                locate?.didAppear?()
                
                let relays = self.findRelays()
                for relay in relays {
                    relay.awake()
                }
            }
            .onDisappear {
                locate?.didDisappear?()
                
                let relays = self.findRelays()
                for relay in relays {
                    relay.silence()
                }
            }
    }
}
