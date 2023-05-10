//
//  Command.swift
//  Granite
//
//  Created by PEXAVC on 12/12/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI

@propertyWrapper
public struct Command<C: GraniteCenter> : DynamicProperty {
    public var id : UUID {
        command.id
    }

    public var wrappedValue : C {
        get {
            command.center
        }
        mutating set {
            command.update(newValue.state)
        }
    }
    
    public var projectedValue : GraniteCommand<C> {
        command
    }
    
    var didAppear: (() -> Void)? {
        command.didAppear
    }
    var didDisappear: (() -> Void)? {
        command.didDisappear
    }
    
    //TODO: used to be StoreObject/ObservedObject,
    //Observed object was not propagating changes in a nested view
    @StateObject public var command : GraniteCommand<C> = .init(.component)

    public init() {}
}
