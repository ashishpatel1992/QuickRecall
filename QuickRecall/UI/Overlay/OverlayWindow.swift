import Cocoa
import SwiftUI

final class OverlayWindow {
    private var window: NSPanel

    var isVisible: Bool { window.isVisible }

    init<Content: View>(content: Content) {
        let hosting = NSHostingController(rootView: content)
        window = NSPanel(contentViewController: hosting)
        window.styleMask = [.titled, .fullSizeContentView]
        window.isOpaque = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.level = .floating
        window.setFrame(NSRect(x: 0, y: 0, width: 680, height: 420), display: false)
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]
    }

    func show() {
        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            let size = window.frame.size
            let origin = NSPoint(x: frame.midX - size.width / 2, y: frame.midY - size.height / 2)
            window.setFrameOrigin(origin)
        }

        // Use NSRunningApplication for more robust activation
        NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])

        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    func close() {
        window.orderOut(nil)
        NSApp.deactivate()
    }
}