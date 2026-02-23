import SwiftUI

// MARK: - Settings Button (macOS 14+)

@available(macOS 14, *)
private struct SettingsButton: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        MenuBarActionRow(label: "Settings...", shortcut: "⌘,") {
            NSApplication.shared.activate()
            openSettings()
            DispatchQueue.main.async {
                if let settingsWindow = NSApp.windows.first(where: { $0.canBecomeKey && $0.isVisible }) {
                    settingsWindow.makeKeyAndOrderFront(nil)
                }
            }
        }
        .keyboardShortcut(",", modifiers: [.command])
    }
}

// MARK: - Reusable Action Row

private struct MenuBarActionRow: View {
    let label: String
    let shortcut: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 13))
                Spacer()
                Text(shortcut)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isHovered ? Color.primary.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Menu Bar View

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {

            // Enable toggle row
            HStack(spacing: 10) {
                Text("Marksmith")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Toggle("", isOn: $appState.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // Conversion stats
            Group {
                if appState.conversionCount > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Conversions: \(appState.conversionCount)")
                        if let lastDate = appState.lastConversionDate {
                            Text("Last: \(lastDate, style: .relative) ago")
                        }
                    }
                } else {
                    Text("No conversions yet")
                }
            }
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            Divider()

            // About
            MenuBarActionRow(label: "About Marksmith", shortcut: "") {
                NSApplication.shared.activate()
                openWindow(id: "about")
            }

            // Settings
            if #available(macOS 14, *) {
                SettingsButton()
            } else {
                SettingsLink {
                    HStack {
                        Text("Settings...")
                            .font(.system(size: 13))
                        Spacer()
                        Text("⌘,")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                }
                .keyboardShortcut(",", modifiers: [.command])
            }

            // Quit
            MenuBarActionRow(label: "Quit Marksmith", shortcut: "⌘Q") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])

            Spacer().frame(height: 6)
        }
        .frame(width: 240)
    }
}
