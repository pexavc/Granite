//
//  ReducerContainer.swift
//  Granite
//
//  Created by PEXAVC on 07/21/22.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import SwiftUI

extension Storage {

    struct ReducerIdentifierKey : Hashable {
        let id : String
        let keyPath: AnyKeyPath
    }
    
}

protocol AnyReducerContainer {
    var id : UUID { get set }
    var label: String { get }
    func setup(_ coordinator: Director)
}

//TODO: MAJOR
//When an @Event is inside a center it cannot be declared in a reducer
//Check @Event var sync: Sync.Reducer (May only be the case if the Relay/Service is in .online mode)
//infinite loop case as well
//
// 01/08/23 which is why we declare @Notify outside of reducers not within..................
//
class ReducerContainer<Event : EventExecutable>: AnyReducerContainer, Prospectable {
    public var id : UUID = .init()
    
    public var label: String {
        reducer?.label ?? ""
    }
    
    weak var coordinator: Director?
    
    var setState: ((AnyGraniteState) -> Void)?
    
    private let reducer: Event?
    var sideEffects: [Forwarding : [GraniteSignal.Payload<GranitePayload?>]] = [:]
    private let isTimed: Bool
    public let interval: Double
    private var timer: DisplayLinkTimer? = nil
    private var isOnline: Bool
    
    var events: [AnyEvent] {
        reducer?.events ?? []
    }
    
    var thread: DispatchQueue {
        .init(label: "\(id)", qos: .background)
    }
    
    init(_ reducer: Event,
                isTimed: Bool = false,
                interval: Double = 0.0,
                isOnline: Bool = false) {
        self.reducer = reducer
        self.isTimed = isTimed
        self.interval = interval
        
        self.isOnline = isOnline
        self.reducer?.setOnline(isOnline)
        
        if isTimed {
            timer = .init()
        }
    }
    
    func setup(_ coordinator: Director) {
        self.coordinator = coordinator
        
        Prospector.shared.currentNode?.addChild(id: self.id, label: String(reflecting: Event.self), type: .event)
        Prospector.shared.push(id: self.id)
        bind()
        observe()
        Prospector.shared.pop()
    }
    
    func bind() {
        guard let reducer = self.reducer else {
            print("Failed to find reducer for container to bind")
            return
        }
        
        reducer.signal.bind("signal")
        reducer.attachSignal.bind("attachSignal")
        
        if isOnline {
            reducer.syncSignal.bind("syncSignal", removeObservers: false)
        }
    }
    
    func observe() {
        guard let reducer = self.reducer else {
            print("Failed to find reducer for container to observe")
            return
        }
        
        reducer.signal += { [weak self] value in
            if let thread = reducer.thread {
                thread.async { [weak self] in
                    self?.commit(value)
                }
            } else {
                self?.commit(value)
            }
        }
        
        reducer.attachSignal += { [weak self] value in
            reducer.update(value)
        }
        
        reducer.syncSignal += { [weak self] value in
            self?.coordinator?.setState(value)
        }
        
        if reducer.isNotifiable {
            reducer.observe()
        }
    }
    
    func commit(_ value: GranitePayload?) {
        reducer?.update(value)
        
        //TODO: this can support the updation of multiple instances of the same component
        //make sure not to allow this timer to run independently in each
        if self.isTimed == true {
            self.timer?.start { [weak self] instance in
                guard self?.coordinator?.isAvailable == true else {
                    instance.stop()
                    self?.timer = nil
                    return
                }
                
                self?.execute()
            }
        } else {
            self.execute()
        }
    }
    
    func execute() {
        
        //TODO: think about the necessity of before
        //it does not feel standard or correct to have
        //
        for signal in (sideEffects[.before] ?? []){
            signal.send(reducer?.payload as? GranitePayload)
        }
        
        //TODO: this CAN be a queue, before it hits an after
        // a basic CS problem
        
        if let newState = self.reducer?.execute(coordinator?.getState()) {
            updateState(newState)
        }
        
//        self.reducer?.findRelays().forEach { relay in
//            relay.detach()
//        }
        
        for signal in (sideEffects[.after] ?? []){
            signal.send(nil)
        }
    }
    
    func updateState(_ newState: AnyGraniteState) {
        if Thread.isMainThread == false {
            //TODO: still haven't proven robustness of this rudimentary threading impl.
            DispatchQueue.main.async { [weak self] in
                self?.coordinator?.setState(newState)
                self?.coordinator?.persistStateChanges()
                
                //TODO: need to allow an option for sync signal to not fire
                //from the reducer itself. allowing a chain of @Event(.afters)
                //to execute until the one's whose final state matters and then
                //can thus, broadcast to peers
                
                self?.thread.async {
                    if self?.isOnline == true {
                        self?.reducer?.syncSignal.send(newState)
                    }
                    
                    if let reducerType = self?.reducer?.reducerType {
                        self?.coordinator?.notify(reducerType, payload: self?.reducer?.payload)
                    }
                }
            }
        } else {
            coordinator?.setState(newState)
            coordinator?.persistStateChanges()
            
            thread.async { [weak self] in
                //TODO: same as above
                if self?.isOnline == true {
                    self?.reducer?.syncSignal.send(newState)
                }
                
                if let reducerType = self?.reducer?.reducerType {
                    self?.coordinator?.notify(reducerType, payload: self?.reducer?.payload)
                }
            }
        }
    }
}
