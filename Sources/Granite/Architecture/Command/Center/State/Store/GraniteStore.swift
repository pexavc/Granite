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

/*
 A GraniteState can be wrapped with a GraniteStore
 inwhich observers notify linked Components and Services.
*/
public class GraniteStore<State : GraniteState>: ObservableObject {
    
    public let id = UUID()
    
    let willChange: GraniteSignal.Payload<State>
    let didLoad: GraniteSignal

    @Published internal var state : State
    @Published var isLoaded : Bool
    
    internal var cancellables = Set<AnyCancellable>()
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
        
        $state
            .removeDuplicates()
            .sink { [weak self] state in
                self?.willChange.send(state)
        }.store(in: &cancellables)
        
        $isLoaded
            .removeDuplicates()
            .sink { [weak self] status in
                if status {
                    guard let state = self?.state else { return }
                    self?.willChange.send(state)
                    self?.didLoad.send()
                }
        }.store(in: &cancellables)
    }
    
    deinit {
        if autoSave {
            self.persistence.save()
        }
        
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
            
            //TODO: debounce?
            if self.autoSave {
                self.persistence.save()
            }
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
