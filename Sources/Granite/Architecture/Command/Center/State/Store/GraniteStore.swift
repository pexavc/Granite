//
//  GraniteStore.swift
//  Granite
//
//  Created by PEXAVC on 12/10/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

extension Storage {
    struct StoreIdentifierKey : Hashable {
        let id : String
        let keyPath: AnyKeyPath
    }
    
    struct StoreSignalIdentifierKey : Hashable {
        let id : UUID
        let keyPath : AnyKeyPath
    }
    
}

/*
 A GraniteState can be wrapped with a GraniteStore
 inwhich observers notify linked Components and Services.
*/
public class GraniteStore<State : GraniteState>: ObservableObject {
    
    public let id = UUID()
    
    public var idSync : UUID {
        if let id = Storage.shared.value(at: Storage.StoreIdentifierKey(id: String(describing: self), keyPath: \GraniteStore<State>.idSync)) as? UUID {
            return id
        }
        else {
            let id = UUID()
            Storage.shared.setValue(id, at: Storage.StoreIdentifierKey(id: String(describing: self), keyPath: \GraniteStore<State>.idSync))
            return id
        }
    }
    
    public var syncSignal : GraniteSignal.Payload<(State, UUID)> {
        Storage.shared.value(at: Storage.StoreSignalIdentifierKey(id: self.idSync, keyPath: \GraniteStore<State>.syncSignal)) {
            GraniteSignal.Payload<(State, UUID)>()
        }
    }
    
    let willChange: GraniteSignal.Payload<State>
    let didLoad: GraniteSignal

    @Published internal var state : State
    @Published var isLoaded : Bool
    
    var isSyncing: Bool = false
    
    internal var cancellables = Set<AnyCancellable>()
    internal var pausable: PausableSinkSubscriber<State, Never>? = nil
    fileprivate var persistStateChangesCancellable : AnyCancellable?
    
    fileprivate let storage : AnyPersistence
    let autoSave : Bool
    
    public init(storage : AnyPersistence = EmptyPersistence(), autoSave: Bool = false) {
        self.storage = storage
        self.autoSave = autoSave
        self.state = .init()
        self.willChange = .init()
        self.didLoad = .init()
        self.isLoaded = autoSave == false
        
        pausable = $state
            .removeDuplicates()
            .pausableSink { [weak self] state in
                self?.willChange.send(state)
                
                let shouldSync = self?.isSyncing == true
                let id = self?.id ?? .init()
                guard let signal = self?.syncSignal else { return }
                if shouldSync {
                    Task.detached {
                        signal.send((state, id))
                    }
                }
        }
        pausable?.store(in: &cancellables)
        
        $isLoaded
            .removeDuplicates()
            .sink { [weak self] status in
                if status, let state = self?.state {
                    self?.willChange.send(state)
                    self?.didLoad.send()
                    self?.pausable?.state = .normal
                }
        }.store(in: &cancellables)
        
        syncSignal += { [weak self] (state, id) in
            guard self?.id != id else {
                //TODO: debounce?
                if self?.autoSave == true {
                    self?.persistence.save()
                }
                    
                return
            }
            
            //pause to avoid sync loop
            self?.pausable?.state = .stopped
            self?.state = state
            //update view
            self?.willChange.send(state)
            self?.pausable?.state = .normal
        }
    }
    
    func sync(shutdown: Bool = false) {
        isSyncing = shutdown == false
    }
    
    func preload() {
        persistence.forceRestore()
    }
    
    deinit {
        if autoSave {
            self.persistence.save()
        }
        
        cancellables.forEach {
            $0.cancel()
        }
        
        cancellables.removeAll()
        
        pausable?.cancel()
        pausable = nil
        
        persistStateChangesCancellable?.cancel()
        persistStateChangesCancellable = nil
    }
    
}

extension GraniteStore {
    
    public var binding : Binding<State> {
        .init {
            return self.state
        } set: { value in
            self.state = value
        }
    }
    
}

extension GraniteStore where State : Codable {
    
    public var persistence : StatePersistence<State> {
        .init(storage: storage) {
            return self.state
        } set: { value in
            self.state = value
        } loaded: { status in
            self.isLoaded = status
        }
    }
    
}
