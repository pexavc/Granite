//
//  Event.swift
//  Granite
//
//  Created by PEXAVC on 01/02/22.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI

public enum Forwarding: String {
    case before
    case after
    case none
}

public enum Lifecycle: String {
    case onAppear
    case onDisappear
    case none
}

public protocol AnyEvent: Bindable {
    var forwarding: Forwarding { get }
    var lifecycle: Lifecycle { get }
    var signal: GraniteSignal.Payload<GranitePayload?> { get }
    var attachSignal: GraniteSignal.Payload<GranitePayload?> { get }
    var intermediateSignal: GraniteSignal.Payload<GranitePayload?> { get }
}

protocol CompileableEvent: Bindable {
    func compile(_ coordinator: Director, properties: CompileableEventProperties) -> [AnyReducerContainer]
}

struct CompileableEventProperties {
    var isOnline: Bool
    
    static var empty: CompileableEventProperties {
        return .init(isOnline: false)
    }
}

@propertyWrapper
public struct Event<Executable: EventExecutable>: AnyEvent {
    enum Kind {
        case keypath
        case forwarding
        case timed
        case basic
    }
    public let id: UUID = .init()

    public var wrappedValue : Executable {
        get {
            expedition
        }
        mutating set {
            expedition = newValue
        }
    }
    
    public var expedition: Executable
    public let forwarding: Forwarding
    public let lifecycle: Lifecycle
    
    public let intermediateSignal: GraniteSignal.Payload<GranitePayload?> = .init()
    
    public var signal: GraniteSignal.Payload<GranitePayload?> {
        expedition.signal
    }
    public var attachSignal: GraniteSignal.Payload<GranitePayload?> {
        expedition.attachSignal
    }
    
    var kind: Kind
    var interval: Double = 0.0
    
    public init(_ forwarding: Forwarding) {
        self.expedition = .init()
        self.forwarding = forwarding
        lifecycle = .none
        kind = .forwarding
    }
    
    public init(interval: Double) {
        self.expedition = .init()
        self.forwarding = .after
        self.interval = interval
        lifecycle = .none
        kind = .timed
    }
    
    public init(_ lifecycle: Lifecycle = .none) {
        self.expedition = .init()
        self.forwarding = .none
        self.lifecycle = lifecycle
        kind = .basic
    }
    
}

extension CompileableEvent {
    func compile(_ coordinator: Director) -> [AnyReducerContainer] {
        return compile(coordinator, properties: .empty)
    }
}

extension Event: CompileableEvent {
    //TODO: profile
    func compile(_ coordinator: Director, properties: CompileableEventProperties) -> [AnyReducerContainer] {
        let container: ReducerContainer<Executable>
        
        switch kind {
        case .timed:
            container = .init(expedition, isTimed: interval > 0.0, interval: interval, isOnline: properties.isOnline)
        case .forwarding, .basic, .keypath:
            container = .init(expedition, isOnline: properties.isOnline)
            
        }
        
        container.setup(coordinator)
        
        var containers: [AnyReducerContainer] = [container]
        
        
        //TODO: allow expeditions to host events within them
        //Caveats, slow component boot times and state component mismatch
        for event in expedition.events {
            guard let compileableEvent = event as? CompileableEvent else {
                continue
            }
            containers += compileableEvent.compile(coordinator, properties: properties)

            //For event forwarding
            guard event.forwarding != .none else {
                continue
            }
            if container.sideEffects[event.forwarding] == nil {
                container.sideEffects[event.forwarding] = [event.signal]
            } else {
                container.sideEffects[event.forwarding]?.append(event.signal)
            }
        }
        
        return containers
    }
}
