//
//  Prospector.Transforms.swift
//  Granite
//
//  Created by PEXAVC on 01/02/22.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation

extension Prospector {
    
    //Mostly meant for debugging purposes
    public func diff(_ nodes: [Prospect]) -> [Prospect?] {
        guard let localNodes: NSMapTable<NSString, Prospect> = self.nodes.mutableCopy() as? NSMapTable<NSString, Prospect> else {
            return []
        }
        
        var nodesDetectedButNotInTree: [Prospect?] = nodes
        for node in nodes {
            if localNodes.object(forKey: node.id.uuidString as NSString) != nil {
                nodesDetectedButNotInTree.removeAll(where: { $0?.id == node.id })
            }
            localNodes.removeObject(forKey: node.id.uuidString as NSString)
            
        }
        
        var diffNodes: [Prospect?] = []
        autoreleasepool {
            let e = localNodes.keyEnumerator()
            for case let key as NSString in e {
                diffNodes.append(localNodes.object(forKey: key))
            }
        }
        
        return diffNodes + nodesDetectedButNotInTree
    }
    
    //TODO: below functions need to be refined / not safe
    var currentNode : Prospect? {
        guard let scopeId = scope.last else {
            return nil
        }
        
        return nodes.object(forKey: scopeId.uuidString as NSString)
    }
    
    func node(for id : UUID) -> Prospect? {
        return nodes.object(forKey: id.uuidString as NSString)
    }
    
    func push(id : UUID, _ type: ProspectType = .none) {
        scope.append(id)
    }
    
    func pop(_ type: ProspectType = .none) {
        guard let last = scope.last,
              last != Prospector.shared.id else {
            return
        }
        
        scope.removeLast()
    }
    
    func remove(id: UUID) {
        guard id != self.id else { return }
        
        node(for: id)?.remove(includeChildren: true)
        scope.removeAll(where: { $0 == id })
        nodes.removeObject(forKey: id.uuidString as NSString)
    }
    
    func print() {
        guard let localNodes: NSMapTable<NSString, Prospect> = self.nodes.mutableCopy() as? NSMapTable<NSString, Prospect> else {
            return
        }
        
        autoreleasepool {
            let e = localNodes.keyEnumerator()
            for case let key as NSString in e {
                let node = localNodes.object(forKey: key)
                Swift.print(node?.label)
            }
        }
    }
}
