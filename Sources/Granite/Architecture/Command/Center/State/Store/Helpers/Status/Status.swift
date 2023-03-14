//
//  Status.swift
//  Granite
//
//  Created by PEXAVC on 12/8/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation

infix operator !~= : StatusBooleanPrecedence

precedencegroup StatusBooleanPrecedence {
    higherThan: LogicalConjunctionPrecedence
    associativity: left
    assignment: false
}

public protocol AnyStatus : Codable, Hashable {
    
}

/*
 Set which can host descriptors to define minimal states
 of subroutines in a Component
*/
public typealias Status<S : AnyStatus> = Set<S>

/*
 Helpful operands to manage a SatusSet swiftly
*/
extension Status {
    
    public static func +=(lhs : inout Set<Element>, rhs : Element) {
        lhs.insert(rhs)
    }
    
    public static func -=(lhs : inout Set<Element>, rhs : Element) {
        lhs.remove(rhs)
    }
    
    public static func |=(lhs : inout Set<Element>, rhs : Element) {
        lhs.removeAll()
        lhs.insert(rhs)
    }
    
    public static func ~=(lhs : Set<Element>, rhs : Element) -> Bool {
        lhs.contains(rhs)
    }
    
    public static func !~=(lhs : Set<Element>, rhs : Element) -> Bool {
        lhs.contains(rhs) == false
    }
    
}
