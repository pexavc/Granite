//
//  GraniteCommand.swift
//  Granite
//
//  Created by PEXAVC on 12/12/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

import Foundation
import Combine

extension Storage {
    
    struct CommandIdentifierKey : Hashable {
        let id : String
        let keyPath: AnyKeyPath
    }
    
}

public enum GraniteCommandKind: CustomStringConvertible {
    
    case service(GraniteRelayKind)
    case component
    
    var isOnline: Bool {
        switch self {
        case .service(let kind):
            return kind == .online
        default:
            return false
        }
    }
    
    public var description: String {
        switch self {
        case .service(let relayKind):
            return "🛸\(relayKind == .online ? "[🛰]" : "")"
        case .component:
            return "📡"
        }
    }
}

/*
 A GraniteComponent's and GraniteService's Core event router,
 state manager, and responder.
*/
public class GraniteCommand<Center: GraniteCenter>: Inspectable, Findable, Prospectable, Director, Nameable, ObservableObject {
    public enum BuildBehavior {
        case dependency(AnyGranitePayload?)
        case none
    }
    
    var thread: DispatchQueue {
        .init(label: "\(id)", qos: .background)
    }
    
    internal var cancellables = Set<AnyCancellable>()
    public let id: UUID
    
    public var isOnline: Bool {
        if case .service(.online) = kind {
            return true 
        } else {
            return false
        }
    }
    
    public var isLoaded: Bool {
        center.findStore()?.isLoaded == true
    }
    
    var center: Center
    
    var lifecycle: GraniteLifecycle = .none
    
    var onAppear: [GraniteSignal.Payload<GranitePayload?>]?
    var onDisappear: [GraniteSignal.Payload<GranitePayload?>]?
    var onTask: [GraniteSignal.Payload<GranitePayload?>]?
    var events: [AnyEvent]?
    var didAppear: (() -> Void)?
    var didDisappear: (() -> Void)?
    var runTasks: (() -> Void)?
    
    //@Event public var discoveryDiagnostic: DiagnoseTree<Center>.Reducer
    internal var reducers: [AnyReducerContainer] = []
    internal var notifies: [String: AnyNotify] = [:]
    
    internal var listenersSet: Bool = false
    
    fileprivate var kind: GraniteCommandKind
    public var buildBehavior: BuildBehavior
    
    init(_ kind: GraniteCommandKind, initialCenter: Center? = nil) {
        let id: UUID = .init()
        self.id = id
        self.kind = kind
        self.buildBehavior = .none
        
        Prospector.shared.currentNode?.addChild(id: self.id, label: String(reflecting: Self.self), type: .command)
//        Prospector.shared.currentNode?.addProspector(self.prospector)
        Prospector.shared.push(id: self.id, .command)
        center = initialCenter ?? Center()
        setup()
        Prospector.shared.pop(.command)
    }
    
    deinit {
        lifecycle = .deLink
        removeObservers(includeChildren: true)
    }
    
    func build(_ buildBehavior: BuildBehavior) {
        self.buildBehavior = buildBehavior
    }
    
    func setup() {
        switch kind {
        case .service(.online):
            center.findStore()?.sync()
        case .component:
            center.findStore()?.awake()
        default:
            break
        }
        
        bind()
        observe()
    }
    
    func bind() {
        guard let store = center.findStore() else {
            return
        }
        
        /*
         TODO: MAJOR
         Compile()'s contents is the culprit to slow component
         build times.
         
         This is due to the recursive nature of Event findind in
         @Event nesting
         
         Update: 08/2023
         the change was done a while ago, but preloading service states
         `async` solved slow responsiveness.
         */
        compile()
        
        store.willChange.bind("stateWillChange")
        store.syncSignal.bind("syncStateSignal")
    }
    
    func listen(_ listeners: () -> Void) {
        //only once
        guard !listenersSet else { return }
        listenersSet = true
        Prospector.shared.push(id: self.id, .command)
        listeners()
        Prospector.shared.pop(.command)
        GraniteLog("applying listeners to: \(NAME)", level: .debug)
    }
    
    func observe() {
        guard let store = center.findStore() else { return }
        
        guard let changeSignal = (store.willChange as? GraniteSignal.Payload<Center.GenericGraniteState>) else {
            return
        }
        
        /*
         We want to update the UI with state changes
         Services have relays to handle updates onto the UI
         this, would be redundant
         
         lifecycle observers don't affect services
         */
        
        guard case .component = kind else { return }
        
        changeSignal += { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange.send()
            }
        }
        
        //Observed here, signal sent by Component+View
        didAppear = { [weak self] in
            self?.thread.sync {
                self?.onAppear?.forEach { event in
                //TODO: There is still some sort of lag in transitions
                    
                    switch self?.buildBehavior {
                    case .dependency(let payload):
                        event.send(payload as? GranitePayload)
                    default:
                        event.send(nil)
                    }
                }
            }
            
            self?.lifecycle = .appeared
        }
        
        didDisappear = { [weak self] in
            self?.onDisappear?.forEach { signal in
                signal.send(nil)
            }
            
            self?.lifecycle = .disappeared
        }
        
        runTasks = { [weak self] in
            self?.onTask?.forEach { signal in
                signal.send(nil)
            }
        }
    }
    
    func compile() {
        let setup = center.findCommandSetup()

        let events: [AnyEvent] = setup.events
        let notifies: [AnyNotify] = setup.notifies

        notifies.forEach { notify in
            self.notifies["\(notify.reducerType)"] = notify
        }

        var onAppearEvents: [AnyEvent] = []
        var onDisappearEvents: [AnyEvent] = []
        var onTaskEvents: [AnyEvent] = []
        var otherEvents: [AnyEvent] = []

        for event in events {
            switch event.lifecycle {
            case .onAppear:
                onAppearEvents.append(event)
            case .onDisappear:
                onDisappearEvents.append(event)
            case .onTask:
                onTaskEvents.append(event)
            default:
                otherEvents.append(event)
            }
        }
        
        reducers = (events).compactMap { $0 as? CompileableEvent }.flatMap { $0.compile(self, properties: .init(isOnline: kind.isOnline)) }

        self.onAppear = onAppearEvents.map { $0.signal }
        self.onDisappear = onDisappearEvents.map { $0.signal }
        self.onTask = onTaskEvents.map { $0.signal }
        
        if case .component = kind {
            GraniteLog("\(NAME) \(kind) | [\(reducers.count)] 🛥 | \(self.id)", level: .debug)
        }
    }
    
    public func update(_ state: Center.GenericGraniteState) {
        guard let store = center.findStore() else { return }
        store.wrappedValue = state
    }
    
    public func persistStateChanges() {
        //TODO: Debounce?
        guard let store = center.findStore() else { return }
        if store.autoSave {
            store.projectedValue.persistence.save()
        }
    }
    
    /*
     Notifies allow reducers to be fired based on another's
     completion.
     
     A GraniteComponent can request their reducers to respond
     to a Service's reducer completion, for instance a network
     call that is being made.
    */
    public func notify(_ reducerType: AnyGraniteReducer.Type, payload: AnyGranitePayload?) {
        if let notify = notifies["\(reducerType)"] {
            GraniteLog("\(NAME) \(kind) notify: [\(reducerType)] | Main 🧵?: \(Thread.isMainThread)", level: .debug)
            notify.send(payload)
        }
    }
}

extension GraniteCommand {
    func setServiceOffline() {
        self.kind = .service(.offline)
    }
}

/*
 Director Callbacks to be used in ReducerContainer
*/
extension GraniteCommand {
    
    public func getState() -> AnyGraniteState {
        return center.state
    }
    
    public func setState(_ state: AnyGraniteState) {
        guard let newState = state as? Center.GenericGraniteState else { return }
        
        self.update(newState)
    }
}

extension GraniteCommand {
    public func didRemoveObservers() {
        
    }
}
