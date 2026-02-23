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

            HStack(spacing: 16) {
                Link("View on GitHub", destination: URL(string: Constants.githubRepoURL)!)
                    .font(.system(size: 13))

                Button("Send Feedback") {
                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
                    let subject = "Marksmith v\(version) Feedback".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    if let url = URL(string: "mailto:\(Constants.feedbackEmail)?subject=\(subject)") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .font(.system(size: 13))
                .buttonStyle(.link)
            }
        }
        .padding(32)
        .frame(width: 360, height: 290)
    }
}
