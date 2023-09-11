//
//  SharedObject.swift
//
//
//  Created by Lorenzo Fiamingo on 31/07/2020.
//

import Foundation
import SwiftUI
import Combine

class SharedObjectJobs {
    static var shared: SharedObjectJobs = .init()
    
    var map: [Int : OperationQueue] = [:]
    var threads: [Int : DispatchQueue] = [:]
    
    init() {}
    
    func create(_ key: Int) {
        guard map[key] == nil else { return }
        
        self.threads[key] = .init(label: "granite.shared.repo.queue.\(key)", qos: .background)
        self.map[key] = .init()
        self.map[key]?.underlyingQueue = self.threads[key]
        self.map[key]?.maxConcurrentOperationCount = 1
    }
}

/// A property wrapper type for an observable object supplied with an id or created at the moment.
@available(watchOS 6.0, tvOS 13.0, iOS 13.0, OSX 10.15, *)
@propertyWrapper
public struct SharedObject<ObjectType, ID>: DynamicProperty where ObjectType: ObservableObject, ID: Hashable {
	
	@ObservedObject private var container: Object<ObjectType>
	
	public var wrappedValue: ObjectType {
		get {
            container.object
        }
		nonmutating set {
            container.object = newValue
        }
	}
	
	public var projectedValue: SharedObject.Wrapper {
		.init(container.object)
	}
	
//	init(wrappedValue: ObjectType, _ id: ID) {
//        container = .init(wrappedValue: wrappedValue, id: id)
//	}
    
    public func silence() {
        container.pausable?.state = .stopped
    }
    
    public func awake() {
        container.pausable?.state = .normal
    }
    
	init(_ id: ID) where ObjectType: SharableObject {
        if let object = SharedRepository.getObject(for: id.hashValue) as? ObjectType {
            container = .init(wrappedValue: object, id: id)
        } else {
            container = .init(wrappedValue: SharedRepository.insert(ObjectType.initialValue, for: id.hashValue), id: id)
        }
	}
	
	private final class Object<ObjectType: ObservableObject>: ObservableObject {
        
		var object: ObjectType
        
        /*
         This container is created wherever a @Relay is called.
         But, there's always only 1 relay instance.
         
         We simply subscribe to each, propogate view updates.
         While maintaining data consistency in 1 singular location.
         */
        
        weak var pausable: PausableSinkSubscriber<ObjectType.ObjectWillChangePublisher.Output, Never>? = nil
		
        deinit {
            pausable?.cancel()
            pausable = nil
            Prospector.shared.node(for: self.id)?.remove(includeChildren: true)
            //GraniteLog("Shareable deinit", level: .debug)
        }
        
        let id: UUID = .init()
        
		init(wrappedValue: ObjectType, id: ID) where ObjectType: SharableObject {
            self.object = wrappedValue
            
            let currentNodeId = Prospector.shared.currentNode?.id
            Prospector.shared.currentNode?.addChild(id: self.id,
                                                    label: String(reflecting: Self.self),
                                                    type: .relayNetwork)
            Prospector.shared.push(id: self.id, .relayNetwork)
            
            pausable = wrappedValue
                .objectWillChange
                .debounce(for: .seconds(0.2), scheduler: RunLoop.main)
                .pausableSink { [unowned self] _ in
                self.objectWillChange.send()
            }
            pausable?.state = .normal
            
            if let currentNodeId,
               let pausable  {
                let nodeLabel = Prospector.shared.node(for: currentNodeId)?.label ?? ""
                //GraniteLog("Shared sub'd under id: \(currentNodeId) | \(nodeLabel)", level: .debug)
                Prospector.shared.currentNode?.addProspect(pausable, for: self.id)
            } else if currentNodeId == nil {
                //GraniteLog("No current node exists: \(String(reflecting: ObjectType.self))", level: .debug)
            }
            
            Prospector.shared.pop(.relayNetwork)
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
final class SharedRepository {
    
    private static var objects: [Int: Any] = [:]
    
    static func getObject(for key: Int) -> Any? {
        return objects[key]
    }
    
    static func insert<ObjectType>(_ object: ObjectType, for key: Int) -> ObjectType {
        objects[key] = object
        return object
    }
}
