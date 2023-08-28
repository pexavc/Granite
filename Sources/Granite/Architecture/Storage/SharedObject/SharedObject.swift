//
//  SharedObject.swift
//
//
//  Created by Lorenzo Fiamingo on 31/07/2020.
//

import SwiftUI
import Combine

class SharedObjectJobs {
    static var shared: FilePersistenceJobs = .init()
    
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
	
	public init(wrappedValue: ObjectType, _ id: ID) {
        container = .init(wrappedValue: wrappedValue, id: id)
	}
	
	public init(_ id: ID) {
        container = .init(wrappedValue: nil, id: id)
	}
	
	public init(_ id: ID) where ObjectType: SharableObject {
        container = .init(wrappedValue: ObjectType.initialValue,
                       id: id)
        self.container.object.sharableLoaded()
	}
	
	private final class Object<ObjectType: ObservableObject>: ObservableObject {
		
		private var cancellable: AnyCancellable?
		
		var object: ObjectType { didSet { subscribe() } }
		
		init(wrappedValue: ObjectType?, id: ID) {
			object = SharedRepository.getObject(for: id.hashValue,
                                                defaultValue: wrappedValue)
			subscribe()
		}
		
		private func subscribe() {
            cancellable = object
                .objectWillChange
                .debounce(for: .seconds(0.2), scheduler: RunLoop.main)
                .sink { [unowned self] _ in
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
