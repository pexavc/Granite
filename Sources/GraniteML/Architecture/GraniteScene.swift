//
//  GraniteScene.swift
//
//
//  Created by PEXAVC on 6/15/24.
//  Copyright © 2024 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import Metal
import MetalPerformanceShaders

public class GraniteScene {

    public let device : MTLDevice

    public let queue : MTLCommandQueue

    public let library : MTLLibrary

    public init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Cannot obtain system default device.")
        }

        guard let queue = device.makeCommandQueue() else {
            fatalError("Cannot obtain device queue.")
        }

        #if swift(>=5.3)
        if let libraryDefault = try? device.makeDefaultLibrary(bundle: Bundle.main) {
            self.library = libraryDefault
        } else {
            do {
                var contentsUrl: URL? = Bundle.main.url(
                    forResource: "default",
                    withExtension: "metallib")

                if let metalUrl = contentsUrl {
                    do {
                        let submoduleLibrary = try device.makeLibrary(URL: metalUrl)

                        self.library = submoduleLibrary

                        GraniteLogger.info("mtlLibrary has been loaded", .metal)
                    }
                    catch let error {
                        fatalError("Cannot initialise Metal libraries for GraniteML.")
                    }
                } else {
                    fatalError("Cannot initialise Metal libraries for GraniteML.")
                }
            }
            catch {
                fatalError("Cannot initialise Metal libraries for GraniteML.")
            }
        }
        #else
        if let libraryDefault = device.makeDefaultLibrary() {
            self.library = libraryDefault
        } else {
            fatalError("Cannot initialize Metal libraries")
        }
        #endif

        self.device = device
        self.queue = queue
    }

}
