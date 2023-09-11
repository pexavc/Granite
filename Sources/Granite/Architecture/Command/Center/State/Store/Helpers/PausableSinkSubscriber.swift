//
//  PausableSinkSubscriber.swift
//  
//
//  Created by PEXAVC on 7/30/23.
//

import Foundation
import Combine


extension Publisher {
    func pausableSink(
        receiveValue: @escaping (Output) -> Void,
        receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void
    ) -> PausableSinkSubscriber<Output, Failure> {
        let subscriber = PausableSinkSubscriber<Output, Failure>(
            receiveValue: receiveValue,
            receiveCompletion: receiveCompletion
        )
        self.subscribe(subscriber)
        return subscriber
    }
    
    func pausableSink(
        _ receiveValue: @escaping (Output) -> Void
    ) -> PausableSinkSubscriber<Output, Failure> where Failure == Never {
        let subscriber = PausableSinkSubscriber<Output, Failure>(
            receiveValue: receiveValue
        )
        self.subscribe(subscriber)
        return subscriber
    }
}

class PausableSinkSubscriber<Input, Failure: Error>: Subscriber, AnyProspectNode {
    var id: UUID = .init()
    
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
    
    var cancellable: AnyCancellable {
        storage.cancellable
    }
    
    enum State {
        case idle
        case stopped
        case paused
        case normal
    }
    
    //TODO: atomic
    var state: State = .idle {
        didSet {
            if oldValue == .paused && state == .normal {
                sendBuffer()
            }
        }
    }
    
    var isStopped = false
    
    var buffer = [Input]()
    var receiveValue: (Input) -> Void
    var receiveCompletion: ((Subscribers.Completion<Failure>) -> Void)?
    
    fileprivate let storage = Storage()
    
    init(
        receiveValue: @escaping (Input) -> Void,
        receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void
    ) {
        self.receiveValue = receiveValue
        self.receiveCompletion = receiveCompletion
    }
    
    init(
        receiveValue: @escaping (Input) -> Void
    ) {
        self.receiveValue = receiveValue
        self.receiveCompletion = nil
    }
    
    deinit {
        cancel()
    }
    
    func receive(subscription: Subscription) {
        storage.subscription = subscription
        subscription.request(.unlimited)
    }
    
    func receive(_ input: Input) -> Subscribers.Demand {
        switch state {
        case .normal:
            receiveValue(input)
        case .paused:
            buffer.append(input)
        default:
            break
        }
        
        return self.demand
    }
    
    func sendBuffer() {
        while !buffer.isEmpty {
            let value = buffer.remove(at: 0)
            receiveValue(value)
        }
    }
    
    func receive(completion: Subscribers.Completion<Failure>) {
        receiveCompletion?(completion)
    }
    
    var demand: Subscribers.Demand {
        switch state {
        case .paused, .stopped:
            return .none
        default:
            return .unlimited
        }
    }
    
    func cancel() {
        cancellable.cancel()
    }
}
