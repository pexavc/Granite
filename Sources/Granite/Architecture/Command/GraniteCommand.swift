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

public enum GraniteCommandKind {
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
}

/*
 A GraniteComponent's and GraniteService's Core event router,
 state manager, and responder.
*/
public class GraniteCommand<Center: GraniteCenter>: Inspectable, Findable, Prospectable, Director, ObservableObject {
    public enum BuildBehavior {
        case dependency(AnyGranitePayload?)
        case none
    }
    
    var thread: DispatchQueue {
        .init(label: "\(id)", qos: .background)
    }
    
    internal var cancellables = Set<AnyCancellable>()
    public let id: UUID
    
    public var isLoaded: Bool {
        center.findStore()?.isLoaded == true
    }
    
    var center: Center
    
    var lifecycle: GraniteLifecycle = .none
    
    var onAppear: [GraniteSignal.Payload<GranitePayload?>]?
    var onDisappear: [GraniteSignal.Payload<GranitePayload?>]?
    var events: [AnyEvent]?
    var didAppear: (() -> Void)?
    var didDisappear: (() -> Void)?
    
    //@Event public var discoveryDiagnostic: DiagnoseTree<Center>.Reducer
    internal var reducers: [AnyReducerContainer] = []
    internal var notifies: [String: AnyNotify] = [:]
    
    fileprivate var kind: GraniteCommandKind
    fileprivate var buildBehavior: BuildBehavior
    
    init(_ kind: GraniteCommandKind) {
        let id: UUID = .init()
        self.id = id
        self.kind = kind
        self.buildBehavior = .none
        
        Prospector.shared.currentNode?.addChild(id: self.id, label: String(reflecting: Self.self), type: .command)
//        Prospector.shared.currentNode?.addProspector(self.prospector)
        Prospector.shared.push(id: self.id, .command)
        center = Center()
        setup()
        Prospector.shared.pop(.command)
    }
    
    deinit {
        lifecycle = .deLink
        removeObservers()
    }
    
    func build(_ buildBehavior: BuildBehavior) {
        self.buildBehavior = buildBehavior
    }
    
    func setup() {
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
         */
        compile()
//        self.events = center.findEvents()
//        for event in events ?? [] {
//            event.intermediateSignal += { value in
//                Prospector.shared.push(id: self.id, .command)
//                if let compiledEvent = event as? CompileableEvent {
//                    let containers = compiledEvent.compile(self, properties: .init(isOnline: self.kind.isOnline))
//                    self.reducers.removeAll(where: { container in containers.map { $0.label }.contains(container.label) })
//                    self.reducers.append(contentsOf: containers)
//                    event.signal.send(value)
//                }
//                Prospector.shared.pop(.command)
//            }
//        }
        
        store.willChange.bind("stateWillChange")
    }
    
    func observe() {
        guard let store = center.findStore() else { return }
        
        guard let changeSignal = (store.willChange as? GraniteSignal.Payload<Center.GenericGraniteState>) else {
            return
        }
        
        changeSignal += { [weak self] _ in
            self?.objectWillChange.send()
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
        var otherEvents: [AnyEvent] = []

        for event in events {
            switch event.lifecycle {
            case .onAppear:
                onAppearEvents.append(event)
            case .onDisappear:
                onDisappearEvents.append(event)
            default:
                otherEvents.append(event)
            }
        }
        
        reducers = (events).compactMap { $0 as? CompileableEvent }.flatMap { $0.compile(self, properties: .init(isOnline: kind.isOnline)) }

        self.onAppear = onAppearEvents.map { $0.signal }
        self.onDisappear = onDisappearEvents.map { $0.signal }
        
        if case .component = kind {
            print("{TEST} \(String(reflecting: Self.self)) \(self.reducers.count) \(self.id)")
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
        print("{TEST} \(String(reflecting: Self.self)) \(reducerType) \(CFAbsoluteTimeGetCurrent()) // isMain: \(Thread.isMainThread)")
        notifies["\(reducerType)"]?.send(payload)
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
