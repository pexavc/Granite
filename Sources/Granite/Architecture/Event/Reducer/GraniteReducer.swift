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

//TODO: This is not friendly for stored Events in Components that have multiple instances
//For each instance shares the observer child that is to a singular signal for example
//when one deinits, all the other signals will not observe
//or, only the latest will
//these need to somehow be copied and removed per instance rather
//then using the storage to pull the same one based on this protocol description
//
//08/2023 the above may have been resolved with recent sync changes?
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
        if let id = Storage.shared.value(at: Storage.ExpeditionIdentifierKey(id: "\(Self.self)" /*String(describing: self)*/, keyPath: \Self.idSync)) as? UUID {
            return id
        }
        else {
            let id = UUID()
            Storage.shared.setValue(id, at: Storage.ExpeditionIdentifierKey(id: "\(Self.self)"/*String(describing: self)*/, keyPath: \Self.idSync))
            return id
        }
    }
    
    public var valueSignal : GraniteSignal.Payload<GranitePayload?> {
        Storage.shared.value(at: Storage.EventSignalIdentifierKey(id: self.id, keyPath: \AnyGraniteReducer.valueSignal)) {
            GraniteSignal.Payload<GranitePayload?>()
        }
    }
    
    public var nudgeNotifyGraniteSignal : GraniteSignal.Payload<GranitePayload> {
        Storage.shared.value(at: Storage.EventSignalIdentifierKey(id: self.id, keyPath: \AnyGraniteReducer.nudgeNotifyGraniteSignal)) {
            GraniteSignal.Payload<GranitePayload>()
        }
    }
    
    //shared (signals ui receivers)
    public var broadcast : GraniteSignal.Payload<GranitePayload?> {
        Storage.shared.value(at: Storage.EventSignalIdentifierKey(id: self.idSync, keyPath: \AnyGraniteReducer.broadcast)) {
            GraniteSignal.Payload<GranitePayload?>()
        }
    }
    
    public func send() {
        valueSignal.send(nil)
    }
    
    public func send(_ payload: GranitePayload) {
        valueSignal.send(payload)
    }
    
    public var notifiable: Bool {
        false
    }
}

public enum GraniteReducerBehavior {
    case task(TaskPriority)
    case none
    
    var isTask: Bool {
        switch self {
        case .task:
            return true
        default:
            return false
        }
    }
}

public enum GraniteReducerInteraction {
    case debounce(Double)
    case throttle(Double)
    case basic
}

public protocol GraniteReducer: AnyGraniteReducer {
    typealias Reducer = GraniteReducerExecutable<Self>
    
    associatedtype Center: GraniteCenter
    associatedtype Metadata: GranitePayload = EmptyGranitePayload
    
    func reduce(state: inout Center.GenericGraniteState)
    func reduce(state: inout Center.GenericGraniteState) async
    func reduce(state: inout Center.GenericGraniteState, payload: Metadata)
    func reduce(state: inout Center.GenericGraniteState, payload: Metadata) async
    
    var thread: DispatchQueue? { get }
    var behavior: GraniteReducerBehavior { get }
    
    init()
}

extension GraniteReducer {
    public var thread: DispatchQueue? {
        nil
    }
    
    public var behavior: GraniteReducerBehavior {
        .none
    }
    
    //instanced version of broadcast
    public var beam : GraniteSignal.Payload<GranitePayload?> {
        Storage.shared.value(at: "\(String(describing: self))_beam") {
            GraniteSignal.Payload<GranitePayload?>()
        }
    }
}

extension GraniteReducer {
    public func reduce(state: inout Center.GenericGraniteState) {}
    public func reduce(state: inout Center.GenericGraniteState) async {}
    public func reduce(state: inout Center.GenericGraniteState, payload: Metadata) {}
    public func reduce(state: inout Center.GenericGraniteState, payload: Metadata) async {}
}

public protocol EventExecutable {
    var label : String { get }
    var reducerType : AnyGraniteReducer.Type { get }
    var signal : GraniteSignal.Payload<GranitePayload?> { get }
    var intermediateSignal : GraniteSignal.Payload<GranitePayload?> { get }
    var beamSignal: GraniteSignal.Payload<GranitePayload?> { get }
    
    var payload: AnyGranitePayload? { get set }
    var events: [AnyEvent] { get }
    var isNotifiable: Bool { get }
    var behavior: GraniteReducerBehavior { get }
    var interaction: GraniteReducerInteraction { get }
    
    var thread: DispatchQueue? { get }
    
    func setOnline(_ isOnline: Bool)
    
    func observe()
    
    func send()
    func send(_ payload: GranitePayload)
    
    func update(_ payload: GranitePayload?)
    func execute(_ state: AnyGraniteState?) -> AnyGraniteState
    func executeAsync(_ state: AnyGraniteState?) async -> AnyGraniteState
    init()
    init(debounce interval: Double)
    init(throttle interval: Double)
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
    
    public var thread: DispatchQueue? {
        expedition.thread
    }
    
    public var valueSignal : GraniteSignal.Payload<GranitePayload?> = .init()
     
    public var intermediateSignal : GraniteSignal.Payload<GranitePayload?> = .init()
    
    public var beamSignal: GraniteSignal.Payload<GranitePayload?> {
        expedition.beam
    }
    
    public var synchronousGraniteSignalValue : GraniteSignal.Payload<GranitePayload?> {
        expedition.valueSignal
    }
    
    public var payload : AnyGranitePayload?
    public var events : [AnyEvent] {
        expedition.findEvents()
    }
    public var isNotifiable : Bool {
        expedition.notifiable
    }
    
    public var behavior: GraniteReducerBehavior {
        expedition.behavior
    }
    
    public var interaction: GraniteReducerInteraction
    
    public enum ListenKind {
        case broadcast
        case beam
    }
    
    //instanced signals (Receiver)
    internal var beamCancellables: Set<AnyCancellable> = .init()
    //shared signals (Receiver)
    internal var broadcastCancellables: Set<AnyCancellable> = .init()
    
    required public init() {
        self.interaction = .basic
        self.payload = expedition.findPayload()
    }
    
    required public init(debounce interval: Double) {
        self.interaction = .debounce(interval)
        self.payload = expedition.findPayload()
    }
    
    required public init(throttle interval: Double) {
        self.interaction = .throttle(interval)
        self.payload = expedition.findPayload()
    }
    
    deinit {
        beamCancellables.forEach { $0.cancel() }
        beamCancellables.removeAll()
        broadcastCancellables.forEach { $0.cancel() }
        broadcastCancellables.removeAll()
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
    
    public func executeAsync(_ state: AnyGraniteState?) async -> AnyGraniteState {
        var mutableState = (state as? Expedition.Center.GenericGraniteState) ?? Expedition.Center.GenericGraniteState()
        
        if let payload = payload as? Expedition.Metadata {
            await expedition.reduce(state: &mutableState, payload: payload)
        } else {
            await expedition.reduce(state: &mutableState)
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
    
    @discardableResult
    public func listen(_ kind: ListenKind = .beam, _ handler: @escaping (GranitePayload?) -> Void ) -> Self {
        switch kind {
        case .beam:
            beamCancellables.forEach { $0.cancel() }
            beamCancellables.removeAll()
            expedition.beam.removeObservers()
            beamCancellables.insert(expedition.beam += handler)
        case .broadcast:
            broadcastCancellables.forEach { $0.cancel() }
            broadcastCancellables.removeAll()
            expedition.broadcast.removeObservers()
            broadcastCancellables.insert(expedition.broadcast += handler)
        }
        return self
    }
    
    public func send() {
        self.payload?.clear()
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
