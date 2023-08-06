//
//  GraniteCenter.swift
//  Granite
//
//  Created by PEXAVC on 12/11/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

extension Storage {
    struct CenterIdentifierKey : Hashable {
        let id : String
        let keyPath : AnyKeyPath
    }
    
}

public protocol AnyGraniteCenter: Bindable, Findable {
    
}

/*
 Stores a GraniteComponent's and GraniteService's Vitals.
 GraniteState and GraniteEvents specifically.
*/
public protocol GraniteCenter: AnyGraniteCenter {
    associatedtype GenericGraniteState: GraniteState
    var state: GenericGraniteState { get set }
    var id: UUID { get }
    init()
}

extension GraniteCenter {
    public var id : UUID {
        if let id = Storage.shared.value(at: Storage.CenterIdentifierKey(id: String(describing: self), keyPath: \AnyGraniteCenter.self)) as? UUID {
            return id
        }
        else {
            let id = UUID()
            Storage.shared.setValue(id, at: Storage.CenterIdentifierKey(id: String(describing: self), keyPath: \AnyGraniteCenter.self))
            
            return id
        }
    }
    
    public func findStore() -> Store<GenericGraniteState>? {
        let mirror = Mirror(reflecting: self)
        let children = mirror.children

        return children.first { $0.value as? Store<GenericGraniteState> != nil }?.value as? Store<GenericGraniteState>
    }
    
    public func save() {
        findStore()?.projectedValue.persistence.save()
    }
}
