import Foundation
import SwiftUI

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: Language
    
    enum Language: String, CaseIterable, Identifiable {
        case english = "en"
        case simplifiedChinese = "zh-Hans"
        // Add more languages as needed
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .simplifiedChinese: return "简体中文"
            }
        }
        
        var icon: String {
            switch self {
            case .english: return "🇺🇸"
            case .simplifiedChinese: return "🇨🇳"
            }
        }
    }
    
    init() {
        // Get saved language or use system default
        if let savedLanguageCode = UserDefaults.standard.string(forKey: "app_language"),
           let language = Language(rawValue: savedLanguageCode) {
            currentLanguage = language
        } else {
            // Use system language or default to English
            let preferredLanguage = Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en"
            currentLanguage = Language(rawValue: preferredLanguage) ?? .english
        }
        
        // Set initial language
        applyLanguage(currentLanguage)
    }
    
    func setLanguage(_ language: Language) {
        currentLanguage = language
        applyLanguage(language)
    }
    
    private func applyLanguage(_ language: Language) {
        // Save selection
        UserDefaults.standard.set(language.rawValue, forKey: "app_language")
        
        // Set preferred languages for the app
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Post notification for views to refresh
        NotificationCenter.default.post(name: Notification.Name("LanguageChanged"), object: nil)
    }
} 