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
        // No main window. Preferences are shown via custom window.
        Settings {
            PreferencesView()
                .environmentObject(appDelegate.snippetStore)
        }
    }
}

extension KeyboardShortcuts.Name {
    static let toggleQuickRecall = Self("toggleQuickRecall")
}
