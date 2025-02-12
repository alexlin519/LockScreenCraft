import SwiftUI
import CoreText

// Remove the @_exported import and just use the types directly since they're in the same module

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
    
    private var registeredFonts: [String: String] = [:] // postScriptName to file name mapping
    
    // Font name to display name mapping
    private let fontDisplayNames: [String: String] = [
        "System Font": "系统字体",
        "LXGWWenKai-Regular": "霞鹜文楷",
        "SourceHanSansCN-Regular": "思源黑体",
        "Ming_Chao": "明朝体",
        "Dingding_JinBuTi": "钉钉进步体",
        "PingFang SC": "苹方",
        "Heiti SC": "黑体",
        "jianghu-gufeng": "江湖古风",
        "jiangnan-hand": "平方江南手写体",
        "CooperZhengKai-1.1": "汇迹正楷",
        "zhongzusong": "重族宋体",
        "guangkekai": "程荣光刻楷体",
        "bangbang": "重庆山城行楷",
        "beili": "峄山碑篆体",
        "summerxingkai": "夏行楷",
        "PingFangLaiJiangHuFeiYangTi-2": "江湖飞扬体",
        "zhaizaijiafentiao": "粉条手写体",
        "linhai-li": "临海隶书",
        "honglei-banshu": "鸿雷板书体",
        "zongxi-li": "崇羲篆体",
        "ZhiMangXing-Regular": "志莽行书",
        "daizen": "daizen",
        "sanji-xingkai": "三极行楷",
        "ximaixihuan": "喜脉喜欢体"
    ]
    
    func registerFonts() {
        print("\n=== 🔍 DEBUG: Font Registration Start ===")
        print("📱 Starting font registration...")
        
        // Debug bundle paths
        let bundle = Bundle.main
        print("📂 Bundle Path: \(bundle.bundlePath)")
        print("📂 Resource Path: \(bundle.resourcePath ?? "nil")")
        
        // List all files in Resources directory
        if let resourcePath = bundle.resourcePath {
            let resourceURL = URL(fileURLWithPath: resourcePath)
            print("\n📂 Listing contents of resource directory:")
            if let contents = try? FileManager.default.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil) {
                contents.forEach { print("   • \($0.lastPathComponent)") }
            }
        }
        
        var fontPaths: [URL] = []
        
        // First try Resources/Fonts
        fontPaths += Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Resources/Fonts") ?? []
        fontPaths += Bundle.main.urls(forResourcesWithExtension: "otf", subdirectory: "Resources/Fonts") ?? []
        
        print("\n📂 Fonts found in Resources/Fonts:")
        fontPaths.forEach { print("   • \($0.lastPathComponent)") }
        
        // Then try Fonts directory
        if fontPaths.isEmpty {
            print("\n⚠️ No fonts found in Resources/Fonts, trying Fonts directory...")
            fontPaths += Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? []
            fontPaths += Bundle.main.urls(forResourcesWithExtension: "otf", subdirectory: "Fonts") ?? []
            print("\n📂 Fonts found in Fonts directory:")
            fontPaths.forEach { print("   • \($0.lastPathComponent)") }
        }
        
        // Finally, try root directory
        if fontPaths.isEmpty {
            print("\n⚠️ No fonts found in subdirectories, trying root directory...")
            if let resourcePath = bundle.resourcePath {
                let resourceURL = URL(fileURLWithPath: resourcePath)
                if let contents = try? FileManager.default.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil) {
                    fontPaths += contents.filter { $0.pathExtension == "ttf" || $0.pathExtension == "otf" }
                }
            }
            print("\n📂 Fonts found in root directory:")
            fontPaths.forEach { print("   • \($0.lastPathComponent)") }
        }
        
        if fontPaths.isEmpty {
            print("\n❌ ERROR: No font files found in any directory!")
            return
        }
        
        print("\n📚 Found font files: \(fontPaths.map { $0.lastPathComponent })")
        
        for url in fontPaths {
            let filename = url.deletingPathExtension().lastPathComponent
            print("\n🔄 Processing font: \(filename)")
            
            // Unregister first to avoid conflicts
            CTFontManagerUnregisterFontsForURL(url as CFURL, .process, nil)
            
            var error: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            
            if success {
            if let dataProvider = CGDataProvider(url: url as CFURL),
                   let cgFont = CGFont(dataProvider) {
                    let postScriptName = cgFont.postScriptName as String? ?? ""
                    
                    // Store the mapping of postScript name to filename
                    registeredFonts[postScriptName] = filename
                    print("✅ Successfully registered font:")
                    print("   Filename: \(filename)")
                    print("   PostScript Name: \(postScriptName)")
                    
                    // Verify the font is actually available
                    #if canImport(UIKit)
                    if let _ = UIFont(name: postScriptName, size: 12) {
                        print("   ✅ Font is available in system")
                    } else {
                        print("   ⚠️ Font registered but not available in system!")
                    }
                    #endif
                }
            } else {
                if let error = error?.takeRetainedValue() {
                    print("❌ Failed to register font \(filename)")
                    print("   Error: \(error.localizedDescription)")
                }
            }
        }
        
        print("\n📝 Final registered fonts mapping:")
        for (postScript, file) in registeredFonts {
            print("   \(file) -> \(postScript)")
        }
        print("=== 🔍 DEBUG: Font Registration End ===\n")
    }
    
    func getFont(name: String, size: CGFloat) -> PlatformFont {
        print("🔍 Attempting to get font: \(name)")
        
        // Handle system font case
        if name == "System Font" {
            #if canImport(UIKit)
            return .systemFont(ofSize: size)
            #elseif canImport(AppKit)
            return .systemFont(ofSize: size)
            #endif
        }
        
        // For system Chinese fonts
        if name == "PingFang SC" || name == "Heiti SC" {
            #if canImport(UIKit)
            if let font = UIFont(name: name, size: size) {
                return font
            }
            #elseif canImport(AppKit)
            if let font = NSFont(name: name, size: size) {
                return font
            }
            #endif
        }
        
        // For custom fonts, try to find the registered postScript name
        for (postScriptName, filename) in registeredFonts {
            if filename == name || postScriptName == name {
                #if canImport(UIKit)
                if let customFont = UIFont(name: postScriptName, size: size) {
                    print("✅ Found custom font: \(postScriptName)")
                    return customFont
                }
                #elseif canImport(AppKit)
                if let customFont = NSFont(name: postScriptName, size: size) {
                    print("✅ Found custom font: \(postScriptName)")
                    return customFont
                }
                #endif
            }
        }
        
        print("⚠️ Falling back to system font for: \(name)")
        #if canImport(UIKit)
        return .systemFont(ofSize: size)
        #elseif canImport(AppKit)
        return .systemFont(ofSize: size)
        #endif
    }
    
    func getAllAvailableFonts() -> [FontDisplayInfo] {
        print("\n=== 🔍 DEBUG: Getting Available Fonts ===")
        var fonts: [FontDisplayInfo] = []
        
        // Add system font first
        fonts.append(FontDisplayInfo(fontName: "System Font", displayName: "系统字体"))
        print("✅ Added system font")
        
        // Add custom fonts from our registered fonts
        print("\n📝 Processing registered fonts:")
        for (postScript, filename) in registeredFonts {
            print("   Checking font: \(filename)")
            if let displayName = fontDisplayNames[filename] {
                fonts.append(FontDisplayInfo(fontName: filename, displayName: displayName))
                print("   ✅ Added custom font: \(displayName)")
            } else {
                print("   ⚠️ No display name mapping for: \(filename)")
            }
        }
        
        // Add basic Chinese system fonts
        let chineseSystemFonts = [
            "PingFang SC",
            "Heiti SC"
        ]
        
        print("\n📝 Adding system Chinese fonts:")
        for fontName in chineseSystemFonts {
            if let displayName = fontDisplayNames[fontName] {
                fonts.append(FontDisplayInfo(fontName: fontName, displayName: displayName))
                print("   ✅ Added system Chinese font: \(displayName)")
            }
        }
        
        let sortedFonts = fonts.sorted { $0.displayName < $1.displayName }
        print("\n📝 Final font list:")
        for font in sortedFonts {
            print("   • \(font.displayName) (\(font.fontName))")
        }
        print("=== 🔍 DEBUG: Font List End ===\n")
        
        return sortedFonts
    }
} 