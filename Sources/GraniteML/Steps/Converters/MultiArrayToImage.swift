import Foundation
import Metal
import CoreML

public struct MutliArrayToImage: GraniteStep {
    public typealias Input = Any
    public typealias Output = GraniteMLImage
    
    public init() {
        
    }
    
    public func execute(input: Any, state: GranitePipelineState) throws -> GraniteMLImage? {
        var array : MLMultiArray? = nil
        
        if let input = input as? [String : Any] {
            array = input.values.first as? MLMultiArray
        }
        else if let input = input as? MLMultiArray {
            array = input
        }
        
        guard let cgImage = array?.cgImage(min: -5, max: 5, channel: nil, axes: (2, 3, 4)) else {
            throw PipelineRuntimeError.genericError(self, "Cannot convert mask into CGImage")
        }
        
        #if os(iOS)
        
        return GraniteMLImage(cgImage: cgImage)
        
        #else
        
        return GraniteMLImage(cgImage: cgImage, size: .init(width: cgImage.width, height: cgImage.height))
        #endif
    }
    
}
