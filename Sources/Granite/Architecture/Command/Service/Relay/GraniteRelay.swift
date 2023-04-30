//
//  GraniteRelay.swift
//  Granite
//
//  Created by PEXAVC on 12/12/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

/*
 NOTE: All relays are online now with the introduction of `SharedObject`
 
 If a GraniteRelay is online, when 1 relay is updated
 all components using the same relay and observing the same
 changing properties will update simultaneously
*/
public enum GraniteRelayKind {
    case online
    case offline
}

/*
 A GraniteRelay allows a GraniteService to be readily available
 in Components and/or Reducers. When inside components changes
 will propogate view changes.
*/
final public class GraniteRelay<Service: GraniteService>: Inspectable, Prospectable, Findable, Director, SharableObject {
    public static var initialValue: GraniteRelay<Service> {
        .init()
    }
    
    public let id : UUID = .init()
    
    var service: Service
    
    var lifecycle: GraniteLifecycle = .none
    
    fileprivate var isSilenced: Bool = false
    fileprivate var pendingUpdates: Bool = false
    
    internal var reducers: [AnyReducerContainer] = []
    internal var cancellables = Set<AnyCancellable>()
    
    fileprivate var kind: GraniteRelayKind
    fileprivate var isDiscoverable: Bool
    
    init(isDiscoverable: Bool = false) {
        self.kind = .offline
        self.isDiscoverable = isDiscoverable
        
        Prospector.shared.currentNode?.addChild(id: self.id, label: String(reflecting: Service.self), type: .relay)
        Prospector.shared.push(id: self.id, .relay)
        service = Service()
        setup()
        Prospector.shared.pop(.relay)
    }
    
    deinit {
        guard isDiscoverable else {
            removeObservers()
            return
        }
        
        removeObservers()
    }
    
    public func update(_ state: Service.GenericGraniteCenter.GenericGraniteState) {
        guard let store = service.center.findStore() else { return }
        store.wrappedValue = state
    }
    
    func setup() {
        
        bind()
        observe()
    }
    
    func bind() {
            
        let events = self.findCompileableEvents()
        
        self.reducers = events.flatMap { $0.compile(self, properties: .init(isOnline: self.kind == .online)) }
    }
    
    func observe() {
        guard let store = service.center.findStore() else { return }
        guard let changeSignal = (store.willChange as? GraniteSignal.Payload<Service.GenericGraniteCenter.GenericGraniteState>) else {
            return
        }
        
        changeSignal += { [weak self] state in
            DispatchQueue.main.async {
                if self?.isSilenced == false {
                    self?.objectWillChange.send()
                } else {
                    self?.pendingUpdates = true
                }
            }
        }
        
        guard isDiscoverable else { return }
        
        self.lifecycle = .attached
        
    }
    
    public func awake() {
        isSilenced = false
        
        if pendingUpdates {
            pendingUpdates = false
            
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange.send()
            }
        }
    }
    
    public func silence() {
        isSilenced = true
    }
    
    public func persistStateChanges() {
        service.locate?.command.persistStateChanges()
    }
    
    public func notify(_ reducerType: AnyGraniteReducer.Type, payload: AnyGranitePayload?) {
        service.locate?.command.notify(reducerType, payload: payload)
    }
}

//MARK: Network sharing
extension GraniteRelay {
    
}

extension GraniteRelay {
    public func getState() -> AnyGraniteState {
        return service.center.state
    }
    
    public func setState(_ state: AnyGraniteState) {
        guard let newState = state as? Service.GenericGraniteCenter.GenericGraniteState else { return }
        
        self.update(newState)
    }
}

extension GraniteRelay {
    public func didRemoveObservers() {
        
    }
}

//TODO: Granite relay network is not syncing states