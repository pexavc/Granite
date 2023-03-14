//
//  AnyCancellable.swift
//  Granite
//
//  Created by PEXAVC on 12/8/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import Combine

/*
 Helpful extension for Combine's cancellables to store into
 GraniteStates
*/
extension AnyCancellable {
    public func store<State : GraniteState>(in store : GraniteStore<State>) {
        self.store(in: &store.cancellables)
    }
}
