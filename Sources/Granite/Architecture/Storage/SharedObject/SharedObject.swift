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
    
	init(_ id: ID) where ObjectType: SharableObject {
        if let object = SharedRepository.getObject(for: id.hashValue) as? ObjectType {
            container = .init(wrappedValue: object, id: id)
        } else {
            container = .init(wrappedValue: SharedRepository.insert(ObjectType.initialValue, for: id.hashValue), id: id)
        }
	}
	
	private final class Object<ObjectType: ObservableObject>: ObservableObject {
		
		private var cancellables = Set<AnyCancellable>()
//        private var cancellable: AnyCancellable? = nil
        
		var object: ObjectType
        
        //internal var pausable: PausableSinkSubscriber<ObjectWillChangePublisher.Output, Never>? = nil
		
		init(wrappedValue: ObjectType, id: ID) where ObjectType: SharableObject {
            self.object = wrappedValue
            //self.subscribe()
            wrappedValue.pausable = wrappedValue
                .objectWillChange
                .debounce(for: .seconds(0.2), scheduler: RunLoop.main)
                .pausableSink { [unowned self] _ in
                self.objectWillChange.send()
            }
            wrappedValue.pausable?.store(in: &cancellables)
            wrappedValue.pausable?.state = .normal
		}
		
//		private func subscribe() {
//            cancellable = object
//                .objectWillChange
//                .debounce(for: .seconds(0.2), scheduler: RunLoop.main)
//                .sink { [unowned self] _ in
//				self.objectWillChange.send()
//            }
//		}
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
