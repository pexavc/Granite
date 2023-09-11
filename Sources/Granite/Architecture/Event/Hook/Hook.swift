//
//  Hook.swift
//  Granite
//
//  Created by PEXAVC on 9/11/23.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI

@propertyWrapper
public struct GraniteHook<T, O> {
    
    public class HookWrapper {
        
        var action : ((T) -> O)? = nil
        
        var clearOnPerform: Bool = false
        
        public func perform(_ value : T) -> O? {
            action?(value)
        }
        
    }
    
    public var wrappedValue : HookWrapper {
        wrapper
    }
    
    fileprivate let wrapper = HookWrapper()
    
    public init() {
        
    }
    
}

@propertyWrapper
public struct GraniteHookAsync<T, O> {
    
    public class AsyncHookWrapper {
        
        var action : ((T) async -> O)? = nil
        
        var clearOnPerform: Bool = false
        
        public func perform(_ value : T) async -> O? {
            await action?(value)
        }
        
    }
    
    public var wrappedValue : AsyncHookWrapper {
        wrapper
    }
    
    fileprivate let wrapper = AsyncHookWrapper()
    
    public init() {
        
    }
    
}

extension GraniteActionable {
//    public func hook<T, O>(_ action : (@escaping (T) -> O), at keyPath : KeyPath<Self, GraniteHook<T, O>.HookWrapper>) {
//        self[keyPath: keyPath].action = { value in
//            action(value)
//        }
//    }
    
    public func hookAsync<T, O>(_ action : (@escaping (T) async -> O), at keyPath : KeyPath<Self, GraniteHookAsync<T, O>.AsyncHookWrapper>) {
        self[keyPath: keyPath].action = { value in
            await action(value)
        }
    }
}
