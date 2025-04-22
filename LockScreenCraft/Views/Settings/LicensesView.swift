import SwiftUI

struct LicensesView: View {
    @State private var expandedLicenses: Set<String> = []
    
    var body: some View {
        List {
            ForEach(licenses, id: \.name) { license in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedLicenses.contains(license.name) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedLicenses.insert(license.name)
                            } else {
                                expandedLicenses.remove(license.name)
                            }
                        }
                    )
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        if let url = license.url {
                            Link(destination: URL(string: url)!) {
                                Text("View Project Website")
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        Text(license.licenseText)
                            .font(.caption)
                            .padding(.vertical, 8)
                    }
                    .padding(.vertical, 8)
                } label: {
                    HStack {
                        Text(license.name)
                            .font(.headline)
                        Spacer()
                        Text(license.licenseType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Licenses".localized)
    }
    
    // Sample license data
    private let licenses: [LicenseInfo] = [
        LicenseInfo(
            name: "Swift Standard Library",
            licenseType: "Apache 2.0",
            url: "https://swift.org",
            licenseText: "Copyright © 2014-2023 Apple Inc. and the Swift project authors.\n\nLicensed under Apache License v2.0 with Runtime Library Exception..."
        ),
        LicenseInfo(
            name: "SwiftUI",
            licenseType: "Apple",
            url: "https://developer.apple.com/xcode/swiftui/",
            licenseText: "Copyright © 2019-2023 Apple Inc. All rights reserved."
        )
        // Add other libraries here
    ]
}

struct LicenseInfo {
    let name: String
    let licenseType: String
    let url: String?
    let licenseText: String
}

#Preview {
    NavigationView {
        LicensesView()
    }
} 