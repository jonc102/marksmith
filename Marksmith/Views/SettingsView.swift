import SwiftUI
import AppKit

// MARK: - Sidebar Tab Enum

enum SettingsTab: String, CaseIterable, Hashable {
    case general = "General"
    case detection = "Detection"
    case support = "Support"

    var icon: String {
        switch self {
        case .general:   return "gear"
        case .detection: return "magnifyingglass"
        case .support:   return "heart"
        }
    }
}

// MARK: - Reusable Components

struct SettingsSidebarItem: View {
    let tab: SettingsTab
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: tab.icon)
                .frame(width: 16)
            Text(tab.rawValue)
                .font(.system(size: 13))
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.primary.opacity(0.08) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

struct SettingsCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.controlBackgroundColor))
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct SettingToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 6).fill(iconColor))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

struct PickerOption {
    let label: String
    let tag: Int
}

struct SettingPickerRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    @Binding var selection: Int
    let options: [PickerOption]

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 6).fill(iconColor))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Picker("", selection: $selection) {
                ForEach(options, id: \.tag) { option in
                    Text(option.label).tag(option.tag)
                }
            }
            .pickerStyle(.segmented)
            .fixedSize()
            .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

struct SettingLinkRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 6).fill(iconColor))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture { action() }
    }
}

struct SettingSliderRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let valueLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(RoundedRectangle(cornerRadius: 6).fill(iconColor))

                Text(title)
                    .font(.system(size: 13, weight: .medium))

                Spacer()

                Text(valueLabel)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Slider(value: $value, in: range, step: step)
                .padding(.leading, 40)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Main Settings View

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar (200px)
            VStack(alignment: .leading, spacing: 2) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    SettingsSidebarItem(tab: tab, isSelected: selectedTab == tab)
                        .onTapGesture { selectedTab = tab }
                }
                Spacer()
            }
            .padding(8)
            .frame(width: 220)
            .frame(maxHeight: .infinity)
            .background(Color(.windowBackgroundColor))

            Divider()

            // Content area
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 744, height: 380)
    }

    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .general:
            GeneralSettingsView()
                .environmentObject(appState)
        case .detection:
            DetectionSettingsView()
                .environmentObject(appState)
        case .support:
            SupportSettingsView()
        }
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
                Text("General")
                    .font(.system(size: 20, weight: .bold))
                    .padding(.bottom, 4)

                SettingsCard {
                    SettingToggleRow(
                        icon: "power",
                        iconColor: .green,
                        title: "Enable Marksmith",
                        description: "Monitor clipboard and convert Markdown automatically",
                        isOn: $appState.isEnabled
                    )

                    Divider().padding(.leading, 54)

                    SettingToggleRow(
                        icon: "arrow.up.to.line",
                        iconColor: .blue,
                        title: "Launch at Login",
                        description: "Start Marksmith when you log in",
                        isOn: $appState.launchAtLogin
                    )

                    Divider().padding(.leading, 54)

                    SettingToggleRow(
                        icon: "doc.richtext",
                        iconColor: .orange,
                        title: "Include RTF Format",
                        description: "Enables pasting in more apps; may slightly alter formatting",
                        isOn: $appState.includeRTF
                    )

                    Divider().padding(.leading, 54)

                    SettingPickerRow(
                        icon: "textformat.size",
                        iconColor: .indigo,
                        title: "Output Font Size",
                        description: "Adjusts the font size of converted rich text",
                        selection: $appState.baseFontSize,
                        options: [
                            PickerOption(label: "Small", tag: 12),
                            PickerOption(label: "Medium", tag: 14),
                            PickerOption(label: "Large", tag: 18)
                        ]
                    )
                }

                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Detection Settings

struct DetectionSettingsView: View {
    @EnvironmentObject var appState: AppState

    private var sensitivityLabel: String {
        switch appState.detectionSensitivity {
        case 1: return "Very Aggressive (threshold: 1)"
        case 2: return "Normal (threshold: 2)"
        case 3: return "Moderate (threshold: 3)"
        case 4: return "Conservative (threshold: 4)"
        case 5: return "Very Conservative (threshold: 5)"
        default: return "Normal (threshold: \(appState.detectionSensitivity))"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detection")
                .font(.system(size: 20, weight: .bold))
                .padding(.bottom, 4)

            SettingsCard {
                SettingSliderRow(
                    icon: "slider.horizontal.3",
                    iconColor: .blue,
                    title: "Detection Sensitivity",
                    value: Binding(
                        get: { Double(appState.detectionSensitivity) },
                        set: { appState.detectionSensitivity = Int($0) }
                    ),
                    range: 1...5,
                    step: 1,
                    valueLabel: sensitivityLabel
                )
            }

            Text("Lower values detect more content as Markdown (may cause false positives). Higher values require more Markdown patterns before converting.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Support Settings

struct SupportSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Support")
                .font(.system(size: 20, weight: .bold))
                .padding(.bottom, 4)

            Text("Thank you for using Marksmith! If you find it useful, consider supporting its development.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            SettingsCard {
                SettingLinkRow(
                    icon: "heart.fill",
                    iconColor: .yellow,
                    title: "Buy Me a Coffee",
                    description: "If you enjoy Marksmith, consider supporting its development.",
                    action: {
                        if let url = URL(string: "https://buymeacoffee.com/jonc102") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                )

                Divider().padding(.leading, 54)

                SettingLinkRow(
                    icon: "ladybug",
                    iconColor: .red,
                    title: "Report a Bug",
                    description: "Found something broken? Let us know on GitHub.",
                    action: {
                        if let url = URL(string: "\(Constants.githubIssuesURL)/new?template=bug_report.md") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                )

                Divider().padding(.leading, 54)

                SettingLinkRow(
                    icon: "lightbulb",
                    iconColor: .purple,
                    title: "Request a Feature",
                    description: "Have an idea? We'd love to hear it.",
                    action: {
                        if let url = URL(string: "\(Constants.githubIssuesURL)/new?template=feature_request.md") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                )
            }

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
