//
//  Bindable.swift
//  Granite
//
//  Created by PEXAVC on 12/12/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation

public protocol Inspectable {
    var id: UUID { get }
    func didRemoveObservers() -> Void
}

extension Inspectable {
    func removeObservers() {
        Prospector.shared.node(for: id)?.remove()
        didRemoveObservers()
    }
    
    func withObservation(_ id: UUID, _ block: (() -> Void)) {
        
    }
}
