//
//  GraniteComponent+Empty.swift
//  
//
//  Created by PEXAVC on 2/21/23.
//

import Foundation
import SwiftUI

public struct GraniteEmptyState {
    let text: String
    let backgroundColor: Color
}

public struct GraniteEmptyStateViewModifier: ViewModifier {
    
    @Binding var isActive: Bool
    
    let skeletonView: AnyView
    
    init(isActive: Binding<Bool>,
         @ViewBuilder skeletonView: @escaping () -> some View) {
        self._isActive = isActive
        self.skeletonView = AnyView(skeletonView())
    }
    
    public func body(content: Content) -> some View {
        ZStack {
            content
            
            if isActive {
                skeletonView
            }
        }
    }
}

extension View {
    public func graniteEmpty(_ isActive: Binding<Bool>,
                             @ViewBuilder skeletonView: @escaping () -> some View) -> some View {
        return self.modifier(GraniteEmptyStateViewModifier(isActive: isActive,
                                                           skeletonView: skeletonView))
    }
}
