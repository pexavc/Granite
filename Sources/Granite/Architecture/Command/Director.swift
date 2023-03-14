//
//  Director.swift
//  Granite
//
//  Created by PEXAVC on 07/04/22.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation

/*
 Allows ReducerContainers to safely update state of their host
 GraniteCommands'
*/
protocol Director: AnyObject {
    var lifecycle: GraniteLifecycle { get set }
    var reducers: [AnyReducerContainer] { get set }
    func persistStateChanges()
    func getState() -> AnyGraniteState
    func setState(_ state: AnyGraniteState)
    func notify(_ reducerType: AnyGraniteReducer.Type, payload: AnyGranitePayload?)
}

extension Director {
    var isAvailable: Bool {
        lifecycle.isAvailable
    }
}
