//
//  PrivacyPolicyView.swift
//  PoseGuard (3.0)
//

import SwiftUI

/// In-app copy of the privacy policy (App Review Guideline 5.1.1(i)).
/// Keep in sync with PRIVACY.md at the repository root, which is the hostable version.
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Nothing leaves your iPhone. PoseGuard has no account, no analytics, no advertising and no third-party SDKs, and it does not track you across apps or websites.")
                } header: {
                    Text("What PoseGuard collects")
                }

                Section("Motion data") {
                    Text("While a tracking session is running, PoseGuard reads your head orientation from your AirPods through Apple's Core Motion headphone motion API. The app processes these readings in real time on your iPhone to tell whether your posture is correct. Raw motion readings are not stored.")
                }

                Section("Session history") {
                    Text("When you stop tracking, PoseGuard saves a summary of the session on your iPhone: its start and end time and the percentage of time your posture was correct. This history powers the report and stays in the app's local storage. It may be included in your device backups, according to your iCloud or computer backup settings. Deleting the app deletes the history.")
                }

                Section("Notifications") {
                    Text("Posture alerts are local notifications created on your iPhone. They are not sent through any server.")
                }

                Section("Permissions") {
                    Text("PoseGuard asks for access to Motion & Fitness data and, optionally, for permission to send notifications. You can change either choice at any time in the Settings app.")
                }

                Section("Children") {
                    Text("PoseGuard does not collect personal information from anyone, including children.")
                }

                Section {
                    Link("Open an issue on GitHub", destination: URL(string: "https://github.com/AcriStefano/PoseGuard/issues")!)
                } header: {
                    Text("Contact")
                } footer: {
                    Text("Effective October 29, 2026. If this policy changes, the updated version will be published with a new effective date.")
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    PrivacyPolicyView()
}
