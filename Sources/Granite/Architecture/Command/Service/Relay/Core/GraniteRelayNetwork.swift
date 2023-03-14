//
//  GraniteRelayNetwork.swift
//  Granite
//
//  Created by PEXAVC on 12/8/21.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//

//import Foundation
//
///* DEPRECATED */
//
//class GraniteRelayNetwork: Inspectable {
//
//    class Shared {
//        private static let queue = DispatchQueue(label: "granite.relay.network.shared", qos: .background)
//        @ThreadSafe(queue: Shared.queue) var networks: [String: GraniteRelayNetwork] = [:]
//        public func setNetwork(_ network: GraniteRelayNetwork) {
//            _networks.mutate { $0[network.label] = network }
//        }
//    }
//
//    private static let queue = DispatchQueue(label: "granite.relay.network", qos: .background)
//    
//    static let shared: Shared = .init()
//    let label: String
//    let id: UUID = .init()
//    var children: [UUID] = []
//    init(label: String) {
//        self.label = label
//        //Prospector.shared.currentNode?.addChild(id: self.id, label: String(reflecting: Self.self), type: .relayNetwork)
//    }
//
//    func addChild(id: UUID) {
//        children.append(id)
//    }
//
//    func removeChild(id: UUID) {
//        children.removeAll(where: { $0 == id })
//        //If children are 0, automatically deallocate the network
//    }
//
//    static func create(label: String, id: UUID) -> GraniteRelayNetwork {
//        let network: GraniteRelayNetwork
//        if GraniteRelayNetwork.shared.networks[label] == nil {
//            network = .init(label: label)
//            GraniteRelayNetwork.shared.setNetwork(network)
//        } else {
//            network = GraniteRelayNetwork.shared.networks[label] ?? .init(label: label)
//        }
//        network.addChild(id: id)
//        return network
//    }
//
//    public func setState(_ state: AnyGraniteState) {
//        _lastState.mutate { $0 = state }
//    }
//
//    @ThreadSafe(queue: GraniteRelayNetwork.queue) var signal: GraniteSignal.Payload<UUID> = .init()
//    @ThreadSafe(queue: GraniteRelayNetwork.queue) var lastState: AnyGraniteState? = nil
//
//    func bind() {
//        Prospector.shared.push(id: self.id)
//        signal.bind()
//        Prospector.shared.pop()
//    }
//
//    //TODO: Rebind when network is disconnected from last relay
//    func didRemoveObservers() {
//
//    }
//}
