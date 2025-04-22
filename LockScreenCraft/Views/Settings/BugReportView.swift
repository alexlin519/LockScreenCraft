import SwiftUI
import PhotosUI

struct BugReportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var description: String = ""
    @State private var severity: BugSeverity = .minor
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var screenshotImage: UIImage?
    
    // Device info is collected automatically
    private var deviceInfo: String {
        "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion), \(UIDevice.current.model)"
    }
    
    var body: some View {
        Form {
            Section(header: Text("Issue Description".localized)) {
                TextEditor(text: $description)
                    .frame(minHeight: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.vertical, 4)
            }
            
            Section(header: Text("Severity".localized)) {
                Picker("Select Severity".localized, selection: $severity) {
                    ForEach(BugSeverity.allCases) { severity in
                        Text(severity.description.localized)
                            .tag(severity)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section(header: Text("Screenshot".localized)) {
                if let image = screenshotImage {
                    HStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                        
                        Spacer()
                        
                        Button(action: {
                            screenshotImage = nil
                            selectedItem = nil
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                } else {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Add Screenshot".localized, systemImage: "photo.badge.plus")
                    }
                }
            }
            .onChange(of: selectedItem) { newValue in
                if let newItem = newValue {
                    loadTransferable(from: newItem)
                }
            }
            
            Section(header: Text("Device Information".localized)) {
                Text(deviceInfo)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Button(action: submitReport) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Submit Report".localized)
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                }
                .disabled(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                .buttonStyle(.borderedProminent)
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Report a Bug".localized)
        .alert("Thank You!".localized, isPresented: $showingSuccess) {
            Button("OK".localized, role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Your bug report has been submitted successfully.".localized)
        }
    }
    
    private func loadTransferable(from item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.screenshotImage = image
                }
            }
        }
    }
    
    private func submitReport() {
        // Validate form
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ Bug report description is empty")
            return
        }
        
        print("🔍 Starting bug report submission")
        isSubmitting = true
        
        // Format the email content
        let subject = "Bug Report: \(severity.rawValue)"
        let body = """
        Description:
        \(description)
        
        Severity: \(severity.rawValue)
        
        Device Info:
        \(deviceInfo)
        
        ---
        Sent from LockScreenCraft app
        
        [Please attach a screenshot if applicable]
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

enum BugSeverity: String, CaseIterable, Identifiable {
    case minor = "Minor"
    case major = "Major"
    case critical = "Critical"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .minor: return "Minor"
        case .major: return "Major"
        case .critical: return "Critical"
        }
    }
}

#Preview {
    NavigationView {
        BugReportView()
    }
} 