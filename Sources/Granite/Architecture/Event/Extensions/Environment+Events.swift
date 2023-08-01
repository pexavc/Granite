//
//  Environment+Events.swift
//  
//
//  Created by PEXAVC on 7/28/23.
//

import Foundation
import SwiftUI

public struct GraniteEventKey: EnvironmentKey {
    public static var defaultValue: EventExecutable? = nil
}

public extension EnvironmentValues {
    var graniteEvent: EventExecutable? {
        get { self[GraniteEventKey.self] }
        set { self[GraniteEventKey.self] = newValue }
    }
}

public extension View {
    func graniteEvent(_ reducer: EventExecutable?) -> some View {
        self
            .environment(\.graniteEvent, reducer)
    }
}
