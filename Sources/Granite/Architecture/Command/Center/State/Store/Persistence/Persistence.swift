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
    var readWriteQueue: OperationQueue? { get }
    
    var key : String { get }
    
    var isRestoring : Bool { get set }
    
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
    public let readWriteQueue: OperationQueue? = .init()
    public var isRestoring: Bool = false
    
    public init() {}
    public required init(key: String) {}
}
