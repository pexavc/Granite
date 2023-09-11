//
//  GraniteMemory.Management.swift
//
//  When constructing GraniteComponents in scrollviews or relays are
//  being used
//
//  Created by PEXAVC on 9/8/23.
//

import Foundation

public extension GraniteMemory {
    class Management {
        public init() {
            
        }
        
        public func addBlock(id: UUID, label: String = "memory-block") {
            let TASK_VM_INFO_COUNT = MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size
                    
            var vmInfo = task_vm_info_data_t()
            var vmInfoSize = mach_msg_type_number_t(TASK_VM_INFO_COUNT)
                    
            let kern: kern_return_t = withUnsafeMutablePointer(to: &vmInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        task_info(mach_task_self_,
                                  task_flavor_t(TASK_VM_INFO),
                                  $0,
                                  &vmInfoSize)
                        }
                    }

            if kern == KERN_SUCCESS {
                let usedSize = Int(vmInfo.internal + vmInfo.compressed)
                print("Memory in use: \(usedSize) bytes")
            } else {
                let errorString = String(cString: mach_error_string(kern), encoding: .ascii) ?? "unknown error"
                print("Error with task_info(): \(errorString)");
            }
        }
        
        public func removeBlock(id: UUID) {
            Prospector
                .shared
                .node(for: id)?
                .remove(includeChildren: true)
            
            Prospector.shared.remove(id: id)
        }
        
        public func resetBlock(id: UUID) {
            let currentLabel: String = Prospector
                .shared
                .currentNode?.label ?? "unknown"
            GraniteLog("resetting memory block under: \(currentLabel)", level: .debug)
            
            let label = Prospector.shared.node(for: id)?.label
            removeBlock(id: id)
            
            addBlock(id: id, label: label ?? "memory-block")
        }
    }
}
