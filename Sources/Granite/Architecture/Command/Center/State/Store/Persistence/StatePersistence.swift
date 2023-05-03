//
//  StatePersistence.swift
//  Granite
//
//  Created by PEXAVC on 12/10/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation

/*
 Sets a persistency type to be enabled along with a GraniteState
 for saving and retrieval operations
*/
public struct StatePersistence<State : Codable> {
    
    private unowned let storage : AnyPersistence
    
    private let getState : () -> State
    private let setState : (State) -> Void
    
    private let isLoaded : (Bool) -> Void
    
    init(storage : AnyPersistence, get : @escaping () -> State, set : @escaping (State) -> Void, loaded : @escaping (Bool) -> Void) {
        self.storage = storage
        self.getState = get
        self.setState = set
        self.isLoaded = loaded
    }
    
    public func save() {
        storage.save(state: getState())
    }
    
    public func restore() {
        DispatchQueue.global(qos: .background).async {
            if let state : State = storage.restore() {
                DispatchQueue.main.async {
                    setState(state)
                    isLoaded(true)
                }
            }
        }
    }
    
    public func forceRestore() {
        if let state : State = storage.restore() {
            setState(state)
            isLoaded(true)
        }
    }
    
    public func purge() {
        storage.purge()
    }
    
}
