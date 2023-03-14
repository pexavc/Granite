//
//  Geometry.swift
//  Granite
//
//  Created by PEXAVC on 12/8/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI

/*
 Container to house a publishable GeomotryProxy for easy
 access in a GraniteState.
*/
public class GeometryProxyContainer: ObservableObject, GraniteModel {
    required public init(from decoder: Decoder) throws {
        value = nil
    }
    
    public static func == (lhs: GeometryProxyContainer, rhs: GeometryProxyContainer) -> Bool {
        lhs.id == rhs.id
    }
    
    public func encode(to encoder: Encoder) throws {
        
    }
    
    public let id: UUID = .init()
    
    @Published var value: GeometryProxy?
    init(_ value: GeometryProxy? = nil) {
        self.value = value
    }
}

/*
 Proxies are updated in GraniteComponent's view build
*/
public protocol AnyGeometry {
    func update(_ proxy: GeometryProxy)
}

@propertyWrapper
public struct Geometry<Proxy: GeometryProxyContainer> : DynamicProperty, GraniteModel {
    public init(from decoder: Decoder) throws {
        proxy = .init(nil)
    }

    public static func == (lhs: Geometry<Proxy>, rhs: Geometry<Proxy>) -> Bool {
        lhs.id == rhs.id
    }

    public func encode(to encoder: Encoder) throws {

    }
    
    public let id: UUID = .init()

    public var wrappedValue : GeometryProxy? {
        get {
            proxy.value
        }
        mutating set {
            proxy.value = newValue
        }
    }
    
    public var proxy : GeometryProxyContainer

    public init() {
        proxy = .init()
    }
    
}

extension Geometry: AnyGeometry {
    public func update(_ proxy: GeometryProxy) {
        self.proxy.value = proxy
    }
}
