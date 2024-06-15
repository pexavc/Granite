//
//  GraniteStep.swift
//
//
//  Created by PEXAVC on 6/15/24.
//  Copyright © 2024 Stoic Collective, LLC. All rights reserved.
//

import Foundation

public protocol GraniteStep: GranitePipe {
    func invalidate(context: GraniteScene)
}

extension GraniteStep {
    public func invalidate(context: GraniteScene) {}
}

extension GranitePipe {
    public func add<T1: GraniteStep>(_ input: T1) -> GranitePipeline<T1.Output> {
        return GranitePipeline(executables: [self, input], scene: GraniteScene())
    }
}
