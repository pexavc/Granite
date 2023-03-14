//
//  Bindable.swift
//  Granite
//
//  Created by PEXAVC on 12/12/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

public protocol Findable {
    
}

extension Findable {
    func findCommandSetup() -> (events: [AnyEvent], notifies: [AnyNotify], store: AnyGraniteStore?) {
        var events: [AnyEvent] = []
        var notifies: [AnyNotify] = []
        var store: AnyGraniteStore? = nil
        
        let mirror = Mirror(reflecting: self)
        let children = mirror.children
        
        for child in children {
            if let event = child.value as? AnyEvent {
                events.append(event)
            }
            
            if let notify = child.value as? AnyNotify {
                notifies.append(notify)
            }
            
            if let anyStore = child.value as? AnyGraniteStore {
                store = anyStore
            }
        }
        
        return (events, notifies, store)
    }
    
    public func findRelays() -> [AnyRelay] {
        let mirror = Mirror(reflecting: self)
        let children = mirror.children

        let events = children.filter { $0.value as? AnyRelay != nil }.compactMap { $0.value as? AnyRelay }

        return events
    }
    
    func findEvents() -> [AnyEvent] {
        let mirror = Mirror(reflecting: self)
        let children = mirror.children

        //TODO: I do not think, filter is reqd. w/ compactMap
        var events = children.filter { $0.value as? AnyEvent != nil }.compactMap { $0.value as? AnyEvent }
        
        return events
    }
    
    func findCompileableEvents() -> [CompileableEvent] {
        let mirror = Mirror(reflecting: self)
        let children = mirror.children

        var events = children.filter { $0.value as? CompileableEvent != nil }.compactMap { $0.value as? CompileableEvent }
        
        return events
    }
    
    func findNotifies() -> [AnyNotify] {
        let mirror = Mirror(reflecting: self)
        let children = mirror.children

        var events = children.filter { $0.value as? AnyNotify != nil }.compactMap { $0.value as? AnyNotify }
        
        return events
    }
    
    public func findGeometry() -> AnyGeometry? {
        let mirror = Mirror(reflecting: self)
        let children = mirror.children

        return children.first { $0.value as? AnyGeometry != nil }?.value as? AnyGeometry
    }
    
    public func findPayload() -> AnyGranitePayload? {
        let mirror = Mirror(reflecting: self)
        let children = mirror.children

        return children.first { $0.value as? AnyGranitePayload != nil }?.value as? AnyGranitePayload
    }
}
