import Cocoa

final class StatusBarController {
    private var statusItem: NSStatusItem!
    private let onActivate: () -> Void
    private let onPreferences: () -> Void

    init(onActivate: @escaping () -> Void, onPreferences: @escaping () -> Void) {
        self.onActivate = onActivate
        self.onPreferences = onPreferences

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "text.quote", accessibilityDescription: "QuickRecall") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "QR"
            }
            button.target = self
            button.action = #selector(statusItemClicked)
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open QuickRecall", action: #selector(openOverlay), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Preferences…", action: #selector(openPreferences), keyEquivalent: ","))
        
        menu.addItem(.separator())
        
        // About Section
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "QuickRecall"
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        
        let aboutItem = NSMenuItem(title: "About \(appName)", action: #selector(openAbout), keyEquivalent: "")
        menu.addItem(aboutItem)
        
        let versionItem = NSMenuItem(title: "Version \(version) (\(build))", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        menu.addItem(versionItem)
        
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
    }

    @objc private func statusItemClicked() {
        // Left click shows menu by default
    }

    @objc private func openOverlay() { onActivate() }
    @objc private func openPreferences() { onPreferences() }
    @objc private func openAbout() { NSApp.orderFrontStandardAboutPanel(nil) }
    @objc private func quit() { NSApp.terminate(nil) }
}
