//
//  GraniteToggle.swift
//  
//
//  Created by PEXAVC on 7/3/23.
//

import Foundation
import SwiftUI

public struct GraniteToggle: View {
    
    public struct Meta: GranitePayload {
        public var isEnabled: Bool
    }
    
    let reducer: any EventExecutable
    let content: AnyView
    
    public init<E: EventExecutable, Content: View>(_ reducer: E, @ViewBuilder content: @escaping (() -> Content)) {
        self.reducer = reducer
        self.content = AnyView(content())
    }
    
    @State var isEnabled: Bool = false
    
    public var body: some View {
        Toggle(isOn: $isEnabled) {
            content
        }.onChange(of: isEnabled) { newState in
            self.reducer.send(Meta(isEnabled: newState))
        }
    }
}
