//
//  FilePersistence.swift
//  Granite
//
//  Created by PEXAVC on 12/10/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation

/*
 Allows for @Store'd GraniteStates to persist data. A lightweight
 CoreData alternative.
*/
final public class FilePersistence : AnyPersistence {
    
    public static var initialValue: FilePersistence {
        .init(key: UUID().uuidString)
    }
    
    public let key : String
    
    fileprivate let url : URL
    
    public var isRestoring: Bool = false
    
    public required init(key: String) {
        self.key = key
        self.url = FilePersistence.Root.appendingPathComponent(key)
        
        do {
            try FileManager.default.createDirectory(at: FilePersistence.Root,
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)
        }
        catch let error {
            print("[Granite] FilePersistence: \(error.localizedDescription)")
        }
    }
    
    public func save<State>(state: State) where State : Codable {
        let encoder = PropertyListEncoder()
        
        
        do {
            let data = try encoder.encode(state)
            
            //If the service is online wrong saves can occur
            //TODO: tmp files that pickle into the full file later?
            let oldData = try Data(contentsOf: url)
            
            guard data.count != oldData.count else {
                return
            }
            
            //print("[Granite] saving \(key)")
            
            try data.write(to: url)
        }
        catch let error {
            print("[Granite] FilePersistence '\(key)' / \(error)")
        }
    }
    
    public func restore<State>() -> State? where State : Codable {
        let decoder = PropertyListDecoder()
        
        guard let data = try? Data(contentsOf: url) else {
            print("[Granite] failed to restore: \(key)")
            return nil
        }
        
        do {
            //print("[Granite] restoring: \(key)")
            return try decoder.decode(State.self, from: data)
        }
        catch let error {
            print("[Granite] FilePersistence '\(key)' / \(error)")
            return nil
        }
    }
  
    public func purge() {
        try? FileManager.default.removeItem(at: url)
    }
 
}

extension FilePersistence {
    
    fileprivate static let Root : URL = {
        let value = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return value.appendingPathComponent("granite-file-persistance")
    }()
    
}
