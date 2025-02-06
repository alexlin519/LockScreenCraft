import SwiftUI
import CoreText

enum FontCategory {
    case system
    case chinese
    case english
    case handwriting
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .chinese: return "Chinese"
        case .english: return "English"
        case .handwriting: return "Handwriting"
        }
    }
}

class FontManager {
    static let shared = FontManager()
    
    private var registeredFonts: Set<String> = []
    
    func registerFonts() {
        // Register custom fonts from the bundle
        if let fontURLs = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts")
            ?? Bundle.main.urls(forResourcesWithExtension: "otf", subdirectory: "Fonts") {
            
            for url in fontURLs {
                var error: Unmanaged<CFError>?
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
                if let fontName = CGDataProvider(url: url as CFURL).flatMap(CGFont.init)?.postScriptName as String? {
                    registeredFonts.insert(fontName)
                }
            }
        }
    }
    
    func getFont(name: String, size: CGFloat) -> UIFont {
        // Try direct font name first
        if let customFont = UIFont(name: name, size: size) {
            return customFont
        }
        
        // Fallback to system font
        return .systemFont(ofSize: size)
    }
    
    func getFontsForCategory(_ category: FontCategory) -> [String] {
        switch category {
        case .system:
            return ["System Font", "SF Pro", "SF Mono"]
        case .chinese:
            return UIFont.familyNames.filter { 
                $0.contains("宋体") || $0.contains("黑体") || $0.contains("楷体")
            }
        case .english:
            return ["Helvetica Neue", "Times New Roman", "Arial"]
        case .handwriting:
            return ["Noteworthy", "Bradley Hand"]
        }
    }
} 