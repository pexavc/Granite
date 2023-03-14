//
//  Service.swift
//  Granite
//
//  Created by PEXAVC on 12/12/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI

@propertyWrapper
public struct Service<Center: GraniteCenter> : DynamicProperty {
    public var id : UUID {
        command.id
    }

    public var wrappedValue : Center {
        get {
            command.center
        }
        mutating set {
            command.update(newValue.state)
        }
    }
    
    public var projectedValue : GraniteCommand<Center> {
        command
    }

    public var command : GraniteCommand<Center>
    
    public init(_ kind: GraniteRelayKind = .offline) {
        command = .init(.service(kind))
    }
}
