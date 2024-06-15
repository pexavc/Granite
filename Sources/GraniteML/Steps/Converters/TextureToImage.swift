//
//  TextureToImage.swift
//
//
//  Created by PEXAVC on 6/15/24.
//  Copyright © 2024 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import Metal

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public struct TextureToImage: GraniteStep {
    public typealias Input = MTLTexture
    public typealias Output = GraniteImage

    public init() {

    }

    public func execute(input: MTLTexture, state: GranitePipelineState) throws -> GraniteImage? {
        state.synchronize(resource: input)
        state.insertCommandBufferExecutionBoundary()

        guard let cgImage = CGImage.fromTexture(input) else {
            throw PipelineRuntimeError.genericError(self, "Cannot convert image to texture")
        }

        return GraniteImage(cgImage: cgImage)
    }

}
