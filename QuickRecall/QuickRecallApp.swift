import SwiftUI
import KeyboardShortcuts

@main
struct QuickRecallApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        // Set default shortcut: ⌘⇧Space
        if KeyboardShortcuts.getShortcut(for: .toggleQuickRecall) == nil {
            KeyboardShortcuts.setShortcut(.init(.space, modifiers: [.command, .shift]), for: .toggleQuickRecall)
        }
    }

    var body: some Scene {
        // QuickRecall is an LSUIElement app: there is no main window, and Preferences are
        // presented by AppDelegate via PreferencesWindow. SwiftUI still requires a Scene,
        // so this placeholder stands in for one.
        Settings {
            EmptyView()
        }
    }
}

extension KeyboardShortcuts.Name {
    static let toggleQuickRecall = Self("toggleQuickRecall")
}
