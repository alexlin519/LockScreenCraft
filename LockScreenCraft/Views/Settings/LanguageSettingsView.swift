import SwiftUI

struct LanguageSettingsView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedLanguage: LocalizationManager.Language
    
    init() {
        _selectedLanguage = State(initialValue: LocalizationManager.shared.currentLanguage)
    }
    
    var body: some View {
        List {
            ForEach(LocalizationManager.Language.allCases) { language in
                Button(action: {
                    selectedLanguage = language
                    localizationManager.setLanguage(language)
                    
                    // Add a small delay to allow the UI to update
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    HStack {
                        Text(language.icon)
                            .font(.largeTitle)
                        
                        Text(language.displayName)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if language == selectedLanguage {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("Language".localized)
    }
} 