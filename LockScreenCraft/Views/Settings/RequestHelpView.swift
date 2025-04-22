import SwiftUI

struct RequestHelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTopic: HelpTopic = .general
    @State private var question: String = ""
    @State private var email: String = ""
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    
    var body: some View {
        Form {
            Section(header: Text("Help Topic".localized)) {
                Picker("Select Topic".localized, selection: $selectedTopic) {
                    ForEach(HelpTopic.allCases) { topic in
                        Text(topic.description.localized)
                            .tag(topic)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section(header: Text("Your Question".localized)) {
                TextEditor(text: $question)
                    .frame(minHeight: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.vertical, 4)
            }
            
            Section(header: Text("Your Email".localized)) {
                TextField("example@email.com", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding(.vertical, 4)
            }
            
            Section {
                Button(action: submitHelp) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Submit Question".localized)
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                }
                .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                         !isValidEmail(email) || isSubmitting)
                .buttonStyle(.borderedProminent)
                .padding(.vertical, 4)
                
                if !isValidEmail(email) && !email.isEmpty {
                    Text("Please enter a valid email address".localized)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Request Help".localized)
        .alert("Thank You!".localized, isPresented: $showingSuccess) {
            Button("OK".localized, role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Your question has been submitted. We'll respond to your email shortly.".localized)
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func submitHelp() {
        // Validate form
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              isValidEmail(email) else {
            return
        }
        
        isSubmitting = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // In a real app, send help request to your backend/service
            isSubmitting = false
            showingSuccess = true
        }
    }
}

enum HelpTopic: String, CaseIterable, Identifiable {
    case general = "General"
    case textFormatting = "TextFormatting"
    case backgrounds = "Backgrounds"
    case saving = "Saving"
    case templates = "Templates"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .general: return "General Help"
        case .textFormatting: return "Text Formatting"
        case .backgrounds: return "Background Options"
        case .saving: return "Saving & Sharing"
        case .templates: return "Templates"
        case .other: return "Other"
        }
    }
}

#Preview {
    NavigationView {
        RequestHelpView()
    }
} 