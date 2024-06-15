//
//  GranitePipelineState.swift
//
//
//  Created by PEXAVC on 6/15/24.
//  Copyright © 2024 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import CoreGraphics
import Metal

public class GranitePipelineState {
    unowned let context: GraniteScene

    public var commandBuffer: MTLCommandBuffer

    public var originalInputSize: CGSize = .zero

    public var currentInputSize: CGSize = .zero

    public var auxiliaryData = [String: Any]()

    public init?(context: GraniteScene) {
        guard let buffer = context.queue.makeCommandBuffer() else {
            return nil
        }

        self.context = context
        self.commandBuffer = buffer
    }

    public func synchronize(resource: MTLResource) {
        #if os(OSX)
        let encoder = commandBuffer.makeBlitCommandEncoder()
        encoder?.synchronize(resource: resource)
        encoder?.endEncoding()
        #endif
    }

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        guard let buffer = context.queue.makeCommandBuffer() else {
            return
        }

        commandBuffer = buffer
    }

}
