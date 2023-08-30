//
//  Relay.swift
//  Granite
//
//  Created by PEXAVC on 12/12/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI

public protocol AnyRelay {
    var id: UUID { get }
    func detach()
    func awake()
    func silence()
    var isOnline: Bool { get }
}

extension Relay: AnyRelay {
    public func detach() {
        Prospector.shared.node(for: self.id)?.remove()
    }
}

@propertyWrapper
public struct Relay<Service: GraniteService> : DynamicProperty {
    
    public var id : UUID {
        relay.id
    }

    public var wrappedValue : Service {
        get {
            relay.service
        }
        mutating set {
            relay.update(newValue.center.state)
        }
    }
    
    public var isOnline: Bool {
        relay.service.locate?.command.isOnline == true
    }
    
    //12-21-12
    //Changed from @StoreObject, while investigating an issue
    //to reducer events not forwarding from within reducers
    //notes can be found in GraniteReducer.swift
    
    @SharedObject(String(reflecting: Self.self)) public var relay : GraniteRelay<Service>
//    @ObservedObject public var relay : GraniteRelay<Service>
    
    let isDiscoverable: Bool
    public init(_ behavior: GraniteRelayBehavior = .normal,
                isDiscoverable: Bool = true, label: String = "") {
        self.isDiscoverable = isDiscoverable
//        self._relay = .init(wrappedValue: .init(isDiscoverable: isDiscoverable))
        
        switch behavior {
        case .silence:
            relay.silence()
        default:
            break
        }
    }
    
    public func awake() {
        relay.awake()
    }
    
    public func silence() {
        relay.silence()
    }
}

public enum GraniteRelayBehavior {
    case normal
    case silence
    case silenceViewUpdates
    case detach
}
