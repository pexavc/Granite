//
//  GraniteService.swift
//  Granite
//
//  Created by PEXAVC on 12/12/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// MARK: GraniteService
//
public protocol GraniteService {
    associatedtype GenericGraniteCenter: GraniteCenter
    var center: GenericGraniteCenter { get set }
    
    var isLoaded: Bool { get }
    
    init()
}

extension GraniteService {
    public var didLoad: GraniteSignal {
        locate?.command.center.findStore()?.didLoad ?? .init()
    }
    
    public var isLoaded: Bool {
        locate?.command.isLoaded == true
    }
    
    public func preload() {
        locate?.command.center.findStore()?.preload()
    }
    
    public func silence(viewUpdatesOnly updateView: Bool = false) {
        locate?.command.center.findStore()?.silence(viewUpdatesOnly: updateView)
    }
    
    public func awake(viewUpdatesOnly updateView: Bool = false) {
        locate?.command.center.findStore()?.awake(viewUpdatesOnly: updateView)
    }
}

extension GraniteService {
    public var locate: Service<Self.GenericGraniteCenter>? {

        let mirror = Mirror(reflecting: self)
        let children = mirror.children

        guard let child = children.first(where: { $0.value as? Service<Self.GenericGraniteCenter> != nil }) else {
            return nil
        }
        
        return child.value as? Service<Self.GenericGraniteCenter>
    }

    public var state: Self.GenericGraniteCenter.GenericGraniteState {
        locate?.command.center.state ?? .init()
    }
    
    public var _state: Binding<Self.GenericGraniteCenter.GenericGraniteState> {
        return Binding<Self.GenericGraniteCenter.GenericGraniteState>(
            get: {
                self.state
            },
            set: {
                self.locate?.command.center.state = $0
            }
        )
    }
}
