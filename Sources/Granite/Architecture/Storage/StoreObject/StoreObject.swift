//
//  StoreObject.swift
//  
//
//  Created by PEXAVC on 9/11/23.
//

import Foundation
import Combine
import SwiftUI

/// A type of object that can provide a common initial value.
@available(watchOS 6.0, tvOS 13.0, iOS 13.0, OSX 10.15, *)
public protocol StoreableObject: ObservableObject {
    
    static var initialValue: Self { get }
}

/// A property wrapper type for an observable object supplied with an id or created at the moment.
@available(watchOS 6.0, tvOS 13.0, iOS 13.0, OSX 10.15, *)
@propertyWrapper
public struct StoreObject<ObjectType, ID>: DynamicProperty where ObjectType: ObservableObject, ID: Hashable {
    
    @ObservedObject private var container: Object<ObjectType>
    
    public var wrappedValue: ObjectType {
        get {
            container.object
        }
        nonmutating set {
            container.object = newValue
        }
    }
    
    public var projectedValue: StoreObject.Wrapper {
        .init(container.object)
    }
    
    public init(_ id: ID) where ObjectType: StoreableObject {
        if let object = StoreRepository.getObject(for: id.hashValue) as? ObjectType {
            container = .init(wrappedValue: object, id: id)
        } else {
            container = .init(wrappedValue: StoreRepository.insert(ObjectType.initialValue, for: id.hashValue), id: id)
        }
    }
    
    private final class Object<ObjectType: ObservableObject>: ObservableObject {
        
        var cancellable: AnyCancellable?
        var object: ObjectType
        
        let id: ID
        
        deinit {
            cancellable?.cancel()
            StoreRepository.remove(for: id.hashValue)
            GraniteLog("Storeable deinit", level: .debug)
        }
        
        init(wrappedValue: ObjectType, id: ID) where ObjectType: StoreableObject {
            self.object = wrappedValue
            self.id = id
            
            cancellable = object
                .objectWillChange
                .sink { _ in
                    self.objectWillChange.send()
                }
        }
    }
    
    @dynamicMemberLookup
    public struct Wrapper {
        private let object: ObjectType
        
        init(_ object: ObjectType) {
            self.object = object
        }
        
        subscript<Subject>(dynamicMember keyPath: ReferenceWritableKeyPath<ObjectType, Subject>) -> Binding<Subject> {
            .init {
                object[keyPath: keyPath]
            } set: { newValue in
                object[keyPath: keyPath] = newValue
            }
        }
    }
}

final class StoreRepository {
    private static var objects: [Int: Any] = [:]
    
    static func getObject(for key: Int) -> Any? {
        return objects[key]
    }
    
    static func insert<ObjectType>(_ object: ObjectType, for key: Int) -> ObjectType {
        objects[key] = object
        return object
    }
    
    static func remove(for key: Int) {
        objects[key] = nil
    }
}
