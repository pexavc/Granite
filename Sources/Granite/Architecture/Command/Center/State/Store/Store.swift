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
    
    func silence(viewUpdatesOnly updateView: Bool = false) {
        container.silence(viewUpdatesOnly: updateView)
    }
    
    func awake(viewUpdatesOnly updateView: Bool = false) {
        container.awake(viewUpdatesOnly: updateView)
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
    
    func sync(shutdown: Bool = false) {
        container.sync(shutdown: shutdown)
    }
    
    func prepareSync() {
        container.prepareSync()
    }
    
    var syncSignal: GraniteSignal.Payload<(State, UUID)> {
        container.syncSignal
    }
    
    var syncEnabled: Bool {
        container.syncEnabled
    }
    
    var isSyncing: Bool {
        container.isSyncing
    }
    
    var viewUpdatesSilenced: Bool {
        container.silenceViewUpdates
    }
    
    private var shouldPreload: Bool
    /*
     TODO:
     - Add debounce function
     - Add manual save function
     */
    public init(storage : AnyPersistence = EmptyPersistence(), autoSave: Bool = false) {
        container = .init(storage: storage, autoSave: autoSave)
        self.shouldPreload = false
    }
    
    public init(persist fileName: String, autoSave: Bool = false, preload: Bool = false) {
        container = .init(storage: FilePersistence(key: fileName), autoSave: autoSave)
        self.shouldPreload = preload
        /*if a Service is called multiple times its relevant
        persistence files make sure it is operating from its
        last state
        */
//        guard autoSave else { return }
//
//        //container.restore()
//
//        if preload {
//            //self.preload()
//        }
    }
}
