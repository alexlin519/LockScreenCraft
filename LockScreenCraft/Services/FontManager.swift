import SwiftUI
import CoreText

// Remove the @_exported import and just use the types directly since they're in the same module

enum FontCategory: Int, CaseIterable {
    case regularKaiScript = 1  // 端正楷书
    case handwritten = 2       // 手写
    case cursiveAndRunningScript = 3  // 草书 行书 行楷
    case other = 4             // 其他
    
    var displayName: String {
        switch self {
        case .regularKaiScript: return "端正楷书"
        case .handwritten: return "手写"
        case .cursiveAndRunningScript: return "草书 行书 行楷"
        case .other: return "其他"
        }
    }
    
    // 返回分类的显示顺序（3214）
    var displayOrder: Int {
        switch self {
        case .regularKaiScript: return 1  // 第一个显示
        case .handwritten: return 2       // 第二个显示
        case .cursiveAndRunningScript: return 3  // 第三个显示
        case .other: return 4             // 第四个显示
        }
    }
}

class FontManager {
    static let shared = FontManager()
    
    private var registeredFonts: [String: String] = [:] // postScriptName to file name mapping
    
    // Font name to category mapping
    private let fontCategories: [String: FontCategory] = [
        // 1. 草书 行书 行楷
        "DuanNingRuanBiXingShu-2": .cursiveAndRunningScript,
        "南构无恙行书": .cursiveAndRunningScript,
        "鸿雷行书简体": .cursiveAndRunningScript,
        "ZhiMangXing-Regular": .cursiveAndRunningScript,
        "summerxingkai": .cursiveAndRunningScript,
        "sanji-xingkai": .cursiveAndRunningScript,
        "bangbang": .cursiveAndRunningScript,
        "LiuJianMaoCao-Regular": .cursiveAndRunningScript,
        "QingNiaoHuaGuangFanXingCao-2": .cursiveAndRunningScript,
        "PingFangYingFengTi-2": .cursiveAndRunningScript,
        
        // 2. 手写
        "huangkaihuaLawyerfont": .handwritten,
        "zhaizaijiafentiao": .handwritten,
        "jiangnan-hand": .handwritten,
        "honglei-banshu": .handwritten,
        "PingFangChangAnTi-2": .handwritten,
        "平方上上谦体": .handwritten,
        "ximaixihuan": .handwritten,
        "字制区喜脉喜欢体": .handwritten,
        
        // 3. 端正楷书
        "YanZhenQingFaShu-2": .regularKaiScript,
        "LXGWWenKai-Regular": .regularKaiScript,
        "CooperZhengKai-1.1": .regularKaiScript,
        "guangkekai": .regularKaiScript,
        "Dingding_JinBuTi": .regularKaiScript,
        "ChillCalligraphyChunQiu_ChenFeng": .regularKaiScript,
        "ChillCalligraphyChunQiu_QiuHong": .regularKaiScript,
        "ChillHuoKai_ConBold": .regularKaiScript,
        "ChillHuoKai_ConRegular": .regularKaiScript,
        "ChillHuoKai_Regular": .regularKaiScript,
        "云峰寒蝉体": .regularKaiScript,
        "XuandongKaishu": .regularKaiScript,
        "SanJiWeiBeiJianTi-Regular-2": .regularKaiScript,
        "SanJiXinWeiBeiJian-2": .regularKaiScript,
        "HanYiWeiBeiJian-1": .regularKaiScript,
        "字体家AI造字福楷": .regularKaiScript,
        "Ming_Chao": .regularKaiScript,
        "linhai-li": .regularKaiScript,
        "Slidechunfeng-Regular": .regularKaiScript,
        "Slideqiu-Regular": .regularKaiScript,
        "YujiMai-Regular": .regularKaiScript,
        "昆明海鸥体": .regularKaiScript,
        
        // 4. 其他
        "beili": .other,
        "zongxi-li": .other,
        "字体家AI造字霸行": .other,
        "jianghu-gufeng": .other,
        "PingFangLaiJiangHuFeiYangTi-2": .other,
        "zhongzusong": .other,
        "qiji-fallback": .other
    ]
    
    // Font name to display name mapping
    private let fontDisplayNames: [String: String] = [
        // Existing fonts (System fonts excluded from list)
        "LXGWWenKai-Regular": "霞鹜文楷",
        "Ming_Chao": "明朝体",
        "Dingding_JinBuTi": "钉钉进步体",
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
        "ximaixihuan": "喜脉喜欢体",
        
        // New fonts from ziti folder - using inferred Chinese names from 新字体完整列表.txt
        // 寒蝉活楷体系列 (Chill Calligraphy - Kai Script)
        "ChillCalligraphyChunQiu_ChenFeng": "寒蝉春风体",
        "ChillCalligraphyChunQiu_QiuHong": "寒蝉秋鸿体",
        "ChillHuoKai_ConBold": "寒蝉活楷粗体",
        "ChillHuoKai_ConRegular": "寒蝉活楷体常规",
        "ChillHuoKai_Regular": "寒蝉活楷体",
        "云峰寒蝉体": "云峰寒蝉体",
        
        // 行书字体 (Running Script / Xing Shu)
        "DuanNingRuanBiXingShu-2": "段宁软笔行书",
        "南构无恙行书": "南构无恙行书",
        "鸿雷行书简体": "鸿雷行书",
        
        // 魏碑字体 (Wei Bei)
        "HanYiWeiBeiJian-1": "汉仪魏碑",
        "SanJiWeiBeiJianTi-Regular-2": "三极魏碑",
        "SanJiXinWeiBeiJian-2": "三极新魏碑",
        
        // 楷书字体 (Kai Script)
        "XuandongKaishu": "玄冬楷书",
        
        // 草书字体 (Cao Script)
        "LiuJianMaoCao-Regular": "钟齐流江毛草",
        "QingNiaoHuaGuangFanXingCao-2": "青鸟花光行草",
        
        // 颜真卿法书 (Yan Zhen Qing Fa Shu)
        "YanZhenQingFaShu-2": "颜真卿体",
        
        // 平方字体系列 (Square Fonts)
        "PingFangChangAnTi-2": "平方长安体",
        "PingFangYingFengTi-2": "平方迎风体",
        "平方上上谦体": "平方上上谦体",
        
        // 季节字体 (Seasonal Fonts)
        "Slidechunfeng-Regular": "春风体",
        "Slideqiu-Regular": "秋风体",
        
        // 柚子字体 - 只保留 Mai，显示为"佑字体"
        "YujiMai-Regular": "佑字体",
        
        // 手写体 (Handwritten)
        "huangkaihuaLawyerfont": "黄开华手写体",
        
        // AI字体 (AI Generated)
        "字体家AI造字福楷": "AI福楷",
        "字体家AI造字霸行": "AI霸行",
        
        // 其他字体 (Other Fonts)
        "qiji-fallback": "奇骥古籍体",
        "昆明海鸥体": "昆明海鸥体",
        "字制区喜脉喜欢体": "喜脉喜欢体"
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
        
        // Fonts to exclude from the list (系统字体、思源黑体、苹方、黑体)
        let excludedFonts: Set<String> = [
            "System Font",
            "PingFang SC",
            "Heiti SC",
            "SourceHanSansCN-Regular",
            // Exclude other Yuji fonts, only keep YujiMai-Regular
            "YujiBoku-Regular",
            "YujiHentaiganaAkari-Regular",
            "YujiHentaiganaAkebono-Regular",
            "YujiSyuku-Regular",
            // Exclude daizen (not in new classification)
            "daizen",
            // Exclude 向南行书体 (XiangNanXingShuTi-1)
            "XiangNanXingShuTi-1"
        ]
        
        // Add custom fonts from our registered fonts
        print("\n📝 Processing registered fonts:")
        for (postScript, filename) in registeredFonts {
            print("   Checking font: \(filename)")
            // Skip excluded fonts
            if excludedFonts.contains(filename) {
                print("   ⏭️ Skipping excluded font: \(filename)")
                continue
            }
            
            // Only add fonts that have a display name mapping and category
            if let displayName = fontDisplayNames[filename],
               let category = fontCategories[filename] {
                fonts.append(FontDisplayInfo(fontName: filename, displayName: displayName))
                print("   ✅ Added custom font: \(displayName) (Category: \(category.displayName))")
            } else {
                print("   ⚠️ No display name mapping or category for: \(filename)")
            }
        }
        
        // Sort fonts by category (3214 order) and then by display name within each category
        let sortedFonts = fonts.sorted { font1, font2 in
            let category1 = fontCategories[font1.fontName] ?? .other
            let category2 = fontCategories[font2.fontName] ?? .other
            
            // First sort by category display order (3214)
            if category1.displayOrder != category2.displayOrder {
                return category1.displayOrder < category2.displayOrder
            }
            
            // Within same category, sort by display name
            return font1.displayName < font2.displayName
        }
        
        print("\n📝 Final font list (sorted by category 3214):")
        var currentCategory: FontCategory? = nil
        for font in sortedFonts {
            if let category = fontCategories[font.fontName], category != currentCategory {
                currentCategory = category
                print("\n   [\(category.displayName)]")
            }
            print("   • \(font.displayName) (\(font.fontName))")
        }
        print("=== 🔍 DEBUG: Font List End ===\n")
        
        return sortedFonts
    }
    
    // Get fonts by category (nil means all fonts)
    func getFonts(byCategory category: FontCategory?) -> [FontDisplayInfo] {
        let allFonts = getAllAvailableFonts()
        
        // If no category specified, return all fonts
        guard let category = category else {
            return allFonts
        }
        
        // Filter fonts by category
        return allFonts.filter { font in
            fontCategories[font.fontName] == category
        }
    }
} 