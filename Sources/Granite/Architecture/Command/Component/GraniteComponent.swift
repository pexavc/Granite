//
//  GraniteComponent.swift
//  Granite
//
//  Created by PEXAVC on 12/8/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

extension Storage {

    struct ComponentIdentifierKey : Hashable {
        let id : String
        let keyPath: AnyKeyPath
    }
    
}

/*
 A GraniteComponent are Granite's Parent/Root Views setup for
 Reducer and complex logic handling/routing
*/
extension GraniteComponent {
    public var id : UUID {
        if let id = locate?.id {
            return id
        } else if let id = Storage.shared.value(at: Storage.ComponentIdentifierKey(id: String(describing: self), keyPath: \Self.self)) as? UUID {
            return id
        }
        else {
            let id = UUID()
            Storage.shared.setValue(id, at: Storage.ComponentIdentifierKey(id: String(describing: self), keyPath: \Self.self))
            return id
        }
    }
}

public protocol AnyGraniteComponent {
    
}

public protocol GraniteComponent: AnyGraniteComponent, Identifiable, View {
    associatedtype GenericGraniteCenter: GraniteCenter
    associatedtype ComponentView: View
    
    var center: GenericGraniteCenter { get set }
    @ViewBuilder var view: Self.ComponentView { get }
}

extension GraniteComponent {
    public var locate: Command<Self.GenericGraniteCenter>? {

        let mirror = Mirror(reflecting: self)
        let children = mirror.children

        guard let child = children.first(where: { $0.value as? Command<Self.GenericGraniteCenter> != nil }) else {
            return nil
        }
        
        return child.value as? Command<Self.GenericGraniteCenter>
    }
    
    public var state: Self.GenericGraniteCenter.GenericGraniteState {
        locate?.command.center.state ?? .init()
    }
    
    public var isLoaded: Bool {
        locate?.command.center.findStore()?.isLoaded == true
    }
}

