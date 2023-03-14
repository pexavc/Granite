//
//  GraniteCache.swift
//  Granite
//
//  Created by PEXAVC on 09/12/20.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation

open class GraniteCache {
    public static var defaults: UserDefaults {
        UserDefaults.standard
    }
    
    open class Value<T> {
        
        let key: String
        var data: T?
        
        public init(_ key: String, _ data: T?) {
            self.key = key
            self.data = data
            self.internalInit()
        }
        
        public init(_ data: T?) {
            
            if let lsv = data as? GraniteCacheValue {
                self.key = lsv.key
            } else {
                self.key = ""
            }
            
            self.data = data
            
            internalInit()
        }
        
        private func internalInit() {
            if GraniteCache.isKeyPresentInUserDefaults(key: key) {
                self.data = retrieve()
            } else {
                self.update(data)
            }
            
        }
        
        public func retrieve() -> T? {
            if let lsv = data as? GraniteCacheValue {
                if let rawInt = GraniteCache.defaults.object(forKey: key) as? Int {
                    return lsv.instance(of: rawInt) as? T
                } else {
                    return nil
                }
            } else {
                return GraniteCache.defaults.object(forKey: key) as? T
            }
        }
        
        public func update<V>(_ data: V? = nil) {
            if let lsv = data as? GraniteCacheValue {
                GraniteCache.defaults.set(lsv.intValue ?? 0, forKey: key)
            } else if let data = data as? T {
                GraniteCache.defaults.set(data, forKey: key)
            }
            
            GraniteCache.defaults.synchronize()
            self.data = data as? T
        }
    }
    
    private var valuesAny: [Value<Any>]
    private var valuesLSV: [Value<GraniteCacheValue>]
    
    public var directory: [String : Any] {
        var directoryToAdd: [String : Any] = [:]
        
        valuesAny.forEach { value in
            directoryToAdd[value.key] = value
        }
        
        valuesLSV.forEach { value in
            directoryToAdd[value.key] = value
        }
        
        return directoryToAdd
    }
    
    public init() {
        valuesAny = []
        valuesLSV = []
    }
    
    public func set(_ values: [Value<Any>]) {
        self.valuesAny = values
    }
    
    public func set(_ values: [Value<GraniteCacheValue>]) {
        self.valuesLSV = values
    }
    
    public func append(_ values: [Value<Any>]) {
        self.valuesAny.append(contentsOf: values)
    }
    
    public func append(_ values: [Value<GraniteCacheValue>]) {
        self.valuesLSV.append(contentsOf: values)
    }
    
    public func get<T>(_ key: Any, defaultValue: T) -> T {
        if let lsv = key as? GraniteCacheValue {
            guard let value = directory.first(
                where: { $0.key == lsv.key })?.value as? (Value<GraniteCacheValue>) else {
                return defaultValue
            }
            return (value.data as? T) ?? defaultValue
        }else if let ks = key as? String {
            guard let value = directory.first(
                where: { $0.key == ks })?.value as? (Value<Any>) else {
                return defaultValue
            }
            return (value.data as? T) ?? defaultValue
        } else {
            return defaultValue
        }
    }
    
    public func get(_ lsv: GraniteCacheValue.Type) -> Int {
        guard let value = directory.first(
            where: { $0.key == lsv.key })?.value as? (Value<GraniteCacheValue>) else {
            return -1
        }
        
        return (value.data)?.value ?? -1
    }
    
    public func getObject(_ lsv: GraniteCacheValue.Type) -> GraniteCacheValue? {
        guard let value = directory.first(
            where: { $0.key == lsv.key })?.value as? (Value<GraniteCacheValue>) else {
            return nil
        }
        
        return value.data
    }
    
    public func store(_ value: Value<Any>) {
        if !directory.keys.contains(value.key) {
            valuesAny.append(value)
        }
    }
    
    public static func isKeyPresentInUserDefaults(key: String) -> Bool {
        return GraniteCache.defaults.object(forKey: key) != nil
    }
    
    public func assert<T: Equatable>(
        _ key: String,
        _ comparable: T) -> Bool {
        
        guard let value = directory.first(
            where: { $0.key == key })?.value as? (Value<Any>) else {
            return false
        }
        
        guard let data = value.data as? T else {
            return false
        }
        
        return data == comparable
    }
    
    public func assert(
        _ lsv: GraniteCacheValue.Type,
        _ comparable: GraniteCacheValue) -> Bool {
        
        guard let value = directory.first(
            where: { $0.key == lsv.key })?.value as? (Value<GraniteCacheValue>) else {
            return false
        }
        
        return value.data?.value == comparable.value
    }
    
    public func update<T>(
        _ key: String,
        _ updatedValue: T) {
        
        guard let value = directory.first(
            where: { $0.key == key })?.value as? (Value<Any>) else {
            return
        }
        
        value.update(updatedValue)
    }
    
    public func update(
        _ lsv: GraniteCacheValue) {
        
        guard let value = directory.first(
            where: { $0.key == lsv.key })?.value as? (Value<GraniteCacheValue>) else {
            return
        }
        
        value.update(lsv)
    }
    
    public func clear() {
        UserDefaults.resetStandardUserDefaults()
        GraniteCache.defaults.synchronize()
    }
}

public enum GraniteCacheReadWrite: Int {
    case read
    case write
    case readAndWrite
    case internalReadAndWrite
    case lock
    
    public var canWrite: Bool {
        return self == .write || self == .readAndWrite
    }
}

public enum GraniteCacheResource {
    case image(String)
}

public protocol GraniteCacheDefaults {
    static var defaults: [GraniteCache.Value<GraniteCacheValue>] { get }
    var writeableDefaults: [GraniteCacheValue] { get }
    var readableDefaults: [GraniteCacheValue] { get }
    static var instance: GraniteCacheDefaults { get }
    init()
}

extension GraniteCacheDefaults {
    public var writeableDefaults: [GraniteCacheValue] {
        return Self.defaults
            .compactMap({ $0.retrieve() })
            .filter({ $0.permissions.canWrite })
    }
    
    public var readableDefaults: [GraniteCacheValue] {
        return Self.defaults
            .compactMap({ $0.retrieve() })
            .filter({ $0.permissions == .read || $0.permissions == .readAndWrite })
    }
    
    public static var instance: GraniteCacheDefaults {
        Self.init()
    }
}

public protocol GraniteCacheValue: Codable, CodingKey {
    var key: String { get }
    var value: Int { get }
    var resource: GraniteCacheResource? { get }
    var asString: String { get }
    var description: String { get }
    var permissions: GraniteCacheReadWrite { get }
    var allCases: [GraniteCacheValue] { get }
    func instance(of: Int) -> Any?
}

extension GraniteCacheValue {
    public var key: String {
        Self.key
    }
    
    public var asString: String {
        Self.key
    }
    
    public static var key: String {
        return "\(Self.self)"
    }
    
    public var description: String {
        return "\(Self.self)"
    }
    
    public var permissions: GraniteCacheReadWrite {
        return .read
    }
    
    public var resource: GraniteCacheResource? {
        nil
    }
}

extension GraniteCacheValue where Self: RawRepresentable, Self.RawValue == Int {
    public func instance(of: Int) -> Any? {
        return Self.init(rawValue: of)
    }
}

extension GraniteCacheValue where Self: Hashable {
    public static var allCases: [Self] {
        return [Self](AnySequence { () -> AnyIterator<Self> in
            var raw = 0
            var first: Self?
            return AnyIterator {
                let current = withUnsafeBytes(of: &raw) { $0.load(as: Self.self) }
                if raw == 0 {
                    first = current
                } else if current == first {
                    return nil
                }
                raw += 1
                return current
            }
        })
    }
    
    public var allCases: [GraniteCacheValue] {
        return Self.allCases
   }
}
