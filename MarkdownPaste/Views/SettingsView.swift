import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            GeneralSettingsView()
                .environmentObject(appState)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            DetectionSettingsView()
                .environmentObject(appState)
                .tabItem {
                    Label("Detection", systemImage: "magnifyingglass")
                }
        }
        .frame(width: 400, height: 250)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Toggle("Enable MarkdownPaste", isOn: $appState.isEnabled)
                .toggleStyle(.switch)

            Toggle("Launch at Login", isOn: $appState.launchAtLogin)
                .toggleStyle(.switch)

            Toggle("Include RTF format", isOn: $appState.includeRTF)
                .toggleStyle(.switch)

            Text("When RTF is included, pasting works in more apps but may produce slightly different formatting.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
    }
}

struct DetectionSettingsView: View {
    @EnvironmentObject var appState: AppState

    private var sensitivityLabel: String {
        switch appState.detectionSensitivity {
        case 1: return "Very Aggressive"
        case 2: return "Normal"
        case 3: return "Moderate"
        case 4: return "Conservative"
        case 5: return "Very Conservative"
        default: return "Normal"
        }
    }

    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 12) {
                Text("Detection Sensitivity")
                    .font(.headline)

                HStack {
                    Text("Aggressive")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Slider(
                        value: Binding(
                            get: { Double(appState.detectionSensitivity) },
                            set: { appState.detectionSensitivity = Int($0) }
                        ),
                        in: 1...5,
                        step: 1
                    )

                    Text("Conservative")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("Current: \(sensitivityLabel) (threshold: \(appState.detectionSensitivity))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                Text("Lower values detect more content as Markdown (may cause false positives). Higher values require more Markdown patterns to be present before converting.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
    }
}
