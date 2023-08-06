//
//  Prospect.swift
//  Granite
//
//  Created by PEXAVC on 01/02/22.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import Combine

public enum ProspectType: String {
    case root
    case command
    case center
    case relay
    case relayNetwork
    case event
    case expedition
    case signal
    case state
    case none
}

public class Prospect {
    
    let id : UUID
    
    let label : String
    
    let type : ProspectType
    
    weak var parent : Prospect? = nil
    
    var children = Set<Prospect>()

    var prospects = Set<AnyCancellable>()
    
    init(id : UUID, label: String, type: ProspectType) {
        self.id = id
        self.label = label
        self.type = type
    }
    
    deinit {
        Prospector.shared.nodes.removeObject(forKey: id.uuidString as NSString)
    }
    
    func addProspect<V>(_ node : Prospect.Node<V>, for signalid : UUID) {
        self.prospects.insert(node.cancellable)
    }
    
    func addProspector(_ node : Prospector) {
        node.parent = self
        Prospector.shared.nodes.setObject(node, forKey: node.id.uuidString as NSString)
        self.children.insert(node)
    }
    
    //TODO: not threadsafe singleton refer to parent tree
    @discardableResult
    func addChild(id : UUID, label: String, type: ProspectType) -> Prospect {
        let child = Prospect(id: id, label: label, type: type)
        child.parent = self
        
        Prospector.shared.nodes.setObject(child, forKey: child.id.uuidString as NSString)
        
        children.insert(child)
        return child
    }
    
    @discardableResult
    func remove(includeChildren : Bool = true) -> [UUID] {
        prospects.forEach {
            $0.cancel()
        }
        
        var removedIDs: [UUID] = [self.id]
        
        prospects.removeAll()
        
        if includeChildren == true {
            children.forEach {
                removedIDs += $0.remove(includeChildren: true)
            }
            
            children.removeAll()
        }
        
        parent?.children.remove(self)
        
        return removedIDs
    }
    
}

extension Prospect : Hashable, Equatable {
    
    public static func == (lhs: Prospect, rhs: Prospect) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}
