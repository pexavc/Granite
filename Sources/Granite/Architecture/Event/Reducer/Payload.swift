//
//  Payload.swift
//  Granite
//
//  Created by PEXAVC on 12/8/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

//TODO: seperate GranitePayload from Payload's wrapper? it will look cleaner if it can be reused maybe for other types of payloads that aren't necesserily reducer specific
import Foundation
import SwiftUI

public protocol AnyGranitePayload {
    func update(_ payload: AnyGranitePayload?)
    var asGranitePayload: GranitePayload? { get }
}

public protocol GranitePayload: AnyGranitePayload {
    
}

extension GranitePayload {
    public func update(_ payload: AnyGranitePayload?) {}
    public var asGranitePayload: GranitePayload? { return nil }
}

public struct EmptyGranitePayload: GranitePayload {
    
}

public protocol GraniteModel: Equatable, Codable, Decodable, GranitePayload {
    
}

public class PayloadContainer {
    var value: GranitePayload?
    init(_ value: GranitePayload? = nil) {
        self.value = value
    }
    
    required init() {
        value = nil
    }
}

@propertyWrapper
public struct Payload<Payload: GranitePayload> : DynamicProperty {
    public let id: UUID = .init()

    public var wrappedValue : Payload? {
        get {
            container.value as? Payload
        }
        mutating set {
            container.value = newValue
        }
    }
    
    public var container : PayloadContainer

    public init() {
        container = .init()
    }
    
}

extension Payload: AnyGranitePayload {
    public func update(_ payload: AnyGranitePayload?) {
        guard payload != nil else { return }
        self.container.value = payload as? Payload
    }
    
    public var asGranitePayload: GranitePayload? {
        return self.container.value
    }
}
