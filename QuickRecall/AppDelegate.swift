import Cocoa
import SwiftUI
import KeyboardShortcuts
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var statusBarController: StatusBarController!
    private(set) var overlayWindow: OverlayWindow!
    private(set) var preferencesWindow: PreferencesWindow!
    private var previousApp: NSRunningApplication?
    let snippetStore = SnippetStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize windows
        overlayWindow = OverlayWindow(content: OverlayView(
            onClose: { [weak self] in
                self?.toggleOverlay()
            },
            onPreferences: { [weak self] in
                self?.openPreferences()
            },
            onInsert: { [weak self] text, copyOnly, completion in
                self?.insert(text: text, copyOnly: copyOnly, completion: completion)
            }
        )
        .environmentObject(snippetStore))
        preferencesWindow = PreferencesWindow(content: PreferencesView()
            .environmentObject(snippetStore))

        // Status bar
        statusBarController = StatusBarController(onActivate: { [weak self] in
            self?.toggleOverlay()
        }, onPreferences: { [weak self] in
            self?.openPreferences()
        })

        // Global Shortcut
        KeyboardShortcuts.onKeyUp(for: .toggleQuickRecall) { [weak self] in
            self?.toggleOverlay()
        }

        // One-time onboarding if Accessibility is not trusted
        if !AXIsProcessTrusted() {
            showAccessibilityOnboarding()
        }
    }

    private func showAccessibilityOnboarding() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "QuickRecall needs Accessibility to paste snippets"
        alert.informativeText = "Enable QuickRecall in System Settings → Privacy & Security → Accessibility, then quit and relaunch QuickRecall to apply the permission. You can still use Copy-only without it."
        alert.addButton(withTitle: "Open Settings…")
        alert.addButton(withTitle: "Later")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    func toggleOverlay() {
        if overlayWindow.isVisible {
            overlayWindow.close()
        } else {
            previousApp = resolveTargetApp()
            overlayWindow.show()
        }
    }

    /// The app that should receive the paste. Never QuickRecall itself — when the overlay is
    /// opened from the status bar we are already frontmost, so fall back to the last known target.
    private func resolveTargetApp() -> NSRunningApplication? {
        guard let front = NSWorkspace.shared.frontmostApplication,
              front.processIdentifier != ProcessInfo.processInfo.processIdentifier,
              front.bundleIdentifier != Bundle.main.bundleIdentifier else {
            return previousApp
        }
        return front
    }

    func openPreferences() {
        if overlayWindow.isVisible {
            overlayWindow.close()
        }
        preferencesWindow.show()
    }

    func insert(text: String, copyOnly: Bool, completion: @escaping (Bool) -> Void) {
        overlayWindow.close()

        guard let targetApp = previousApp, !targetApp.isTerminated else {
            InsertionManager.insert(text: text, copyOnly: copyOnly, completion: completion)
            return
        }

        // Reactivate the previously focused app
        targetApp.activate(options: [.activateIgnoringOtherApps])

        func attemptPaste(remaining: Int) {
            let front = NSWorkspace.shared.frontmostApplication
            if front?.processIdentifier == targetApp.processIdentifier {
                // Now that target app is frontmost, perform paste
                InsertionManager.insert(text: text, copyOnly: copyOnly) { success in
                    completion(success)
                }
            } else if remaining > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    attemptPaste(remaining: remaining - 1)
                }
            } else {
                // Timeout: attempt paste anyway
                InsertionManager.insert(text: text, copyOnly: copyOnly) { success in
                    completion(success)
                }
            }
        }

        // Poll up to ~1s waiting for focus to switch back to target app
        attemptPaste(remaining: 20)
    }

    func applicationWillTerminate(_ notification: Notification) {
        snippetStore.flush()
    }

}
