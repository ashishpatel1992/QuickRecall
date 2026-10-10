import Foundation
import Combine

final class SnippetStore: ObservableObject {
    @Published var snippets: [Snippet] = [] {
        didSet {
            guard isLoaded, snippets != oldValue else { return }
            scheduleSave()
        }
    }

    private let folderURL: URL
    private let fileURL: URL
    private let ioQueue = DispatchQueue(label: "com.quickrecall.snippetstore.io", qos: .utility)
    private var pendingSave: DispatchWorkItem?
    private var isLoaded = false

    /// Typing in the snippet editor mutates `snippets` on every keystroke; coalesce the writes.
    private let saveDebounce: TimeInterval = 0.5

    init() {
        let fm = FileManager.default
        folderURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("QuickRecall", isDirectory: true)
        fileURL = folderURL.appendingPathComponent("snippets.json")
        load()
        isLoaded = true
    }

    func load() {
        let fm = FileManager.default
        do {
            if !fm.fileExists(atPath: folderURL.path) {
                try fm.createDirectory(at: folderURL, withIntermediateDirectories: true)
            }
            if fm.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                snippets = try JSONDecoder().decode([Snippet].self, from: data)
            } else {
                snippets = [
                    Snippet(name: "Hello World", content: "echo Hello, world!"),
                    Snippet(name: "Email", content: "user@example.com")
                ]
                write(snippets)
            }
        } catch {
            Log.store.error("Failed to load snippets: \(error.localizedDescription, privacy: .public)")
            snippets = []
        }
    }

    /// Writes any pending changes immediately. Call before the app terminates.
    func flush() {
        pendingSave?.cancel()
        pendingSave = nil
        let snapshot = snippets
        ioQueue.sync { self.write(snapshot) }
    }

    private func scheduleSave() {
        pendingSave?.cancel()
        let snapshot = snippets
        let work = DispatchWorkItem { [weak self] in
            self?.write(snapshot)
        }
        pendingSave = work
        ioQueue.asyncAfter(deadline: .now() + saveDebounce, execute: work)
    }

    private func write(_ snippets: [Snippet]) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(snippets)
            try data.write(to: fileURL, options: .atomic)
            // Snippets can hold secrets; keep the file readable by the owner only.
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: fileURL.path
            )
        } catch {
            Log.store.error("Failed to save snippets: \(error.localizedDescription, privacy: .public)")
        }
    }
}
