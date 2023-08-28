//
//  Action.swift
//  Granite
//
//  Created by PEXAVC on 12/26/22.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI

@propertyWrapper public struct GraniteAction<T> {
    
    public class ActionWrapper {
        
        var action : ((T) -> Void)? = { _ in
            
        }
        
        var clearOnPerform: Bool = false
        
        public func perform(_ value : T) {
            action?(value)
        }
        
    }
    
    public var wrappedValue : ActionWrapper {
        wrapper
    }
    
    fileprivate let wrapper = ActionWrapper()
    
    public init() {
        
    }
    
}

extension GraniteAction where T == Void {
    
    public init() {
        
    }
    
}

extension GraniteAction.ActionWrapper where T == Void {
    
    public func perform() {
        action?(())
    }
    
}

public protocol GraniteActionable {
    
}

extension GraniteActionable {
    public func attach<I>(_ action : (@escaping (I) -> Void), at keyPath : KeyPath<Self, GraniteAction<I>.ActionWrapper>) -> Self {
        self[keyPath: keyPath].action = { value in
            action(value)
        }
        
        return self
    }
}

extension View {
    //Experimenting this retained action in Loom's Modals
    public func attachAndClear<I>(_ action : (@escaping (I) -> Void),
                          at keyPath : KeyPath<Self, GraniteAction<I>.ActionWrapper>) -> some View {
        self[keyPath: keyPath].action = { value in
            action(value)
            self[keyPath: keyPath].action = nil
        }
        
        return self
            .onDisappear {
                self[keyPath: keyPath].action = nil
            }
    }
    
    public func attach<I>(_ action : (@escaping (I) -> Void),
                          at keyPath : KeyPath<Self, GraniteAction<I>.ActionWrapper>) -> Self {
        self[keyPath: keyPath].action = { value in
            action(value)
        }
        
        return self
    }
    
    public func attach(_ action : (@escaping () -> Void), at keyPath : KeyPath<Self, GraniteAction<Void>.ActionWrapper>) -> Self {
        self[keyPath: keyPath].action = { value in
            action()
        }
        
        return self
    }
    
    public func attach(_ action : GraniteAction<Void>.ActionWrapper, at keyPath : KeyPath<Self, GraniteAction<Void>.ActionWrapper>) -> Self {
        self[keyPath: keyPath].action = { value in
            action.perform(value)
        }
        
        return self
    }

    public func attach<I>(_ action : GraniteAction<I>.ActionWrapper, at keyPath : KeyPath<Self, GraniteAction<I>.ActionWrapper>) -> Self {
        self[keyPath: keyPath].action = { value in
            action.perform(value)
        }

        return self
    }
    
    public func attach<I, O>(_ action : GraniteAction<O>.ActionWrapper,
                             at keyPath : KeyPath<Self, GraniteAction<I>.ActionWrapper>,
                             transform : @escaping (I) -> O) -> Self {
        self[keyPath: keyPath].action = { value in
            action.perform(transform(value))
        }
        
        return self
    }
    
    public func attach<S: EventExecutable, O>(_ expedition: S,
                                              at keyPath : KeyPath<Self, GraniteAction<O>.ActionWrapper>) -> Self {
        self[keyPath: keyPath].action = { value in
            if let _ = value as? GranitePayload {
                expedition.send(value as? GranitePayload ?? EmptyGranitePayload())
            } else {
                expedition.send()
            }
        }
        
        return self
    }
    
    
}
