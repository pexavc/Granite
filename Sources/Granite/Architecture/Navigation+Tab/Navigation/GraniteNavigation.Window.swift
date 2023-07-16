//
//  GraniteNavigation.Window.swift
//  
//
//  Created by PEXAVC on 7/5/23.
//

public protocol GraniteWindowDelegate {
    func didCloseWindow(_ id: String)
}
#if os(macOS)
import Foundation
import SwiftUI
import AppKit
import Combine

public class GraniteNavigationWindow {
    public static var shared: GraniteNavigationWindow = .init()
    
    fileprivate var windows: [String:GraniteWindow] = [:]
    fileprivate var count: Int = 0
    
    public static var defaultSize: CGSize = .init(width: 360, height: 480)
    public static var backgroundColor: NSColor = .clear
    
    public func addWindow<Content: View>(id: String? = nil,
                                         title: String,
                                         size: CGSize? = nil,
                                         titlebarAware: Bool = false,
                                         isMain: Bool = false,
                                         @ViewBuilder content : (@escaping () -> Content)) {
        
        let windowId: String = id ?? "Window_\(count)"
        let windowSize: CGSize = size ?? GraniteNavigationWindow.defaultSize
        windows[windowId] = .init(id: windowId, isMain: isMain, size: windowSize)
        windows[windowId]?.backgroundColor = GraniteNavigationWindow.backgroundColor
        windows[windowId]?.build(title: title, center: false, show: true) { [weak self] in
            content()
                .frame(minWidth: windowSize.width, minHeight: windowSize.height)
                .padding(.top, titlebarAware ? (self?.windows[windowId]?.titleBarHeight ?? NSWindow.defaultTitleBarHeight) : 0)
        }
        
        self.count = self.windows.keys.count
    }
    
    public func closeWindow(_ id: String) {
        windows[id] = nil
        self.count = self.windows.keys.count
    }
    
    public func containsWindow(_ number: Int) -> Bool {
        return windows.values.first(where: { $0.windowNumber == number }) != nil
    }
}

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
    
    let pubClickedOutside = NotificationCenter.default
        .publisher(for: NSNotification.Name("nyc.stoic.Bullish.ClickedOutside"))
    let pubClickedInside = NotificationCenter.default
        .publisher(for: NSNotification.Name("nyc.stoic.Bullish.ClickedInside"))
    
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
    
    public func build<Content: View>(title: String? = nil,
                              center: Bool = false,
                              show: Bool = false,
                              @ViewBuilder content : (@escaping () -> Content)) {
        DispatchQueue.main.async { [weak self] in
            self?.main = AppWindow(self?.size ?? .zero,
                                   title: title,
                                   center: center,
                                   compact: self?.isAlert == true)
            
            self?.main?.delegate = self
            
            self?.titleBarHeight = self?.main?.titlebarHeight ?? 0
            self?.isPrepared = true
            
            if self?.observeEvents == true {
                self?.observe()
            }
            
            self?.lastUpdate = .init()
            
            self?.main?.backgroundColor = GraniteNavigationWindow.backgroundColor
            
            self?.main?.contentViewController = NSHostingController(rootView: content())
            
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
            main?.close()
            isVisible = false
        } else {
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

class AppWindow: NSWindow {
    
    private var lastPoint: CGPoint? = nil
    
    init(_ size: CGSize,
         title: String? = nil,
         center: Bool = false,
         compact: Bool = false) {
        
        let origin = AppWindow.originPoint(size, newSize: .zero, center: center)
        
        super.init(contentRect: .init(origin: origin, size: size),
                   styleMask: [.fullSizeContentView, .titled, .closable],
                   backing: .buffered,
                   defer: false)
        
        self.lastPoint = origin
        
        isReleasedWhenClosed = false
        hasShadow = true
        isOpaque = false
        
        //        level = .floating
        backgroundColor = .clear
        
        standardWindowButton(.closeButton)?.isHidden = false// compact == true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        
        titlebarAppearsTransparent = true
        
        if let windowTitle = title, compact == false {
            self.title = windowTitle
        }
        //        titleVisibility = .hidden
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
        //        print("[AppWindow] originPoint: \(visibleFrame)")
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
        print("[AppWindow] \(lastPoint ?? .zero) new: \(origin)")
        self.setFrame(.init(origin: origin, size: newSize), display: true)
    }
}

extension NSWindow {
    var titlebarHeight: CGFloat {
        frame.height - contentLayoutRect.height
    }
    
    public static var defaultTitleBarHeight: CGFloat {
        28
    }
}

#endif
