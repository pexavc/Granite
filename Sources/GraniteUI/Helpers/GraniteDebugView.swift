//
//  GraniteDebug.swift
//  GraniteUI
//
//  Created by PEXAVC on 2/26/21.
//

import Foundation
import SwiftUI

public struct GraniteDebugView: View {
    
    public init(_ message: String) {
        print("[GraniteDebugView] \(message)")
    }
    
    public var body: some View {
        EmptyView().hidden()
    }
}
