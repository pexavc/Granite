//
//  File.swift
//  
//
//  Created by PEXAVC on 4/30/23.
//

import Foundation
import SwiftUI

extension View {
    public func onTapIf(_ condition: Bool, _ action: (@escaping () -> Void)) -> some View {
        Group {
            if condition {
                self.onTapGesture {
                    action()
                }
            } else {
                self
            }
        }
    }
}
