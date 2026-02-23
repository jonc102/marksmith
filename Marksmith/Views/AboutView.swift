import SwiftUI

struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 80, height: 80)

            VStack(spacing: 4) {
                Text(Constants.appName)
                    .font(.system(size: 18, weight: .semibold))
                Text("Version \(appVersion)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Text("Clipboard monitor that converts Markdown to rich text on copy.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Link("View on GitHub", destination: URL(string: "https://github.com/jonc102/marksmith")!)
                .font(.system(size: 13))
        }
        .padding(32)
        .frame(width: 360, height: 260)
    }
}
