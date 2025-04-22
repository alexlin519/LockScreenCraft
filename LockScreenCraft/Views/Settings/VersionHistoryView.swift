import SwiftUI

struct VersionHistoryView: View {
    var body: some View {
        List {
            ForEach(versionHistory) { version in
                Section(header: 
                    HStack {
                        Text("Version \(version.version)")
                            .font(.headline)
                        Spacer()
                        Text(version.date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                ) {
                    ForEach(version.changes, id: \.self) { change in
                        HStack(alignment: .top) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .padding(.top, 6)
                            Text(change.localized)
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("Version History".localized)
    }
    
    // Sample version history data
    private let versionHistory: [VersionInfo] = [
        VersionInfo(
            version: "1.0",
            date: "November 2023",
            changes: [
                "Initial release",
                "Text styling with multiple font options",
                "Background gallery with texture options",
                "Device-specific rendering",
                "Save to Photos library",
                "Multiple language support"
            ]
        ),
        VersionInfo(
            version: "0.9 Beta",
            date: "October 2023",
            changes: [
                "Beta testing release",
                "Core functionality implementation",
                "Basic UI implementation",
                "Stability improvements"
            ]
        )
    ]
}

struct VersionInfo: Identifiable {
    let id = UUID()
    let version: String
    let date: String
    let changes: [String]
}

#Preview {
    NavigationView {
        VersionHistoryView()
    }
} 