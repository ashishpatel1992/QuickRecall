import SwiftUI
import KeyboardShortcuts
import ServiceManagement

struct PreferencesView: View {
    @EnvironmentObject var store: SnippetStore

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchAtLoginError: String?

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
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(isOn: $launchAtLogin) {
                        Text("Launch at login")
                    }
                    .onChange(of: launchAtLogin) { newValue in
                        setLaunchAtLogin(newValue)
                    }

                    if let launchAtLoginError {
                        Text(launchAtLoginError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(8)
            }

            Spacer()
        }
        .padding(20)
        .frame(minWidth: 680, minHeight: 420)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        let isCurrentlyEnabled = SMAppService.mainApp.status == .enabled
        // Also stops the revert below from re-entering this handler.
        guard enabled != isCurrentlyEnabled else { return }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginError = nil
        } catch {
            Log.preferences.error("Failed to toggle launch at login: \(error.localizedDescription, privacy: .public)")
            launchAtLoginError = "Couldn't update launch at login: \(error.localizedDescription). This usually requires QuickRecall to be signed and located in /Applications."
            launchAtLogin = isCurrentlyEnabled
        }
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

            if let id = selection, store.snippets.contains(where: { $0.id == id }) {
                EditorDetailView(snippet: binding(for: id))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack { Text("Select or add a snippet") }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(0)
    }

    /// Binds by identity rather than array index, so reordering or deleting a snippet
    /// can never leave the editor pointing at the wrong row or out of bounds.
    private func binding(for id: UUID) -> Binding<Snippet> {
        Binding(
            get: { store.snippets.first(where: { $0.id == id }) ?? Snippet(id: id, name: "", content: "") },
            set: { newValue in
                guard let index = store.snippets.firstIndex(where: { $0.id == id }) else { return }
                store.snippets[index] = newValue
            }
        )
    }

    func add() {
        let new = Snippet(name: "New Snippet", content: "")
        store.snippets.append(new)
        selection = new.id
    }

    func deleteSelected() {
        guard let id = selection else { return }
        selection = nil
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
