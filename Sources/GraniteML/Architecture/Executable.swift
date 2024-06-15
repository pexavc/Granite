//
//  Executable.swift
//
//
//  Created by PEXAVC on 6/15/24.
//  Copyright © 2024 Stoic Collective, LLC. All rights reserved.
//

import Foundation

public protocol Executable {
    var label : String { get }

    func run(on input : Any, state : GranitePipelineState) throws -> Any?

    func runBatch(on inputs: [Any], state : GranitePipelineState) throws -> [Any]?
}
