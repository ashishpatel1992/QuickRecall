import Cocoa
import SwiftUI

final class PreferencesWindow {
    private var window: NSWindow

    init<Content: View>(content: Content) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 460),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.center()
        window.title = "Preferences"
        window.contentView = NSHostingView(rootView: AnyView(content))
    }

    func show() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
