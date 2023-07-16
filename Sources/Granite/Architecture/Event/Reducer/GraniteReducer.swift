//
//  GraniteReducer.swift
//  Granite
//
//  Created by PEXAVC on 8/8/20.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CoreData

extension Storage {
    struct ExpeditionIdentifierKey : Hashable {
        let id : String
        let keyPath: AnyKeyPath
    }
    
    struct EventSignalIdentifierKey : Hashable {
        let id : UUID
        let keyPath : AnyKeyPath
    }
    
}

public protocol AnyGraniteReducer: Findable {
    var notifiable: Bool { get }
}


/*
 TODO: MAJOR
 - Online services cannot pass events passed 2 reducers
 - If there is a referenced response reducer it needs to be called or removed
 state changes in the callee will not persist
 
 - Payload property wrapper not allowing state changes to persist. it's as if
 it blocks all the other signals in the online service's stack
 -- a workaround is making a reducer alternative where payload is a typealias
 --- this does solve the necessary optional on payloads, might be a better
 overall
 
 - even though in online mode, the latest changes are added, the initial reducer
 in a response chain is the final state that is persisted...
 
 - need to look at attaching events for "after" events.
 
 
 // 12-21-22
 // ALL OF THE ABOVE HAVE BEEN ADDRESSED WITH A SIMPLE UPDATE
 // all signals are not shared except for one, it is called syncSignal below.
 // it is only fired at the end of the reducer to syncStates with all services
 // for some reason doing it this way made it more reliable. Since the id
 // needed to be shared via 'Self.self' not 'String(describing: self)'
 // most likely it was intializing a fresh signal before the signal's observer
 // was prepared, and before the signal sent the notification to its subscribers.
 */

//TODO: This is not friendly for stored Events in Components that have multiple instances
//For each instance shares the observer child that is to a singular signal for example
//when one deinits, all the other signals will not observe
//or, only the latest will
//these need to somehow be copied and removed per instance rather
//then using the storage to pull the same one based on this protocol description
extension AnyGraniteReducer {
    public var id : UUID {
        if let id = Storage.shared.value(at: Storage.ExpeditionIdentifierKey(id: String(describing: self), keyPath: \Self.self)) as? UUID {
            return id
        }
        else {
            let id = UUID()
            Storage.shared.setValue(id, at: Storage.ExpeditionIdentifierKey(id: String(describing: self), keyPath: \Self.self))
            return id
        }
    }
    
    public var idSync : UUID {
        if let id = Storage.shared.value(at: Storage.ExpeditionIdentifierKey(id: "\(Self.self)"/*String(describing: self)*/, keyPath: \Self.self)) as? UUID {
            return id
        }
        else {
            let id = UUID()
            Storage.shared.setValue(id, at: Storage.ExpeditionIdentifierKey(id: "\(Self.self)"/*String(describing: self)*/, keyPath: \Self.self))
            return id
        }
    }
    
    public var valueSignal : GraniteSignal.Payload<GranitePayload?> {
        Storage.shared.value(at: Storage.EventSignalIdentifierKey(id: self.id, keyPath: \AnyGraniteReducer.valueSignal)) {
            GraniteSignal.Payload<GranitePayload?>()
        }
    }
    
    public var attachGraniteSignal : GraniteSignal.Payload<GranitePayload?> {
        Storage.shared.value(at: Storage.EventSignalIdentifierKey(id: self.id, keyPath: \AnyGraniteReducer.attachGraniteSignal)) {
            GraniteSignal.Payload<GranitePayload?>()
        }
    }
    
    public var syncGraniteSignal : GraniteSignal.Payload<AnyGraniteState> {
        Storage.shared.value(at: Storage.EventSignalIdentifierKey(id: self.idSync, keyPath: \AnyGraniteReducer.syncGraniteSignal)) {
            GraniteSignal.Payload<AnyGraniteState>()
        }
    }
    
    public var nudgeNotifyGraniteSignal : GraniteSignal.Payload<GranitePayload> {
        Storage.shared.value(at: Storage.EventSignalIdentifierKey(id: self.id, keyPath: \AnyGraniteReducer.nudgeNotifyGraniteSignal)) {
            GraniteSignal.Payload<GranitePayload>()
        }
    }
    
    public func send() {
        valueSignal.send(nil)
    }
    
    public func send(_ payload: GranitePayload) {
        valueSignal.send(payload)
    }
    
    public func attach(_ payload: GranitePayload) {
        attachGraniteSignal.send(payload)
    }
    
    public var notifiable: Bool {
        false
    }
    
    public var offline: Bool {
        false
    }
}

public protocol GraniteReducer: AnyGraniteReducer {
    typealias Reducer = GraniteReducerExecutable<Self>
    
    associatedtype Center: GraniteCenter
    associatedtype Metadata: GranitePayload = EmptyGranitePayload
    
    func reduce(state: inout Center.GenericGraniteState)
    func reduce(state: inout Center.GenericGraniteState, payload: Metadata)
    
    var thread: DispatchQueue? { get }
    
    init()
}

extension GraniteReducer {
    public var thread: DispatchQueue? {
        nil
    }
}

extension GraniteReducer {
    public func reduce(state: inout Center.GenericGraniteState) {}
    public func reduce(state: inout Center.GenericGraniteState, payload: Metadata) {}
}

public protocol EventExecutable {
    var label : String { get }
    var reducerType : AnyGraniteReducer.Type { get }
    var signal : GraniteSignal.Payload<GranitePayload?> { get }
    var intermediateSignal : GraniteSignal.Payload<GranitePayload?> { get }
    var attachSignal : GraniteSignal.Payload<GranitePayload?> { get }
    var syncSignal : GraniteSignal.Payload<AnyGraniteState> { get }
    var payload: AnyGranitePayload? { get set }
    var events: [AnyEvent] { get }
    var isNotifiable: Bool { get }
    var isOffline: Bool { get }
    
    var thread: DispatchQueue? { get }
    
    func setOnline(_ isOnline: Bool)
    
    func observe()
    
    func send()
    func send(_ payload: GranitePayload)
    
    func attach(_ payload: GranitePayload)
    func update(_ payload: GranitePayload?)
    func execute(_ state: AnyGraniteState?) -> AnyGraniteState
    init()
}

open class GraniteReducerExecutable<Expedition: GraniteReducer>: EventExecutable {
    private lazy var expedition: Expedition = {
        .init()
    }()
    
    public let id: UUID = .init()
    
    public var label: String {
        "\(Expedition.self)"
    }
    
    public var reducerType: AnyGraniteReducer.Type {
        Expedition.self
    }
    
    private var isOnline: Bool = false
    
    public var signal : GraniteSignal.Payload<GranitePayload?> {
        valueSignal
    }
    
    public var attachSignal : GraniteSignal.Payload<GranitePayload?> {
        if isOnline {
            return synchronousGraniteSignalValue
        } else {
            return valueSignal
        }
    }
    
    public var syncSignal : GraniteSignal.Payload<AnyGraniteState> {
        expedition.syncGraniteSignal
    }
    
    public var thread: DispatchQueue? {
        expedition.thread
    }
    
    public var valueSignal : GraniteSignal.Payload<GranitePayload?> = .init()
     
    public var intermediateSignal : GraniteSignal.Payload<GranitePayload?> = .init()
    
    public var synchronousGraniteSignalValue : GraniteSignal.Payload<GranitePayload?> {
        expedition.valueSignal
    }
    
    public var synchronousAttachGraniteSignalValue : GraniteSignal.Payload<GranitePayload?> {
        expedition.attachGraniteSignal
    }
    
    public var payload : AnyGranitePayload?
    public var events : [AnyEvent] {
        expedition.findEvents()
    }
    public var isNotifiable : Bool {
        expedition.notifiable
    }
    public var isOffline: Bool {
        expedition.offline
    }
    
    required public init() {
        //let expedition = Expedition()
        //self.expedition = expedition
        self.payload = expedition.findPayload()
        //self.events = expedition.findEvents()
        //self.isNotifiable = expedition.notifiable
    }
    
    public func execute(_ state: AnyGraniteState?) -> AnyGraniteState {
        var mutableState = (state as? Expedition.Center.GenericGraniteState) ?? Expedition.Center.GenericGraniteState()
        
        
        if let payload = payload as? Expedition.Metadata {
            expedition.reduce(state: &mutableState, payload: payload)
        } else {
            expedition.reduce(state: &mutableState)
        }
        
        return mutableState
    }
    
    public func setOnline(_ isOnline: Bool) {
        self.isOnline = isOnline
    }
    
    public func update(_ payload: GranitePayload?) {
        //TODO: make sure it is okay that a nil check is not required
        //Otherwise in notify requests and repetitive subsequent ones
        //the last payload persists
        if self.payload == nil {
            //Covers typealias alternative
            self.payload = payload
        }
        //Covers property wrapper case
        self.payload?.update(payload)
    }
    
    public func observe() {
        expedition.nudgeNotifyGraniteSignal += { [weak self] value in
            self?.send(value)
        }
    }
    
    public func send() {
        signal.send(nil)
    }
    
    public func send(_ payload: GranitePayload) {
        update(payload)
        signal.send(payload)
    }
    
    public func attach(_ payload: GranitePayload) {
        update(payload)
    }
}
