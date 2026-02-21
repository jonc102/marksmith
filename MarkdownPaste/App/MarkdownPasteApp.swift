import SwiftUI

@main
struct MarkdownPasteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        MenuBarExtra("MarkdownPaste", image: "MenuBarIcon") {
            MenuBarView()
                .environmentObject(appState)
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
