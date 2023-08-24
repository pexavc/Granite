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
public class GraniteStore<State : GraniteState>: ObservableObject, Nameable {
    
    public let id = UUID()
    
    public var idSync : UUID {
        if let id = Storage.shared.value(at: Storage.StoreIdentifierKey(id: String(reflecting: self), keyPath: \GraniteStore<State>.idSync)) as? UUID {
            return id
        }
        else {
            let id = UUID()
            Storage.shared.setValue(id, at: Storage.StoreIdentifierKey(id: String(reflecting: self), keyPath: \GraniteStore<State>.idSync))
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
    
    var syncEnabled: Bool = false
    var isSyncing: Bool = false
    
    internal var cancellables = Set<AnyCancellable>()
    internal var pausable: PausableSinkSubscriber<State, Never>? = nil
    internal var pausableLoaded: PausableSinkSubscriber<Bool, Never>? = nil
    //TODO: remove?
    fileprivate var persistStateChangesCancellable : AnyCancellable? = nil
    fileprivate var syncCancellable: AnyCancellable? = nil
    fileprivate var syncTask: Task<Void, Error>? = nil
    
    fileprivate let storage : AnyPersistence
    
    var silenceViewUpdates: Bool = false
    
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
            if self?.silenceViewUpdates == false {
                self?.willChange.send(state)
            }
                
            guard self?.isSyncing == false else {
                self?.isSyncing = false
                return
            }
            
            let shouldSync = self?.syncEnabled == true
            let id = self?.id ?? .init()
            
            if let signal = self?.syncSignal,
               shouldSync {
                
                //TODO: this detachment needs too be revisited
                self?.syncTask = Task(priority: .userInitiated) {
                    signal.send((state, id))
                }
            }
            
            if self?.autoSave == true && self?.isSyncing == false {
                self?.persistence.save(state)
            }
        }
        pausable?.store(in: &cancellables)
        
        pausableLoaded = $isLoaded
            .removeDuplicates()
            .pausableSink { [weak self] status in
                if status, let state = self?.state {
                    self?.pausable?.state = .normal
                    
                    if self?.silenceViewUpdates == false {
                        self?.willChange.send(state)
                    }
                    
                    self?.didLoad.send()
                }
        }
        pausableLoaded?.store(in: &cancellables)
        pausableLoaded?.state = .normal
        
        /*
         See GraniteCommand: Line 152
             GraniteRelay:   Line 114-133
         */
        syncCancellable = syncSignal += { [weak self] (state, id) in
            guard self?.syncEnabled == true,
                  self?.id != id else {
                return
            }

            //GraniteLog("syncing: \(self?.NAME)", level: .debug)

            //self?.silence()
            self?.isSyncing = true
            self?.state = state
            //self?.awake()
        }
    }
    
    /*
     Sync should be toggled via GraniteCommand
     GraniteCommand is the core object store of
     all instance types, Components and Services currently
     */
    func sync(shutdown: Bool = false) {
        syncEnabled = shutdown == false
        
//        guard syncEnabled else { return }
    }
    
    /*
     Extends container to allow calls from outside helps
     prevent multiple draw calls during state updates
     */
    func silence(viewUpdatesOnly: Bool = false) {
        if viewUpdatesOnly {
            self.silenceViewUpdates = true
        } else {
            pausable?.state = .stopped
        }
    }
    
    func awake(viewUpdatesOnly: Bool = false) {
        if viewUpdatesOnly {
            self.silenceViewUpdates = false
        } else {
            pausable?.state = .normal
        }
    }
    
    func prepareSync() {
        self.isSyncing = true
    }
    
    
    /*
     Force preload, which is async on the background thread
     by default, affects Services mostly
     */
    func preload() {
        persistence.forceRestore()
    }
    
    func restore() {
        self.persistence.restore()
    }
    
    deinit {
        //TODO: doesn't seem necessary and is a expensive op
//        if autoSave {
//            self.persistence.save()
//        }
//        Prospector.shared.node(for: id)?.remove(includeChildren: false)
        self.syncTask?.cancel()
        self.syncTask = nil
        
        syncCancellable?.cancel()
        syncCancellable = nil
        
        cancellables.forEach {
            $0.cancel()
        }
        
        cancellables.removeAll()
        
        pausable?.cancel()
        pausable = nil
        
        pausableLoaded?.cancel()
        pausableLoaded = nil
        
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
