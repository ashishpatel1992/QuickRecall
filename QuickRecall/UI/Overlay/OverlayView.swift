import SwiftUI
import ApplicationServices

struct OverlayView: View {
    @EnvironmentObject var store: SnippetStore
    let onClose: () -> Void
    let onPreferences: () -> Void
    let onInsert: (_ text: String, _ copyOnly: Bool, _ completion: @escaping (Bool) -> Void) -> Void

    enum SearchScope {
        case all
        case title
    }
    
    @State private var searchScope: SearchScope = .all
    @State private var query: String = ""
    @State private var selection: UUID?
    @State private var statusText: String = ""
    @State private var isAccessibilityTrusted: Bool = AXIsProcessTrusted()
    @FocusState private var isFocused: Bool

    var filtered: [Snippet] {
        if query.isEmpty { return store.snippets }
        let q = query.lowercased()
        return store.snippets
            .compactMap { snippet -> (snippet: Snippet, score: Int)? in
                let value = score(snippet, q)
                return value > 0 ? (snippet, value) : nil
            }
            // Break ties by name so the list doesn't reshuffle on every keystroke.
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.snippet.name.localizedCaseInsensitiveCompare(rhs.snippet.name) == .orderedAscending
            }
            .map(\.snippet)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("QuickRecall")
                    .font(.headline)
                    .foregroundColor(.secondary)

                TextField("Search snippets…", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .onSubmit { insertSelected(copyOnly: false) }
                    .background(ListNavigator(snippets: filtered, selection: $selection))
                    .onExitCommand(perform: onClose)
                    .onChange(of: query) { _ in
                        selection = filtered.first?.id
                    }
                
                Menu {
                    Picker(selection: $searchScope, label: EmptyView()) {
                        Text("Full Text").tag(SearchScope.all)
                        Text("Title Only").tag(SearchScope.title)
                    }
                    .pickerStyle(.inline)
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .onChange(of: searchScope) { _ in
                    selection = filtered.first?.id
                }

            }
            .padding(.horizontal)

            if filtered.isEmpty {
                VStack(spacing: 6) {
                    Spacer()
                    Image(systemName: store.snippets.isEmpty ? "tray" : "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text(store.snippets.isEmpty
                         ? "No snippets yet. Add one in Preferences."
                         : "No snippets match “\(query)”")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    List(selection: $selection) {
                        ForEach(filtered) { snip in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(snip.name).font(.headline)
                                    Text(snip.content)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }

                                Spacer()

                                Button("Copy") { performInsertion(snippet: snip, copyOnly: true) }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)

                                Button("Insert") { performInsertion(snippet: snip, copyOnly: false) }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                            }
                            .tag(snip.id)
                            .id(snip.id) // Explicit ID for ScrollViewReader
                        }
                    }
                    .listStyle(.inset)
                    .onChange(of: selection) { newSelection in
                        if let newSelection {
                            withAnimation {
                                proxy.scrollTo(newSelection, anchor: .center)
                            }
                        }
                    }
                }
            }

            if !statusText.isEmpty {
                HStack {
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
            } else if !isAccessibilityTrusted {
                HStack {
                    Text("If paste doesn’t work: 1) Open Accessibility and enable QuickRecall; 2) Close and relaunch QuickRecall; 3) Try again.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
            }
            VStack(spacing: 0) {
                Divider()
                MenuRow(title: "Preferences", shortcut: "⌘ ,") { onPreferences() }
                MenuRow(title: "Quit", shortcut: "⌘ Q") { NSApplication.shared.terminate(nil) }
            }
            .padding(.top, 4)
        }

        .onAppear {
            selection = filtered.first?.id
            // Slight delay to ensure window is ready to accept focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
            isAccessibilityTrusted = AXIsProcessTrusted()
        }
    }

    private func score(_ s: Snippet, _ q: String) -> Int {
        let nameMatch = s.name.lowercased().contains(q)
        let contentMatch = s.content.lowercased().contains(q)
        
        switch searchScope {
        case .all:
            let nameScore = nameMatch ? 2 : 0
            let contentScore = contentMatch ? 1 : 0
            return nameScore + contentScore
        case .title:
            return nameMatch ? 1 : 0
        }
    }

    private func insertSelected(copyOnly: Bool) {
        guard let id = selection ?? filtered.first?.id, let snip = store.snippets.first(where: { $0.id == id }) else {
            statusText = "No snippet selected"
            return
        }
        performInsertion(snippet: snip, copyOnly: copyOnly)
    }

    private func performInsertion(snippet: Snippet, copyOnly: Bool) {
        onInsert(snippet.content, copyOnly) { success in
            DispatchQueue.main.async {
                if success {
                    statusText = copyOnly ? "Copied to clipboard" : "Inserted"
                } else {
                    statusText = "Accessibility permission needed. Open System Settings → Privacy & Security → Accessibility and enable QuickRecall. The text is on your clipboard as a fallback."
                }
            }
        }
    }

}

struct MenuRow: View {
    let title: String
    let shortcut: String
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(isHovering ? .white : .primary)
                Spacer()
                Text(shortcut)
                    .font(.caption)
                    .foregroundColor(isHovering ? .white.opacity(0.8) : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isHovering ? Color.accentColor : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

struct ListNavigator: NSViewRepresentable {
    var snippets: [Snippet]
    @Binding var selection: UUID?

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.hostView = view
        context.coordinator.start()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.hostView = nsView
        context.coordinator.snippets = snippets
        context.coordinator.selectionBinding = $selection
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.stop()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator {
        /// The view we are attached to, used to tell whether a key event belongs to the overlay.
        weak var hostView: NSView?
        var snippets: [Snippet] = []
        var selectionBinding: Binding<UUID?>
        private var monitor: Any?

        init(_ parent: ListNavigator) {
            self.selectionBinding = parent.$selection
            self.snippets = parent.snippets
        }

        deinit {
            stop()
        }

        func start() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self else { return event }
                return self.handle(event: event)
            }
        }

        func stop() {
            guard let monitor else { return }
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }

        func handle(event: NSEvent) -> NSEvent? {
            // Only intercept arrow keys aimed at the overlay window. Without this check the
            // monitor swallows ↑/↓ app-wide, breaking the Preferences list and text editor.
            guard let window = hostView?.window,
                  window.isVisible,
                  event.window === window else { return event }

            // 125 = Down, 126 = Up
            guard event.keyCode == 125 || event.keyCode == 126 else { return event }
            guard !snippets.isEmpty else { return event }

            let isDown = event.keyCode == 125
            let currentID = selectionBinding.wrappedValue
            let index = snippets.firstIndex(where: { $0.id == currentID })

            let newIndex: Int
            switch (index, isDown) {
            case (nil, _):
                newIndex = isDown ? 0 : snippets.count - 1
            case (let current?, true):
                newIndex = min(current + 1, snippets.count - 1)
            case (let current?, false):
                newIndex = max(current - 1, 0)
            }

            if newIndex != index {
                DispatchQueue.main.async {
                    self.selectionBinding.wrappedValue = self.snippets[newIndex].id
                }
            }

            // Consume the event either way so the text cursor doesn't move.
            return nil
        }
    }
}
