//
//  GraniteSignal.Payload.swift
//  Granite
//
//  Created by PEXAVC on 07/21/22.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import Combine

extension GraniteSignal {
    public struct Payload<Value> : Signal {
        
        fileprivate class Storage {
            var lastValue : Value? = nil
        }
        
        public let id = UUID()
        
        public var publisher: AnyPublisher<Value, Never> {
            subject
                .eraseToAnyPublisher()
            
        }
        
        public internal(set) var lastValue : Value? {
            get {
                storage.lastValue
            }
            
            set {
                storage.lastValue = newValue
            }
        }
        
        internal let subject : PassthroughSubject<Value, Never>
        
        fileprivate let storage = Storage()
        
        public init(_ initial : Value? = nil) {
            self.subject = PassthroughSubject()
        }
        
        public func send(_ value : Value) {
            storage.lastValue = value
            subject.send(value)
        }
        
    }
}

extension GraniteSignal.Payload {
    
    @discardableResult
    public func observeChange(handler : @escaping (Value, Value) -> Void) -> AnyCancellable {
        let observer = Prospect.Node<Value> { value in
            guard let oldValue = self.lastValue else {
                return
            }
            
            handler(value, oldValue)
        }
        
        Prospector.shared.currentNode?.addProspect(observer, for: id)
        Prospector.shared.node(for: self.id)?.addProspect(observer, for: id)
        
        return observer.cancellable
    }
    
}
