//
//  Prospector.swift
//  Granite
//
//  Created by PEXAVC on 12/08/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI

@propertyWrapper
final class ThreadSafe<Value> {
    private let queue: DispatchQueue
    private var value: Value

    init(wrappedValue: Value, queue: DispatchQueue) {
        self.queue = queue
        self.value = wrappedValue
    }

    var wrappedValue: Value {
        get { queue.sync { value } }
        set { queue.async(flags: .barrier) { self.value = newValue } }
    }

    func mutate(_ mutation: (inout Value) -> Void) {
        return queue.sync {
            mutation(&value)
        }
    }
}
