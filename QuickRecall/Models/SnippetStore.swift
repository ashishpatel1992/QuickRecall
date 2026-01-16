import Foundation
import Combine

final class SnippetStore: ObservableObject {
    @Published var snippets: [Snippet] = [] {
        didSet { save() }
    }

    private let folderURL: URL
    private let fileURL: URL

    init() {
        let fm = FileManager.default
        folderURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("QuickRecall", isDirectory: true)
        fileURL = folderURL.appendingPathComponent("snippets.json")
        load()
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
                save()
            }
        } catch {
            print("SnippetStore load error: \(error)")
            snippets = []
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(snippets)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("SnippetStore save error: \(error)")
        }
    }
}
