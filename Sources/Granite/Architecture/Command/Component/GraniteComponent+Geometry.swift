//
//  GraniteComponent+Geometry.swift
//  Granite
//
//  Created by PEXAVC on 12/8/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI

/*
 Same behavior as lifecycleView except the State if hosting
 a @Geometry variable, will be updated with the Component's
 first GemeotryProxy.
*/
extension GraniteComponent {
    func geometryView(_ geo: AnyGeometry?) -> some View {
        lifecycle(view)
            .background(
                GeometryReader { proxy in
                    Color
                        .clear
                        .onAppear {
                        geo?.update(proxy)
                    }
                })
    }
}
