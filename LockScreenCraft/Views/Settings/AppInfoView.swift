import SwiftUI

struct AppInfoView: View {
    // App version from Info.plist
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    // Build number from Info.plist
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "text.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("LockScreenCraft")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Version \(appVersion) (\(buildNumber))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 30)
            }
            
            Section(header: Text("Details".localized)) {
                LabeledContent("Version".localized, value: appVersion)
                LabeledContent("Build".localized, value: buildNumber)
                LabeledContent("Released".localized, value: "2023")
                LabeledContent("Platform".localized, value: "iOS 15.0+")
            }
            
            Section(header: Text("Developer".localized)) {
                Link(destination: URL(string: "https://github.com/alexlin519")!) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                        Text("Alex Lin")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                // You can add your LinkedIn link here when you provide it
                Link(destination: URL(string: "https://www.linkedin.com/in/your-profile")!) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.blue)
                        Text("LinkedIn Profile".localized)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Section(header: Text("Description".localized)) {
                Text("LockScreenCraft is an iOS app that allows you to create beautiful custom wallpapers for your lock screen with personalized text, backgrounds, and styling options.".localized)
                    .font(.body)
                    .padding(.vertical, 8)
            }
        }
        .navigationTitle("App Info".localized)
    }
}

#Preview {
    NavigationView {
        AppInfoView()
    }
} 