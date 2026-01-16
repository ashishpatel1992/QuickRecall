import SwiftUI
import KeyboardShortcuts
import ServiceManagement

struct PreferencesView: View {
    @EnvironmentObject var store: SnippetStore

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("QuickRecall Preferences").font(.title2).padding(.bottom, 8)

            GroupBox(label: Text("Global Shortcut")) {
                HStack {
                    Text("Open overlay:")
                    KeyboardShortcuts.Recorder(for: .toggleQuickRecall)
                    Spacer()
                }.padding(8)
            }

            GroupBox(label: Text("Snippets")) {
                SnippetsEditorView()
                    .environmentObject(store)
                    .frame(minHeight: 240)
            }

            GroupBox(label: Text("General")) {
                Toggle(isOn: $launchAtLogin) {
                    Text("Launch at login")
                }
                .onChange(of: launchAtLogin) { newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        print("Failed to toggle launch at login: \(error)")
                    }
                }
                .padding(8)
            }

            Spacer()
        }
        .padding(20)
        .frame(minWidth: 680, minHeight: 420)
    }
}

struct SnippetsEditorView: View {
    @EnvironmentObject var store: SnippetStore
    @State private var selection: UUID?

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                List(selection: $selection) {
                    ForEach(store.snippets) { snip in
                        Text(snip.name).tag(snip.id)
                    }
                }
                .frame(minWidth: 220)
                
                Divider()
                
                HStack(spacing: 0) {
                    Button(action: add) {
                        Image(systemName: "plus")
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    
                    Button(action: deleteSelected) {
                        Image(systemName: "minus")
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .disabled(selection == nil)
                    
                    Spacer()
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
            }
            .frame(width: 220)

            Divider()

            if let id = selection, let idx = store.snippets.firstIndex(where: { $0.id == id }) {
                // Safer binding that checks bounds to prevent crashes during deletion
                let binding = Binding(
                    get: { 
                        if store.snippets.indices.contains(idx) {
                            return store.snippets[idx]
                        } else {
                            return Snippet(name: "", content: "") // Fallback
                        }
                    },
                    set: { 
                        if store.snippets.indices.contains(idx) {
                            store.snippets[idx] = $0 
                        }
                    }
                )
                EditorDetailView(snippet: binding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack { Text("Select or add a snippet") }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(0)
    }

    func add() {
        let new = Snippet(name: "New Snippet", content: "")
        store.snippets.append(new)
        selection = new.id
    }

    func deleteSelected() {
        guard let id = selection else { return }
        
        // 1. Deselect first to detach the DetailView binding immediately
        selection = nil
        
        // 2. Remove the item from the store. 
        // We use removeAll(where:) for safety instead of index.
        // Doing this ensures we don't need to worry about index validity.
        // We do it immediately; if the previous 'selection = nil' triggered a render,
        // the DetailView should already be gone or tearing down.
        // If we still see crashes, we can wrap this in DispatchQueue.main.async
        store.snippets.removeAll { $0.id == id }
    }
}

struct EditorDetailView: View {
    @Binding var snippet: Snippet

    var body: some View {
        Form {
            TextField("Name", text: $snippet.name)
            TextEditor(text: $snippet.content)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 200)
        }
        .padding(8)
    }
}
