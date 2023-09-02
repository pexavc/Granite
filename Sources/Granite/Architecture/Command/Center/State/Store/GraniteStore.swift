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
    
    let willChange: GraniteSignal.Payload<State>
    let didLoad: GraniteSignal
    //var didChange: (() -> Void)? = nil
    
    @Published internal var state : State
    @Published var isLoaded : Bool
    
    var syncEnabled: Bool = false
    var isSyncing: Bool = false
    
    internal var cancellables = Set<AnyCancellable>()
    //TODO: remove?
    fileprivate var persistStateChangesCancellable : AnyCancellable? = nil
    
    fileprivate let storage : AnyPersistence
    
    let autoSave : Bool
    
    public init(storage : AnyPersistence = EmptyPersistence(), autoSave: Bool = false) {
        self.storage = storage
        self.autoSave = autoSave
        self.state = .init()
        self.willChange = .init()
        self.didLoad = .init()
        self.isLoaded = autoSave == false
        
        $state
            .removeDuplicates()
            .debounce(for: .seconds(0.2), scheduler: RunLoop.main)
            .sink { [weak self] state in
            if self?.autoSave == true && self?.isSyncing == false {
                self?.persistence.save(state)
            }
        }.store(in: &cancellables)
        
        $isLoaded
            .removeDuplicates()
            .sink { [weak self] status in
                if status, let state = self?.state {
                    self?.didLoad.send()
                }
        }.store(in: &cancellables)
    }
    
    /*
     Force preload, which is async on the background thread
     by default, affects Services mostly
     */
    func preload() {
        persistence.forceRestore()
    }
    
    func restore(wait forCompletion: Bool = false) {
        self.persistence.restore(wait: forCompletion)
    }
    
    deinit {
        cancellables.forEach {
            $0.cancel()
        }
        
        cancellables.removeAll()
        
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
