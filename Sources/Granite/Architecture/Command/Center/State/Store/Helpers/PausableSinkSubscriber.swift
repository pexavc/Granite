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

class PausableSinkSubscriber<Input, Failure: Error>: Subscriber, Cancellable {
    var subscription: Subscription?
    
    //TODO: atomic
    var isPaused = false {
        didSet {
            if !isPaused {
                sendBuffer()
            }
        }
    }
    var buffer = [Input]()
    var receiveValue: (Input) -> Void
    var receiveCompletion: ((Subscribers.Completion<Failure>) -> Void)?
    
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
        self.subscription = subscription
        subscription.request(.unlimited)
    }
    
    func receive(_ input: Input) -> Subscribers.Demand {
        if isPaused {
            buffer.append(input)
        } else {
            receiveValue(input)
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
        isPaused ? .unlimited : .none
    }
    
    func cancel() {
        subscription?.cancel()
        subscription = nil
    }
}
