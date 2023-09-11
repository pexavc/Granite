//
//  Prospector.swift
//  Granite
//
//  Created by PEXAVC on 01/02/22.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

extension Storage {
    struct ProspectorIdentifierKey : Hashable {
        let id : String
        let keyPath: AnyKeyPath
    }
    
    struct ProspectorSignalIdentifierKey : Hashable {
        let id : UUID
        let keyPath : AnyKeyPath
    }
}

protocol AnyProspector : Cancellable {
    
    var id : UUID { get }
    
}

public class Prospector : Prospect {

    public init(id: UUID = .init(), type: ProspectType = .root) {
        super.init(id: id, label: "\(type)", type: type)
        
        nodes.setObject(self, forKey: self.id.uuidString as NSString)
        scope.append(self.id)
    }
    
    static let shared = Prospector()
    
    var nodes = NSMapTable<NSString, Prospect>.strongToWeakObjects()
    var scope = [UUID]()
    var scopeBench = [(ProspectType, Double)]()
    
    public var nodeCount: Int {
        nodes.count
    }
}
