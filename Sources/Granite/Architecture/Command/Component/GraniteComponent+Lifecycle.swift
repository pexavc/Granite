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
        let relays = self.findRelays()
        
        guard let command = locate else {
            return view
            .onAppear {
                for relay in relays {
                    relay.awake()
                }
            }
            .onDisappear {
                for relay in relays {
                    relay.silence()
                }
            }
        }
        
        if #available(macOS 12.4, iOS 15, *) {
            
            return view
                .task {
                    for relay in relays {
                        relay.awake()
                    }
                    
                    await command.runTasks?()
                }
                .onAppear {
                    command.didAppear?()
                }
                .onDisappear {
                    command.didDisappear?()
                    
                    for relay in relays {
                        relay.silence()
                    }
                }
        } else {
            
            return view
                .onAppear {
                    for relay in relays {
                        relay.awake()
                    }
                    
                    command.didAppear?()
                }
                .onDisappear {
                    command.didDisappear?()
                    
                    for relay in relays {
                        relay.silence()
                    }
                }
        }
    }
}
