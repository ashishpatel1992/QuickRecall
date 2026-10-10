import Foundation
import os

enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.quickrecall.app"

    static let app = Logger(subsystem: subsystem, category: "App")
    static let store = Logger(subsystem: subsystem, category: "SnippetStore")
    static let insertion = Logger(subsystem: subsystem, category: "Insertion")
    static let preferences = Logger(subsystem: subsystem, category: "Preferences")
}
