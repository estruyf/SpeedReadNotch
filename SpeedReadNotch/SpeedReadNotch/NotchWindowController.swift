import Cocoa
import SwiftUI

class NotchWindowController: NSObject {
    static let shared = NotchWindowController()
    
    private var panel: NSPanel?
    private var eventMonitor: Any?
    private var eventTap: CFMachPort?
    private var eventTapSource: CFRunLoopSource?
    private var shouldAutoStart: Bool = false
    private var heightObserver: NSObjectProtocol?
    private var widthObserver: NSObjectProtocol?
    private var readingObserver: NSObjectProtocol?
    private var lastScreenFrame: CGRect?
    private var lastMenuBarHeight: CGFloat = 0
    private var isReadingActive: Bool = false
    
    func toggle() {
        if panel != nil {
            dismiss()
        } else {
            // Get text from clipboard
            let text = NSPasteboard.general.string(forType: .string) ?? "No text in clipboard to read."
            show(text: text)
        }
    }
    
    func toggleAndRead() {
        if panel != nil {
            dismiss()
        } else {
            // Get text from clipboard
            let text = NSPasteboard.general.string(forType: .string) ?? "No text in clipboard to read."
            shouldAutoStart = true
            show(text: text)
            shouldAutoStart = false
        }
    }
    
    func showSettings() {
        if panel != nil {
            NotificationCenter.default.post(name: NSNotification.Name("NotchOpenSettings"), object: nil)
            return
        }
        let text = NSPasteboard.general.string(forType: .string) ?? "Settings"
        show(text: text, startWithSettings: true)
    }
    
    func show(text: String, startWithSettings: Bool = false) {
        // Find screen with mouse or main
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let menuBarHeight = screenFrame.maxY - visibleFrame.maxY
        
        lastScreenFrame = screenFrame
        lastMenuBarHeight = menuBarHeight
        
        let overlayView = NotchView(text: text, onDismiss: { [weak self] in
            self?.dismiss()
        }, autoStart: shouldAutoStart, topInset: menuBarHeight, startWithSettings: startWithSettings)
        let hostingView = NSHostingView(rootView: overlayView)
        
        // Dimensions matching DevNotch style
        let notchWidth: CGFloat = 500
        let notchHeight: CGFloat = 90 + menuBarHeight
        
        let x = screenFrame.midX - notchWidth / 2
        // Position below the menu bar with a small extra gap
        let y = screenFrame.maxY - notchHeight + 6
        
        let newPanel = NSPanel(
            contentRect: NSRect(x: x, y: y, width: notchWidth, height: notchHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        newPanel.backgroundColor = .clear
        newPanel.isOpaque = false
        newPanel.hasShadow = true
        newPanel.level = .screenSaver // High level to sit over menu bar
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newPanel.isMovable = false
        newPanel.contentView = hostingView
        newPanel.makeKeyAndOrderFront(nil)
        newPanel.orderFrontRegardless()
        
        self.panel = newPanel
        
        // Listen for notch height changes
        if heightObserver == nil {
            heightObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("NotchHeightChanged"),
                object: nil,
                queue: .main
            ) { [weak self] notif in
                guard let self,
                      let height = notif.userInfo?["height"] as? CGFloat else { return }
                self.updatePanelHeight(height)
            }
        }

        // Listen for notch width changes
        if widthObserver == nil {
            widthObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("NotchWidthChanged"),
                object: nil,
                queue: .main
            ) { [weak self] notif in
                guard let self,
                      let width = notif.userInfo?["width"] as? CGFloat else { return }
                self.updatePanelWidth(width)
            }
        }

        // Listen for reading state changes
        if readingObserver == nil {
            readingObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("NotchReadingStateChanged"),
                object: nil,
                queue: .main
            ) { [weak self] notif in
                guard let self,
                      let isReading = notif.userInfo?["isReading"] as? Bool else { return }
                self.isReadingActive = isReading
            }
        }
        
        // Add keyboard event monitor for spacebar
        setupKeyboardMonitor()
    }
    
    func dismiss() {
        removeKeyboardMonitor()
        if let observer = heightObserver {
            NotificationCenter.default.removeObserver(observer)
            heightObserver = nil
        }
        if let observer = widthObserver {
            NotificationCenter.default.removeObserver(observer)
            widthObserver = nil
        }
        if let observer = readingObserver {
            NotificationCenter.default.removeObserver(observer)
            readingObserver = nil
        }
        isReadingActive = false
        panel?.orderOut(nil)
        panel = nil
    }
    
    private func updatePanelHeight(_ height: CGFloat) {
        guard let panel, let screenFrame = lastScreenFrame else { return }
        var frame = panel.frame
        frame.size.height = height
        frame.origin.y = screenFrame.maxY - height
        panel.setFrame(frame, display: true, animate: true)
    }

    private func updatePanelWidth(_ width: CGFloat) {
        guard let panel, let screenFrame = lastScreenFrame else { return }
        var frame = panel.frame
        frame.size.width = width
        frame.origin.x = screenFrame.midX - width / 2
        panel.setFrame(frame, display: true, animate: true)
    }
    
    private func setupKeyboardMonitor() {
        removeKeyboardMonitor()
        
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 49 { // Spacebar key code
                NotificationCenter.default.post(name: NSNotification.Name("SpacebarPressed"), object: nil)
                return nil // Consume the event
            }
            if event.keyCode == 53 { // Escape key code
                NotificationCenter.default.post(name: NSNotification.Name("NotchEscapePressed"), object: nil)
                return nil
            }
            return event
        }

        setupEventTap()
    }
    
    private func removeKeyboardMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        removeEventTap()
    }

    private func setupEventTap() {
        guard eventTap == nil else { return }
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let controller = Unmanaged<NotchWindowController>.fromOpaque(refcon).takeUnretainedValue()
            return controller.handleEventTap(type: type, event: event)
        }
        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: userInfo
        ) else {
            return
        }
        eventTap = tap
        eventTapSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let source = eventTapSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func removeEventTap() {
        if let source = eventTapSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            eventTapSource = nil
        }
        if let tap = eventTap {
            CFMachPortInvalidate(tap)
            eventTap = nil
        }
    }

    private func handleEventTap(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            if keyCode == 49 && isReadingActive && panel?.isVisible == true {
                NotificationCenter.default.post(name: NSNotification.Name("SpacebarPressed"), object: nil)
                return nil
            }
            if keyCode == 53 && isReadingActive && panel?.isVisible == true {
                NotificationCenter.default.post(name: NSNotification.Name("NotchEscapePressed"), object: nil)
                return nil
            }
        }
        return Unmanaged.passUnretained(event)
    }
}
