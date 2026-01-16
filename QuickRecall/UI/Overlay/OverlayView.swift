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
        return store.snippets.sorted { score($0, q) > score($1, q) }
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

            }
            .padding(.horizontal)

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
        let view = NSView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.snippets = snippets
        context.coordinator.selectionBinding = _selection
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator {
        var snippets: [Snippet] = []
        var selectionBinding: Binding<UUID?>
        var monitor: Any?

        init(_ parent: ListNavigator) {
            self.selectionBinding = parent._selection
            self.snippets = parent.snippets
            
            self.monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self = self else { return event }
                return self.handle(event: event)
            }
        }

        deinit {
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
            }
        }

        func handle(event: NSEvent) -> NSEvent? {
            guard event.keyCode == 125 || event.keyCode == 126 else { return event }
            
            // 125 = Down, 126 = Up
            let isDown = event.keyCode == 125
            
            guard !snippets.isEmpty else { return event }
            
            let currentID = selectionBinding.wrappedValue
            let index = snippets.firstIndex(where: { $0.id == currentID }) ?? -1
            
            var newIndex = index
            if isDown {
                newIndex = min(index + 1, snippets.count - 1)
                // If nothing was selected, select first
                if index == -1 { newIndex = 0 }
            } else {
                newIndex = max(index - 1, 0)
                // If nothing was selected, select last? Or first? Let's say first.
                if index == -1 { newIndex = 0 }
            }
            
            if newIndex != index {
                DispatchQueue.main.async {
                    self.selectionBinding.wrappedValue = self.snippets[newIndex].id
                }
                return nil // Consume event
            }
            
            return nil // Consume event even if we didn't move (e.g. at top/bottom) to prevent cursor move
        }
    }
}
