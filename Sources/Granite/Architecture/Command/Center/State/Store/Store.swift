//
//  Store.swift
//  Granite
//
//  Created by PEXAVC on 12/10/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI

protocol AnyGraniteStore {
 
    var id : UUID { get }
    
    var willChange : AnyGraniteSignal { get }
    
}

/*
 PropertyWrapper swiftly sets up a GraniteState for GraniteStore
 usage
*/
@propertyWrapper
public struct Store<State : GraniteState> : DynamicProperty, AnyGraniteStore {
    
    public var id : UUID {
        container.id
    }
    
    public var wrappedValue : State {
        get {
            container.state
        }
        nonmutating set {
            container.state = newValue
        }
    }
    
    public var projectedValue : GraniteStore<State> {
        container
    }
    
    var willChange: AnyGraniteSignal {
        container.willChange
    }
    
    @ObservedObject var container : GraniteStore<State>

    var autoSave: Bool {
        container.autoSave
    }
    
    var isLoaded: Bool {
        container.isLoaded
    }
    
    var didLoad: GraniteSignal {
        container.didLoad
    }
    
    func restore(wait forCompletion: Bool = false) {
        container.restore(wait: shouldPreload || forCompletion)
    }
    
    func preload() {
        container.preload()
    }
    
    func save(_ state: State? = nil) {
        container.persistence.save(state)
    }
    
    private var shouldPreload: Bool
    
    public init(storage : AnyPersistence = EmptyPersistence(), autoSave: Bool = false) {
        container = .init(storage: storage, autoSave: autoSave)
        self.shouldPreload = false
    }
    
    public init(persist fileName: String,
                kind: PersistenceKind = .basic,
                autoSave: Bool = false,
                preload: Bool = false) {
        container = .init(storage: FilePersistence(key: fileName, kind: kind), autoSave: autoSave)
        self.shouldPreload = preload
        /*if a Service is called multiple times its relevant
        persistence files make sure it is operating from its
        last state
        */
        guard autoSave else { return }

        container.restore(wait: preload)
    }
}
