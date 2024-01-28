//
//  GraniteNavigation.Window.swift
//  
//
//  Created by PEXAVC on 7/5/23.
//

public protocol GraniteWindowDelegate {
    func didCloseWindow(_ id: String)
}

import Foundation
import SwiftUI

public struct GraniteRouteWindowProperties {
    public let title: String
    public let style: GraniteNavigationWindowStyle
    public let center: Bool = false
    public let isClosable: Bool = true
    public let isCompact: Bool
    public let isChildWindow: Bool
    public let titlebarAware: Bool = false
    
    public init(title: String = "",
                style: GraniteNavigationWindowStyle = .default,
                isCompact: Bool = false,
                isChildWindow: Bool = false) {
        self.title = title
        self.style = style
        self.isCompact = isCompact
        self.isChildWindow = isChildWindow
    }
    
    public static func child(size: CGSize) -> GraniteRouteWindowProperties {
        return .init(style: .init(size: .init(width: size.width,
                                              height: size.height),
                                  mask: .resizable),
                     isChildWindow: true)
    }
    
    public static func resizable(size: CGSize) -> GraniteRouteWindowProperties {
        return .init(style: .init(size: size, mask: .resizable))
    }
    
    public static func resizable(_ width: CGFloat, _ height: CGFloat) -> GraniteRouteWindowProperties {
        return .init(style: .init(size: .init(width: width, height: height), mask: .resizable))
    }
    
    public func minSize(_ width: CGFloat, _ height: CGFloat) -> GraniteRouteWindowProperties {
        return .init(style: .init(size: self.style.size,
                                  minSize: .init(width: width, height: height),
                                  mask: .resizable))
    }
    
    public func updateCompact(_ state: Bool) -> GraniteRouteWindowProperties {
        .init(title: self.title, style: self.style, isCompact: state)
    }
}

public struct GraniteNavigationWindowStyle {
    var size: CGSize
    var minSize: CGSize
    var mask: NSWindow.StyleMask?
    
    public init(size: CGSize, minSize: CGSize? = nil, mask: NSWindow.StyleMask? = nil) {
        self.size = size
        self.minSize = minSize ?? size
        self.mask = mask
    }
    
    public static var `default`: GraniteNavigationWindowStyle {
        .init(size: GraniteNavigationWindowStyle.defaultSize)
    }
    
    public static var defaultSize: CGSize = .init(width: 360, height: 480)
}

#if os(iOS)
public struct NSWindow {
    public enum StyleMask {
        case resizable
    }
    static var defaultTitleBarHeight: CGFloat {
        0
    }
}
#elseif os(macOS)
import AppKit
import Combine

public class GraniteNavigationWindow {
    public static var shared: GraniteNavigationWindow = .init()
    
    fileprivate var windows: [String : GraniteWindow] = [:]
    fileprivate var count: Int = 0
    
    fileprivate var mainWindowId: String? = nil
    
    public static var defaultSize: CGSize = GraniteNavigationWindowStyle.defaultSize
    public static var backgroundColor: NSColor = .clear
    
    public static var defaultMainWindowId: String = "granite.app.window.main"
    
    public func addWindow<Content: View>(id: String? = nil,
                                         props: GraniteRouteWindowProperties,
                                         isMain: Bool = false,
                                         @ViewBuilder content : (@escaping () -> Content)) {
        
        let windowId: String = id ?? "Window_\(count)"
        let windowSize: CGSize = props.style.size ?? GraniteNavigationWindow.defaultSize
        let minWindowSize: CGSize = props.style.minSize ?? windowSize
        windows[windowId] = .init(id: windowId, isMain: isMain, size: windowSize)
        windows[windowId]?.backgroundColor = GraniteNavigationWindow.backgroundColor
        windows[windowId]?.build(props, show: true) { [weak self] in
            content()
                .padding(.top, props.titlebarAware ? (self?.windows[windowId]?.titleBarHeight ?? NSWindow.defaultTitleBarHeight) : 0)
        }
        
        GraniteLog("Adding window: \(windowId) of size: \(windowSize)", level: .debug)
        
        if isMain {
            mainWindowId = windowId
        }
        
        self.count = self.windows.keys.count
    }
    
    public var mainWindow: GraniteWindow? {
        guard let mainWindowId else {
            return nil
        }
        
        return windows[mainWindowId]
    }
    
    public func updateWidth(_ value: CGFloat, id: String) {
        guard let window = windows[id]?.retrieve() else { return }
        window.setFrame(NSRect(origin: window.frame.origin, size: .init(width: value, height: window.frame.height)), display: true)
    }
    
    public func closeWindow(_ id: String) {
        windows[id] = nil
        self.count = self.windows.keys.count
    }
    
    public func containsWindow(_ number: Int) -> Bool {
        return windows.values.first(where: { $0.windowNumber == number }) != nil
    }
    
    public static func create<Content: View>(isMain: Bool = true,
                                             props: GraniteRouteWindowProperties = .resizable(900, 600).minSize(900, 600),
                                             @ViewBuilder content: @escaping (() -> Content)) {
        GraniteNavigationWindow.shared.addWindow(id: GraniteNavigationWindow.defaultMainWindowId,
                                                 props: props,
                                                 isMain: isMain) {
            content()
        }
    }
}

/// Container to manage the NSWindow and its lifecycle/observers
public class GraniteWindow: NSObject, Identifiable, NSWindowDelegate {
    @Published var isPrepared: Bool = false
    
    public var delegate: GraniteWindowDelegate?
    
    private var main: AppWindow? = nil
    
    private(set) var lastUpdate: Date = .init()
    
    public var backgroundColor: NSColor = .clear {
        didSet {
            main?.backgroundColor = backgroundColor
        }
    }
    
    let size: CGSize
    let isMain: Bool
    let isAlert: Bool
    let maxSize: CGSize
    let observeEvents: Bool
    private(set) var titleBarHeight: CGFloat = 0
    
    private var isVisible: Bool = false
    
    let pubClickedOutside = Granite.App.Interaction.windowClickedOutside.publisher
    let pubClickedInside = Granite.App.Interaction.windowClickedInside.publisher
    
    internal var cancellables = Set<AnyCancellable>()
    
    public var windowNumber: Int {
        main?.windowNumber ?? -1
    }
    
    public let id: String
    
    public init(id: String,
                isMain: Bool = false,
                isAlert: Bool = false,
                size: CGSize = .init(width: 480, height: 640),
                maxSize: CGSize = .init(width: 800, height: 750),
                observeEvents: Bool = false) {
        self.id = id
        self.isMain = isMain
        self.isAlert = isAlert
        self.size = size
        self.maxSize = maxSize
        self.observeEvents = observeEvents
        super.init()
    }
    
    public func build<Content: View>(_ props: GraniteRouteWindowProperties,
                                     show: Bool = false,
                                     @ViewBuilder content : (@escaping () -> Content)) {
        DispatchQueue.main.async { [weak self] in
            self?.main = AppWindow(props.updateCompact(self?.isAlert == true))
            
            self?.main?.delegate = self
            
            self?.titleBarHeight = self?.main?.titlebarHeight ?? 0
            self?.isPrepared = true
            
            if self?.observeEvents == true {
                self?.observe()
            }
            
            self?.lastUpdate = .init()
            
            self?.main?.backgroundColor = GraniteNavigationWindow.backgroundColor
            
            self?.main?.contentViewController = NSHostingController(rootView: content()
                .transformEnvironment(\.graniteNavigationWindowDestinationStyle, transform: { value in
                    value?.titleBarHeight = self?.main?.titlebarHeight ?? NSWindow.defaultTitleBarHeight
                }))
            
            self?.main?.contentMinSize = self?.size ?? .zero
            self?.main?.minSize = self?.size ?? .zero
            self?.main?.setFrame(.init(origin: self?.main?.frame.origin ?? .zero, size: self?.size ?? .zero), display: true)
            
            if show {
                self?.toggle()
                self?.main?.center()
            }
        }
    }
    
    public func windowWillClose(_ notification: Notification) {
        self.isVisible = false
        GraniteNavigationWindow.shared.closeWindow(self.id)
        self.delegate?.didCloseWindow(self.id)
    }
    
    func setSize(_ size: CGSize) {
        let sizeAdjusted: CGSize = .init(width: min(maxSize.width, size.width),
                                         height: min(maxSize.height, size.height + (titleBarHeight + NSWindow.defaultTitleBarHeight)))
        DispatchQueue.main.async { [weak self] in
            self?.main?.setSize(sizeAdjusted, defaultSize: self?.size ?? .zero)
            self?.lastUpdate = .init()
        }
    }
    
    public func toggle() {
        if isVisible {
            GraniteLog("[\(self.id)] hiding: \(self.main?.frame ?? .zero)", level: .debug)
            main?.close()
            isVisible = false
        } else {
            GraniteLog("[\(self.id)] showing: \(self.main?.frame ?? .zero)", level: .debug)
            main?.level = .floating
            main?.makeKeyAndOrderFront(nil)
            main?.level = .normal
            isVisible = true
        }
    }
    
    public func close() {
        main?.close()
        isVisible = false
    }
    
    public func bringToFront() {
        main?.level = .floating
        main?.makeKeyAndOrderFront(nil)
        main?.level = .normal
        isVisible = true
    }
    
    func observe() {
        pubClickedOutside.sink { [weak self] _ in
            guard self?.isVisible == true else { return }
            
            DispatchQueue.main.async { [weak self] in
                self?.main?.close()
                self?.isVisible = false
            }
        }.store(in: &cancellables)
        
        //This will only fire if a registered navigation window is clicked
        //otherwise dismiss all other window types like an alert
        pubClickedInside.sink { [weak self] _ in
            guard self?.isVisible == true else { return }
            
            guard self?.isAlert == true else { return }
            
            DispatchQueue.main.async { [weak self] in
                self?.main?.close()
                self?.isVisible = false
            }
        }.store(in: &cancellables)
    }
    
    public func retrieve() -> NSWindow? {
        self.main
    }
}

public extension NSWindow {
    func graniteStyle(_ props: GraniteRouteWindowProperties) {
        
        var windowStyleMask: NSWindow.StyleMask
        
        if props.isChildWindow {
            windowStyleMask = []
        } else {
            windowStyleMask = [.fullSizeContentView, .titled]
        }
        
        if props.isClosable {
            windowStyleMask.formUnion(.closable)
        }
        
        if let mask = props.style.mask {
            windowStyleMask.formUnion(mask)
        }
        
        self.styleMask = windowStyleMask
        
        isReleasedWhenClosed = false
        hasShadow = true
        isOpaque = false
        
        //        level = .floating
        backgroundColor = .clear
        
        standardWindowButton(.closeButton)?.isHidden = props.isClosable == false// compact == true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        
        titlebarAppearsTransparent = true
        
        if props.isCompact == false {
            self.title = props.title
        }
    }
}

public class AppWindow: NSWindow {
    
    private var lastPoint: CGPoint? = nil
    
    public init(_ props: GraniteRouteWindowProperties) {
        
        let origin: CGPoint
        
        var windowStyleMask: NSWindow.StyleMask
        
        if props.isChildWindow {
            windowStyleMask = []
            origin = .zero
        } else {
            windowStyleMask = [.fullSizeContentView, .titled]
            origin = AppWindow.originPoint(props.style.size, newSize: .zero, center: props.center)
        }
        
        
        if props.isClosable {
            windowStyleMask.formUnion(.closable)
        }
        
        if let mask = props.style.mask {
            windowStyleMask.formUnion(mask)
        }
        
        super.init(contentRect: .init(origin: origin, size: props.style.size),
                   styleMask: windowStyleMask,
                   backing: .buffered,
                   defer: false)
        
        self.lastPoint = origin
        self.graniteStyle(props)
        //        titleVisibility = .hidden
    }
    
    public func setOrigin(_ origin: CGPoint) {
        let size = self.frame.size
        self.setFrame(.init(origin: origin,
                            size: size),
                      display: true)
    }
    
    public func setCenter(_ center: CGPoint) {
        let size = self.frame.size
        self.setFrame(.init(origin: .init(x: center.x - (size.width / 2),
                                          y: center.y - (size.height / 2)),
                            size: size),
                      display: true)
    }
    
    static func originPoint(_ size: CGSize, newSize: CGSize, titleBarHeight: CGFloat = 28, currentMidPoint: CGPoint? = nil, center: Bool = false) -> CGPoint {
        guard let main = NSScreen.main else {
            return .zero
        }
        
        let startingContainer: CGSize = .init(width: size.width, height: size.height + titleBarHeight)
        let newContainer: CGSize = .init(width: newSize.width, height: newSize.height + titleBarHeight)
        
        let visibleFrame = main.visibleFrame
        let startWindowX = (currentMidPoint?.x) ?? ((visibleFrame.midX) - (startingContainer.width / 2))
        let startWindowY = (currentMidPoint?.y) ?? ((visibleFrame.midY) - (startingContainer.height / 2))
        
        var startPoint: CGPoint = .init(x: startWindowX, y: startWindowY)
        if newSize != .zero {
            let diff = newContainer.height - startingContainer.height
            
            startPoint.y -= diff
        } else {
            startPoint.y -= visibleFrame.origin.y
        }
        
        if currentMidPoint == nil {
            if center {
                startPoint.y -= size.height / 2
            } else {
                startPoint.y += (visibleFrame.height / 3) / 2
            }
        }
        
        return startPoint
    }
    
    func newPoint(newSize: CGSize,
                  titleBarHeight: CGFloat = 28,
                  currentMidPoint: CGPoint? = nil) -> CGPoint {
        
        let startingContainer: CGSize = frame.size
        let newContainer: CGSize = .init(width: newSize.width, height: newSize.height)
        
        var startPoint: CGPoint = lastPoint ?? .zero
        
        if newSize != .zero {
            let diff = newContainer.height - startingContainer.height
            
            startPoint.y -= (diff)
        }
        
        lastPoint = startPoint
        
        return startPoint
    }
    
    func setSize(_ newSize: CGSize, defaultSize: CGSize) {
        lastPoint = frame.origin
        let origin: CGPoint = newPoint(newSize: newSize, titleBarHeight: self.titlebarHeight, currentMidPoint: lastPoint)
        
        GraniteLog("old: \(lastPoint ?? .zero), new: \(origin))", level: .debug)
        
        self.setFrame(.init(origin: origin, size: newSize), display: true)
    }
}

extension NSWindow {
    public var titlebarHeight: CGFloat {
        frame.height - contentLayoutRect.height
    }
    
    public static var defaultTitleBarHeight: CGFloat {
        28
    }
}

#endif
