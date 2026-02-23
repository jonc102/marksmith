import SwiftUI

@main
struct MarksmithApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        MenuBarExtra("Marksmith", image: "MenuBarIcon") {
            MenuBarView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appState)
        }

        Window("About Marksmith", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
    }
}
