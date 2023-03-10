//
//  Persistence.swift
//  Granite
//
//  Created by PEXAVC on 12/10/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation

/*
 Base class for Persistence types.
*/
public protocol AnyPersistence : AnyObject {
    
    var key : String { get }
    
    init(key : String)
    
    func save<State : Codable>(state : State)
    func restore<State : Codable>() -> State?
    func purge()
}

extension AnyPersistence {
    public var key : String {
        "Empty"
    }
    
    public func save<State>(state: State) where State : Codable {}
    
    public func restore<State>() -> State? where State : Codable {
        return nil
    }
    
    public func purge() {}
}

/*
 Mostly used for default inits
*/
public class EmptyPersistence : AnyPersistence {
    public init() {}
    public required init(key: String) {}
}
