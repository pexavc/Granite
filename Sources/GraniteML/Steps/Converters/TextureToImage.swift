import Foundation
import Metal

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public struct TextureToImage: GraniteStep {
    public typealias Input = MTLTexture
    public typealias Output = GraniteMLImage
    
    public init() {
        
    }
    
    public func execute(input: MTLTexture, state: GranitePipelineState) throws -> GraniteMLImage? {
        state.synchronize(resource: input)
        state.insertCommandBufferExecutionBoundary()
          
        guard let cgImage = CGImage.fromTexture(input) else {
            throw PipelineRuntimeError.genericError(self, "Cannot convert image to texture")
        }

        return GraniteMLImage(cgImage: cgImage)
    }
    
}
