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
    
    @ObservedObject fileprivate var container : GraniteStore<State>

    var autoSave: Bool {
        container.autoSave
    }
    
    var isLoaded: Bool {
        container.isLoaded
    }
    
    var didLoad: GraniteSignal {
        container.didLoad
    }
    
    func preload() {
        container.preload()
    }
    
    func sync(shutdown: Bool = false) {
        container.sync(shutdown: shutdown)
    }
    
    var syncSignal: GraniteSignal.Payload<(State, UUID)> {
        container.syncSignal
    }
    
    var isSyncing: Bool {
        container.isSyncing
    }
    
    /*
     TODO:
     - Add debounce function
     - Add manual save function
     */
    public init(storage : AnyPersistence = EmptyPersistence(), autoSave: Bool = false) {
        container = .init(storage: storage, autoSave: autoSave)
    }
    
    public init(persist fileName: String, autoSave: Bool = false, preload: Bool = false) {
        container = .init(storage: FilePersistence(key: fileName), autoSave: autoSave)
        
        /*if a Service is called multiple times its relevant
        persistence files make sure it is operating from its
        last state
        */
        guard autoSave else { return }
        if preload {
            container.persistence.forceRestore()
        } else {
            container.persistence.restore()
        }
    }
}
