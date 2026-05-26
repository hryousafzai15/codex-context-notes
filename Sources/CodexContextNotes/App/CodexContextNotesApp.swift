import SwiftUI

@main
struct CodexContextNotesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Codex Notes", systemImage: "note.text") {
            Button("Open Current Context") {
                appDelegate.showPanelFromMenu()
            }

            Button("Test Shortcut Path") {
                appDelegate.runShortcutSelfTestFromMenu()
            }

            SettingsLink {
                Text("Settings")
            }

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }

        Settings {
            SettingsView()
        }
    }
}
