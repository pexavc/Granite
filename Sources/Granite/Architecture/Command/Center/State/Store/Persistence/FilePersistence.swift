//
//  FilePersistence.swift
//  Granite
//
//  Created by PEXAVC on 12/10/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation

class FilePersistenceJobs {
    static var shared: FilePersistenceJobs = .init()
    
    var map: [String : OperationQueue] = [:]
    var threads: [String : DispatchQueue] = [:]
    
    init() {}
    
    func create(_ key: String) {
        guard map[key] == nil else { return }
        
        self.threads[key] = .init(label: "granite.rw.queue.\(key)", qos: .background)
        self.map[key] = .init()
        self.map[key]?.underlyingQueue = self.threads[key]
        self.map[key]?.maxConcurrentOperationCount = 1
    }
}

/*
 Allows for @Store'd GraniteStates to persist data. A lightweight
 CoreData alternative.
*/
final public class FilePersistence : AnyPersistence {
    public var readWriteQueue: OperationQueue? {
        FilePersistenceJobs.shared.map[key]
    }
    
    public static var initialValue: FilePersistence {
        .init(key: UUID().uuidString, kind: .basic)
    }
    
    public let key : String
    
    fileprivate let url : URL
    
    public var isRestoring: Bool = false
    
    public var hasRestored: Bool = false
    
    public required init(key: String, kind: PersistenceKind) {
        let rootPath: URL
        
        func getDefaultURL() -> URL {
            let value = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            return value.appendingPathComponent("granite-file-persistance")
        }
        switch kind {
        case .basic:
            rootPath = getDefaultURL()
        case .group(let id):
            let groupURL = FileManager
                .default
                .containerURL(
                    forSecurityApplicationGroupIdentifier: id)?
                .appendingPathComponent("granite-file-persistance")
            
            rootPath = groupURL ?? getDefaultURL()
        }
        
        self.key = key
        self.url = rootPath.appendingPathComponent(key)
        
        FilePersistenceJobs.shared.create(key)
        
        do {
            try FileManager.default.createDirectory(at: rootPath,
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)
        }
        catch let error {
            GraniteLog(error.localizedDescription, level: .error)
        }
    }
    
    public func save<State>(state: State) where State : Codable {
        let encoder = PropertyListEncoder()
        
        self.readWriteQueue?.addOperation { [weak self] in
            do {
                guard let self else { return }
                let data = try encoder.encode(state)
                
                try data.write(to: self.url)
                
                //GraniteLog(self.key, level: .info)
            }
            catch let error {
                GraniteLog("key: \(self?.key ?? "") | error: \(error.localizedDescription)", level: .error)
            }
        }
    }
    
    public func restore<State>() -> State? where State : Codable {
        let decoder = PropertyListDecoder()
        
        guard let data = try? Data(contentsOf: url) else {
            GraniteLog(key, level: .error)
            return nil
        }
        
        do {
            hasRestored = true
            return try decoder.decode(State.self, from: data)
        }
        catch let error {
            GraniteLog("key: \(key) | error: \(error.localizedDescription)", level: .error)
            return nil
        }
    }
  
    public func purge() {
        try? FileManager.default.removeItem(at: url)
    }
}
