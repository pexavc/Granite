//
//  GraniteState.swift
//  Granite
//
//  Created by PEXAVC on 12/10/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

public protocol AnyGraniteState {
    
}

public protocol GraniteState: AnyGraniteState, Findable, GraniteModel {
    init()
}

public enum GraniteSignalError: Error {
    case test
}
