//
//  View+Events.swift
//  Granite
//
//  Created by PEXAVC on 12/06/22.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI

//TODO: same for Button classes and other QoL accessors 
extension View {
    public func onTapGesture<S: AnyGraniteReducer>(_ reducer: S) -> some View {
        return self.onTapGesture {
            reducer.send()
        }
    }
    
    public func onTapGesture<S: EventExecutable>(_ reducer: S) -> some View {
        return self.onTapGesture {
            reducer.send()
        }
    }
}
