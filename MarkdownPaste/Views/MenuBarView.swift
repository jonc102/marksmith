import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button {
            appState.isEnabled.toggle()
        } label: {
            if appState.isEnabled {
                Label("Enabled", systemImage: "checkmark")
            } else {
                Text("Disabled")
            }
        }
        .keyboardShortcut("e", modifiers: [.command])

        Divider()

        if appState.conversionCount > 0 {
            Text("Conversions: \(appState.conversionCount)")
            if let lastDate = appState.lastConversionDate {
                Text("Last: \(lastDate, style: .relative) ago")
            }
        } else {
            Text("No conversions yet")
        }

        Divider()

        SettingsLink {
            Text("Settings...")
        }
        .keyboardShortcut(",", modifiers: [.command])

        Divider()

        Button("Quit MarkdownPaste") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: [.command])
    }
}
