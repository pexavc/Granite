//
//  Prospector.Signals.swift
//  Granite
//
//  Created by PEXAVC on 01/02/22.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation

//TODO: shared signal should be used for prospecting component tree outside of the scope of the applicatoin main -> utility threads, while maintaining accuracy/consistency
extension Prospector {
    static var id : UUID {
        if let id = Storage.shared.value(at: Storage.ProspectorIdentifierKey(id: String(describing: self), keyPath: \Self.self)) as? UUID {
            return id
        }
        else {
            let id = UUID()
            Storage.shared.setValue(id, at: Storage.ProspectorIdentifierKey(id: String(describing: self), keyPath: \Self.self))
            return id
        }
    }
    
    static var idSync : UUID {
        if let id = Storage.shared.value(at: Storage.ProspectorIdentifierKey(id: "\(Self.self)"/*String(describing: self)*/, keyPath: \Self.self)) as? UUID {
            return id
        }
        else {
            let id = UUID()
            Storage.shared.setValue(id, at: Storage.ProspectorIdentifierKey(id: "\(Self.self)"/*String(describing: self)*/, keyPath: \Self.self))
            return id
        }
    }
    
    public var valueSignal : GraniteSignal.Payload<GranitePayload?> {
        Storage.shared.value(at: Storage.ProspectorSignalIdentifierKey(id: Prospector.id, keyPath: \Prospector.valueSignal)) {
            GraniteSignal.Payload<GranitePayload?>()
        }
    }
    
    public var syncGraniteSignal : GraniteSignal.Payload<GranitePayload?> {
        Storage.shared.value(at: Storage.ProspectorSignalIdentifierKey(id: Prospector.id, keyPath: \Prospector.syncGraniteSignal)) {
            GraniteSignal.Payload<GranitePayload?>()
        }
    }
    
    public func send(_ payload: GranitePayload?, sync: Bool = true) {
        if sync {
            syncGraniteSignal.send(payload)
        } else {
            valueSignal.send(payload)
        }
    }
}
