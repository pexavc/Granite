//
//  Prospect.Node.swift
//  Granite
//
//  Created by PEXAVC on 01/02/22.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import Combine

protocol AnyProspectNode : Cancellable {
    var id : UUID { get }
}

extension Prospect {
    struct Node<Value> : Subscriber, AnyProspectNode {
        typealias Input = Value
        typealias Failure = Never
        
        fileprivate class Storage {
            
            var cancellable = AnyCancellable({})
            
            var subscription : Subscription? = nil {
                
                didSet {
                    cancellable = AnyCancellable { [weak self] in
                        self?.subscription?.cancel()
                        self?.subscription = nil
                    }
                }
                
            }
            
        }
        
        var cancellable : AnyCancellable {
            storage.cancellable
        }
        
        let combineIdentifier = CombineIdentifier()
        let id = UUID()
        let action : (Value) -> Void
        
        fileprivate let storage = Storage()
        
        init(action : @escaping (Value) -> Void) {
            self.action = action
        }
        
        func receive(subscription: Subscription) {
            storage.subscription = subscription

            subscription.request(.unlimited)
        }
        
        func receive(_ input: Value) -> Subscribers.Demand {
            action(input)
            return .none
        }
        
        func receive(completion: Subscribers.Completion<Never>) {
            
        }
        
        func cancel() {

            storage.cancellable.cancel()
            storage.cancellable = AnyCancellable({})
        }
    }
}
