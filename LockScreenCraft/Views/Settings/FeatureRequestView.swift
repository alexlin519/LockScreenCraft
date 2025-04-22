import SwiftUI

struct FeatureRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var featureTitle: String = ""
    @State private var featureDescription: String = ""
    @State private var priority: FeaturePriority = .medium
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    
    var body: some View {
        Form {
            Section(header: Text("Feature Title".localized)) {
                TextField("Enter a short title for your feature".localized, text: $featureTitle)
                    .padding(.vertical, 4)
            }
            
            Section(header: Text("Feature Description".localized)) {
                TextEditor(text: $featureDescription)
                    .frame(minHeight: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.vertical, 4)
            }
            
            Section(header: Text("Priority".localized)) {
                Picker("Select Priority".localized, selection: $priority) {
                    ForEach(FeaturePriority.allCases) { priority in
                        Text(priority.description.localized)
                            .tag(priority)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section {
                Button(action: submitRequest) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Submit Request".localized)
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                }
                .disabled(featureTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                          featureDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                          isSubmitting)
                .buttonStyle(.borderedProminent)
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Feature Request".localized)
        .alert("Thank You!".localized, isPresented: $showingSuccess) {
            Button("OK".localized, role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Your feature request has been submitted and will be reviewed.".localized)
        }
    }
    
    private func submitRequest() {
        // Validate form
        guard !featureTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !featureDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ Feature request fields are empty")
            return
        }
        
        print("🔍 Starting feature request submission")
        isSubmitting = true
        
        // Format the email content
        let subject = "Feature Request: \(featureTitle)"
        let body = """
        Feature Title:
        \(featureTitle)
        
        Description:
        \(featureDescription)
        
        Priority: \(priority.description)
        
        ---
        Sent from LockScreenCraft app
        
        [Please attach any relevant screenshots or mockups if applicable]
        """
        
        // Create mailto URL
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mailtoString = "mailto:support@lockscreencraft.com?subject=\(encodedSubject)&body=\(encodedBody)"
        
        print("📧 Mailto URL: \(mailtoString)")
        
        guard let mailtoURL = URL(string: mailtoString) else {
            print("❌ Failed to create mailto URL")
            isSubmitting = false
            return
        }
        
        if UIApplication.shared.canOpenURL(mailtoURL) {
            print("✅ Opening mail client...")
            UIApplication.shared.open(mailtoURL, options: [:]) { success in
                print("📱 Mail client open success: \(success)")
                
                DispatchQueue.main.async {
                    self.isSubmitting = false
                    if success {
                        self.showingSuccess = true
                    } else {
                        // Handle failure to open
                        print("❌ Failed to open mail client")
                    }
                }
            }
        } else {
            print("❌ No mail client available")
            isSubmitting = false
            
            // Show an alert telling the user no mail client is available
            let alert = UIAlertController(
                title: "No Email App Found".localized,
                message: "Please make sure you have an email app installed and configured on your device.".localized,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
            
            // Get the current window's root view controller to present the alert
            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
        }
    }
}

enum FeaturePriority: String, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .low: return "Nice to Have"
        case .medium: return "Helpful"
        case .high: return "Essential"
        }
    }
}

#Preview {
    NavigationView {
        FeatureRequestView()
    }
} 