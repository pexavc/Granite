//
//  GraniteSignal.swift
//  Granite
//
//  Created by PEXAVC on 07/21/22.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import Combine

protocol AnyGraniteSignal: Inspectable, Prospectable {
}

extension AnyGraniteSignal {
    //TODO:
    //for granite relay networks to work online, do not
    //remove observers
    //we should toggle this here somehow
    //published can be abstracted abit more to allow for more complex combinations with least space
    func bind(_ name: String? = nil, removeObservers: Bool = true) {
        if removeObservers {
            self.removeObservers()
        }
        
        //Prospector.shared.currentNode?.addChild(id: self.id, label: "\(name ?? "")\(name == nil ? "" : " ")" + String(reflecting: Self.self), type: .signal)
    }
    
    public func didRemoveObservers() {
         
    }
}

protocol Signal: AnyGraniteSignal, Bindable {
    associatedtype Value

    var publisher : AnyPublisher<Value, Never> { get }
    
    func observe(handler : @escaping (Value) -> Void) -> AnyCancellable
}

extension Signal {
    var observerCount: Int {
        Prospector.shared.node(for: self.id)?.prospects.count ?? 0
    }
    
    @discardableResult
    public func observe(handler : @escaping (Value) -> Void) -> AnyCancellable {
        let observer = Prospect.Node<Value>(action: handler)
        
        publisher.subscribe(observer)
        
        Prospector.shared.currentNode?.addChild(id: self.id,
                                                label: "signal" + String(reflecting: Self.self), type: .signal)
        Prospector.shared.currentNode?.addProspect(observer, for: id)
        Prospector.shared.node(for: self.id)?.addProspect(observer, for: id)
    
        return observer.cancellable
    }
    
}

extension Signal {
    @discardableResult
    public static func +=(lhs : Self, rhs : @escaping (Value) -> Void) -> AnyCancellable {
        lhs.observe(handler: rhs)
    }
}

public struct GraniteSignal : Signal {
    public let id = UUID()

    public var publisher: AnyPublisher<Void, Never> {
        subject
            .eraseToAnyPublisher()
    }
    
    internal let subject = PassthroughSubject<Void, Never>()
    
    public init() {
        
    }
    
    public func send() {
        subject.send()
    }
}
