//
//  Notify.swift
//  
//
//  Created by PEXAVC on 1/6/23.
//

import Foundation
import SwiftUI

extension Storage {
    struct NotifyIdentifierKey : Hashable {
        let id : String
        let keyPath: AnyKeyPath
    }
}

/*
 TODO:
 
 When @Geometry is added to a component state itll prevent state updates to
 update in the same lifecycle of the view of a notify response callback.
 
 probably too many state changes before the latest state is updated within the
 component
 
 */

protocol AnyNotify {
    //var id : UUID { get }
    var reducerType: AnyGraniteReducer.Type { get set }
    func send(_ payload: AnyGranitePayload?)
    func notify<E: GraniteReducer>(_ event: E)
    func remove<E: GraniteReducer>(_ event: E.Type)
    func notify<E: EventExecutable>(_ event: E)
    func remove<E: EventExecutable>(_ event: E.Type)
}

public class GraniteNotify {
    let id = UUID()
    private var notifications: [String: AnyGraniteReducer] = [:]
    private var compiledNotifications: [String: EventExecutable] = [:]
    
    //TODO: remove failsafe should be called prior to append
    //or this array should be a set
    public func notify<E: GraniteReducer>(_ event: E) {
        notifications["\(event)"] = event
    }
    
    public func notify<E: EventExecutable>(_ event: E) {
        compiledNotifications["\(event)"] = event
    }
    
    public func send(_ payload: AnyGranitePayload?) {
        for (key, value) in notifications {
            notifications[key] = nil
            value.nudgeNotifyGraniteSignal.send(payload?.asGranitePayload ?? EmptyGranitePayload())
        }
        
        for (key, value) in compiledNotifications {
            compiledNotifications[key] = nil
            value.send(payload?.asGranitePayload ?? EmptyGranitePayload())
        }
    }
    
    public func remove<E: GraniteReducer>(_ event: E.Type) {
        notifications["\(event)"] = nil
    }
    
    public func remove<E: EventExecutable>(_ event: E.Type) {
        notifications["\(event)"] = nil
    }
    
    public var notificationCount: Int {
        notifications.count
    }
}

public class GraniteNotifyContainer {
    public var graniteNotify: GraniteNotify = .init()
}

@propertyWrapper
public struct Notify: DynamicProperty, AnyNotify {
    public let id: UUID
    
    public enum Kind {
        case online
        case offline
    }
    
    public var wrappedValue : GraniteNotify {
        get {
            graniteNotifyContainer.graniteNotify
        }
        nonmutating set {
            graniteNotifyContainer.graniteNotify = newValue
        }
    }
    
    public var reducerType: AnyGraniteReducer.Type
    public var graniteNotifyContainer: GraniteNotifyContainer
    
    var graniteNotify: GraniteNotify {
        graniteNotifyContainer.graniteNotify
    }
    
    public init(_ reducerType: AnyGraniteReducer.Type) {
        self.id = .init()
        self.reducerType = reducerType
        self.graniteNotifyContainer = .init()
    }
    
    public func notify<E: GraniteReducer>(_ event: E) {
        graniteNotify.notify(event)
    }
    
    public func notify<E: EventExecutable>(_ event: E) {
        graniteNotify.notify(event)
    }
    
    public func send(_ payload: AnyGranitePayload?) {
        graniteNotify.send(payload)
    }
    
    public func remove<E: GraniteReducer>(_ event: E.Type) {
        graniteNotify.remove(event)
    }
    
    public func remove<E: EventExecutable>(_ event: E.Type) {
        graniteNotify.remove(event)
    }
}
