import SwiftUI

struct CreditsView: View {
    var body: some View {
        List {
            Section(header: Text("Developer".localized)) {
                CreditPersonView(
                    name: "Alex Lin",
                    role: "Lead Developer",
                    description: "App design, development, and concept",
                    links: [
                        PersonLink(title: "GitHub", url: "https://github.com/alexlin519", icon: "git"),
                        PersonLink(title: "LinkedIn", url: "https://www.linkedin.com/in/your-profile", icon: "link")
                    ]
                )
            }
            
            Section(header: Text("Acknowledgements".localized)) {
                CreditItemView(
                    title: "Open Source Libraries",
                    description: "This app uses various open source libraries and components"
                )
                
                CreditItemView(
                    title: "Design Resources",
                    description: "Background textures and design elements from various sources"
                )
                
                CreditItemView(
                    title: "Testing & Feedback",
                    description: "Thanks to all beta testers who provided valuable feedback"
                )
            }
        }
        .navigationTitle("Credits".localized)
    }
}

struct CreditPersonView: View {
    let name: String
    let role: String
    let description: String
    let links: [PersonLink]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(name)
                        .font(.headline)
                    Text(role.localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Text(description.localized)
                .font(.body)
                .padding(.vertical, 4)
            
            HStack {
                ForEach(links) { link in
                    Link(destination: URL(string: link.url)!) {
                        HStack {
                            Image(systemName: link.icon)
                            Text(link.title)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct CreditItemView: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.localized)
                .font(.headline)
            Text(description.localized)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct PersonLink: Identifiable {
    let id = UUID()
    let title: String
    let url: String
    let icon: String
}

#Preview {
    NavigationView {
        CreditsView()
    }
} 