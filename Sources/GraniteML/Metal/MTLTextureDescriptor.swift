//
//  MTLTextureDescriptor.swift
//
//
//  Created by PEXAVC on 6/15/24.
//  Copyright © 2024 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import Metal

extension MTLTextureDescriptor {
    public static func basicRW(format: MTLPixelFormat, input: MTLTexture) -> MTLTextureDescriptor {
        let outputTextureDescriptor: MTLTextureDescriptor = {
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: format,
                                                                      width: input.width,
                                                                      height: input.height,
                                                                      mipmapped: false)
            descriptor.usage = [.shaderRead, .shaderWrite]
            return descriptor
        }()

        return outputTextureDescriptor
    }
}
