//
//  GraniteLogger.swift
//
//
//  Created by PEXAVC on 2/26/21.
//  Copyright Β© 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import os

public struct GraniteLogger {
    private static let subsystem = "granite"
    
    public enum Category: String {
        case expedition
        case command
        case center
        case relay
        case component
        case state
        case event
        case dependency
        case adAstra
        case signal
        case metal
        case ml
        case utility
        case network
        case none
        
        var log: OSLog {
            OSLog(subsystem: subsystem, category: self.rawValue)
        }
        
        var helper: String {
            switch self {
            case .expedition:
                return "π₯π₯π₯π₯"
            case .command:
                return "π‘π‘π‘π‘"
            case .center:
                return "ππππ"
            case .relay:
                return "π°π°π°π°"
            case .component:
                return "πΈπΈπΈπΈ"
            case .state:
                return "π½π½π½π½"
            case .event:
                return "ββββ"
            case .dependency:
                return "π¦π¦π¦π¦"
            case .adAstra:
                return "ππππ"
            case .signal:
                return "π₯π₯π₯π₯"
            case .metal:
                return "πΈπΈπΈπΈ"
            case .ml:
                return "π§¬π§¬π§¬π§¬"
            case .utility:
                return "π§π§π§π§"
            case .network:
                return "π¬π¬π¬π¬"
            case .none:
                return "-------"
            }
        }
        
        var disable: Bool {
            return true
//            switch self {
//            case .expedition:
//                return false
//            default:
//                return true
//            }
        }
    }
    
    public class Counters {
        public var command: Int = 0
        
        func update(_ category: GraniteLogger.Category) {
            
            switch category {
            case .command:
                command += 1
            default:
                break
            }
        }
        
        func getLogCount(_ category: GraniteLogger.Category) -> String {
            switch category {
            case .command:
                return " log count: \(command) "
            default:
                return ""
            }
        }
    }
    static var counters: Counters = .init()
    
    static func focusText(_ isFocused: Bool) -> String {
        return isFocused ? "π§ͺ" : ""
    }
    
    public static func info(_ object: Any,
                            _ logger: GraniteLogger.Category = .none,
                            focus: Bool = false,
                            symbol: String = "") {
        guard !logger.disable else { return }//|| focus else { return }
        
        counters.update(logger)
        
        os_log("%@",
               log: logger.log,
               type: .info,
               "\nπ‘π‘π‘π‘π‘π‘\n"+logger.helper+" \(symbol)\(symbol.isEmpty ? "" : " ")\(focusText(focus))\n"+"\(object)"+"\n"+logger.helper+" \(focusText(focus))\nπ‘π‘π‘\(counters.getLogCount(logger))π‘π‘π‘")
    }
    
    public static func info(_ text: String,
                            _ logger: GraniteLogger.Category = .none,
                            focus: Bool = false,
                            symbol: String = "") {
        guard !logger.disable || focus else { return }
        
        counters.update(logger)
        
        os_log("%@",
               log: logger.log,
               type: .info,
               "\nπ‘π‘π‘π‘π‘π‘\n"+logger.helper+" \(symbol)\(symbol.isEmpty ? "" : " ")\(focusText(focus))\n"+text+"\n"+logger.helper+" \(focusText(focus))\nπ‘π‘π‘\(counters.getLogCount(logger))π‘π‘π‘")
    }
    
    public static func debug(_ text: String,
                              _ logger: GraniteLogger.Category,
                              focus: Bool = false,
                              symbol: String = "") {
        guard !logger.disable else { return }
        os_log("%@",
               log: logger.log,
               type: .debug,
               logger.helper+"\(symbol)\(focusText(focus))\n"+text+"\n"+logger.helper+"\nπ‘π‘π‘π‘π‘π‘\(focusText(focus))")
    }
    
    public static func error(_ text: String,
                              _ logger: GraniteLogger.Category,
                              focus: Bool = false,
                              symbol: String = "") {
        guard !logger.disable else { return }
        os_log("%@",
               log: logger.log,
               type: .error,
               logger.helper+"\(symbol)\(focusText(focus))\n"+text+"\n"+logger.helper+"\nπ‘π‘π‘π‘π‘π‘\(focusText(focus))")
    }
}
