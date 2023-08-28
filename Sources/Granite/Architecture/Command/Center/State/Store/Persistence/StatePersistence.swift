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
    
    public func save(_ state: State? = nil) {
        storage.save(state: state ?? getState())
    }
    
    public func restore(wait: Bool = false) {
        guard storage.hasRestored == false else { return }
        GraniteLog("restoring store: \(storage.key)", level: .debug)
        storage.readWriteQueue?.addBarrierBlock {
            if let state : State = storage.restore() {
                setState(state)
            } else {
                save()
            }
            
            isLoaded(true)
        }
        
        if wait {
            storage.readWriteQueue?.waitUntilAllOperationsAreFinished()
        }
    }
    
    public func forceRestore() {
        storage.readWriteQueue?.waitUntilAllOperationsAreFinished()
//        if let state : State = storage.restore() {
//            setState(state)
//            isLoaded(true)
//        } else {
//            save()
//        }
    }
    
    public func purge() {
        storage.purge()
    }
    
}
