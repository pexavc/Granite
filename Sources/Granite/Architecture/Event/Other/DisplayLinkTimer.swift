//
//  DisplayLinkTimer.swift
//  Marble
//
//  Created by PEXAVC on 8/8/20.
//  Copyright © 2020 Stoic Collective, LLC. All rights reserved.
//


//TODO: This really shouldn't be accessible the way it is in ReduceContainer.swift
//need to encapsulate it correctly so it is a retrievable option with other
//types of throughput modifiers, like debounce, throttle, etc.

import AVFoundation
import Foundation

extension Int {
    public func randomBetween(_ secondNum: Int) -> Int{
        guard secondNum > 0 else { return 0 }
        
        return Int.random(in: self..<secondNum)
    }
}

#if os(iOS)
import UIKit
public typealias GraniteDisplayLink = CADisplayLink

#elseif os(OSX)
import AppKit
public typealias GraniteDisplayLink = CVDisplayLink
#endif

#if canImport(UIKit)
import UIKit

open class DisplayLinkTimer: NSObject {
    var displayLink: GraniteDisplayLink?
    
    var lastTime: CMTime = .zero
    
    var isDownloadingNextPayload: Bool = false
    var isDisplayOnly: Bool = false
    private var consumer: ((DisplayLinkTimer) -> ())? = nil
    
    public let id: UUID = UUID()

    public override init() {
        super.init()
        
        self.isDisplayOnly = true
    }
    
    public func start(_ callback: @escaping (DisplayLinkTimer)  -> Void) {
        self.consumer = callback
        displayLink = GraniteDisplayLink(target: self, selector: #selector(displayLinkDidRefresh))
        displayLink?.preferredFramesPerSecond = 30
        displayLink?.add(to: .main, forMode: .common)
    }
    
    public func stop() {
        displayLink?.invalidate()
        displayLink = nil
        consumer = nil
    }
    
    
    @objc func displayLinkDidRefresh(link: GraniteDisplayLink) {
        
        self.consumer?(self)
    }
}

#elseif os(OSX)
import AppKit
import CoreVideo
import Cocoa

open class DisplayLinkTimer: NSObject {
    lazy var operation: OperationQueue = {
        var op = OperationQueue.init()
        op.qualityOfService = .background
        op.maxConcurrentOperationCount = 1
        op.name = "atlas.frame.operation"
        return op
    }()
    
    var _displayLink: GraniteDisplayLink?
    var _displaySource: DispatchSourceUserDataAdd?
    
    public var consumer: ((DisplayLinkTimer) -> ())?
    var lastTime: CMTime = .zero
    
    var isDownloadingNextPayload: Bool = false
    var isDisplayOnly: Bool = false
    
    public let id: String = UUID().uuidString
    
    public override init() {
        
        
        super.init()
    }
    public func start(_ gameLoop: ((DisplayLinkTimer) -> ())?) {
        self.consumer = gameLoop
        
        _displaySource = DispatchSource.makeUserDataAddSource(queue: DispatchQueue.main)
        _displaySource!.setEventHandler {[weak self] in
            self?.operation.addOperation { [weak self] in
                guard let this = self else { return }
                self?.consumer?(this)
            }
        }
        _displaySource!.resume()
        
        var cvReturn = CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink)
                   
        assert(cvReturn == kCVReturnSuccess)

        cvReturn = CVDisplayLinkSetOutputCallback(_displayLink!, dispatchGameLoop, Unmanaged.passUnretained(_displaySource!).toOpaque())

        assert(cvReturn == kCVReturnSuccess)

        cvReturn = CVDisplayLinkSetCurrentCGDisplay(_displayLink!, CGMainDisplayID () )

        assert(cvReturn == kCVReturnSuccess)
    }
    
    public func start() {
        CVDisplayLinkStart(_displayLink!)
    }
    
    public func stop() {
        CVDisplayLinkStop(_displayLink!)
        _displaySource?.cancel()
        operation.cancelAllOperations()
        _displayLink = nil
        consumer = nil
    }
    
    private let dispatchGameLoop: CVDisplayLinkOutputCallback = {
        displayLink, now, outputTime, flagsIn, flagsOut, displayLinkContext in
    
        let source = Unmanaged<DispatchSourceUserDataAdd>.fromOpaque(displayLinkContext!).takeUnretainedValue()
        source.add(data: 1)
        
    
        return kCVReturnSuccess
    }
    
    
    @objc func displayLinkDidRefresh(link: GraniteDisplayLink) {
        guard _displayLink != nil else {
            CVDisplayLinkStop(link)
            return
        }
        operation.addOperation { [weak self] in
            self?.update()
        }
    }
    
    func update() {
        consumer?(self)
    }
}



//*************** NETWORK/DB POWERED *******************/

//if  (currentPayload == nil || payloadFetchIndex >= payloadFetchLimit-1) &&
//    !isDownloadingNextPayload {
//
//    isDownloadingNextPayload = true
//
//
//    if  cache.keys.contains(currentContributionIndex),
//        let cachedPayload = cache[currentContributionIndex] {
//        self.upcomingPayload = cachedPayload
//        update()
//    } else {
//        AtlasCommands.download(
//            index: currentContributionIndex) {
//                (depthPayload, skinPayload, atlasPayload) in
//
//                self.upcomingPayload = (depthPayload, skinPayload, atlasPayload)
//                self.cache.updateValue(self.upcomingPayload, forKey: self.currentContributionIndex)
//                self.update()
//        }
//    }
//}
//
//if  let depthPayload = currentPayload?.0,
//    let skinPayload = currentPayload?.1,
//    let atlasPayload = currentPayload?.2{
//
//    consumer(depthPayload, skinPayload, atlasPayload)
//}
#endif
