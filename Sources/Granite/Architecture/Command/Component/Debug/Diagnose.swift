//
//  Diagnose.swift
//  Granite
//
//  Created by PEXAVC on 12/8/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation

struct DiagnoseTree<C: GraniteCenter>: GraniteReducer {
    typealias Center = C
    
    init() {}
    
    func reduce(state: inout Center.GenericGraniteState) {
        printTree(Prospector.shared)
    }
}

extension DiagnoseTree {
    func printTree(_ rootNode: Prospector) {
        var nodeCount: Int = 0
        var nodesDetected: [Prospect] = []
        
        func inspect(_ node: Prospect, type: ProspectType) -> String {
            nodesDetected.append(node)
            nodeCount += 1
            
            func childDetail(_ node: Prospect, callCount: Int = 0, expand: Bool = true) -> String {
                
                var childInfo = """
                """
                
                guard expand else {
                    let nodeCountOld = nodeCount
                    for child in node.children {
                        if child.children.isEmpty == false {
                            let _ = childDetail(child, callCount: callCount + 1, expand: false)
                        }
                        nodesDetected.append(child)
                        nodeCount += 1
                    }
                    
                    childInfo += """
                    Nested Children: \(nodeCount - nodeCountOld)
                    """
                    
                    return childInfo
                }
                
                for child in node.children {
                    let parent = child.parent?.label ?? "none"
                    let parentType: ProspectType = child.parent?.type ?? .none
                    let parentId = child.parent?.id.uuidString ?? ""
                    let tabs = [String].init(repeating: "\t", count: callCount).joined(separator: "")
                    let startingSep = callCount == 0 ? "//" : "::"
                    childInfo += """
                        
                        \(tabs)\(startingSep) \(child.label) [\(child.type)]
                        \(tabs)\(startingSep) Parent: \(parent) [\(parentType)]
                        \(tabs)\(startingSep) Children: \(child.children.count)
                        \(child.children.isEmpty ? "" : childDetail(child, callCount: callCount + 1))
                        \(tabs)\(startingSep) \(child.id)
                        \(tabs)-------------------------------
                    
                    """
                    nodesDetected.append(child)
                    nodeCount += 1
                }
                
                
                return childInfo
            }
            var info: String = """
            """
            guard let node = Prospector.shared.node(for: node.id) else {
                return "not observed, either removed or leaked"
            }
            
            let command = node.label
            let instanceState = "none"
            let parent = node.parent?.id.uuidString ?? "none"
            let parentType: ProspectType = node.parent?.type ?? .none
            let instanceType: ProspectType = node.type
            
            let attachedTo: String? = nil
            
            info += """
              _____________________________
             | \(command) (\(instanceType)) [\(instanceState)] \((attachedTo == nil ? "" : attachedTo!))
             | -----------------------
             | Parent: \(parent) [\(parentType)]
             | Children: \(node.children.count)
             | \(childDetail(node, expand: false))
             |
             | \(node.id)
             |_____________________________
            
            """
            
            
            return info
        }
        
        var detail: String = """
        \n
         Root Node Count: \(Prospector.shared.nodeCount)
         ===============================:
         \n
         \(inspect(rootNode, type: .root))
        """
        
        let diff = Prospector.shared.diff(nodesDetected)
        detail += """
        \n
         ===============================: \(nodesDetected.count), Leaks Detected: \(diff.isEmpty == false)
        \n
        """
        
        if diff.isEmpty == false {
            detail += """
            \n
             Failed to detect
             ===============================:
             \n
            """
            for node in diff {
                if let nodeCheck = node {
                    detail += """
                      _____________________________
                     | \(nodeCheck.label)
                     | -----------------------
                     | Parent: \(nodeCheck.parent?.label ?? "none") [\(nodeCheck.parent?.type ?? .none)]
                     |_____________________________
                    \n
                    """
                }
            }
        }
        
        print(detail)
    }
}
