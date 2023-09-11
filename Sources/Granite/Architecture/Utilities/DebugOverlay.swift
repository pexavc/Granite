//
//  File.swift
//  
//
//  Created by PEXAVC on 9/11/23.
//

import Foundation
import SwiftUI

public struct DebugOverlayView: View {
    public var body: some View {
        VStack {
            HStack {
                Spacer()
                
                Button {
                    Prospector.shared.print()
                } label: {
                    Text("Print Nodes")
                }
                .buttonStyle(.plain)
            }
        }
    }
}


public extension View {
    func graniteDebugOverlay() -> some View {
        ZStack {
            self
            DebugOverlayView()
        }
    }
}
