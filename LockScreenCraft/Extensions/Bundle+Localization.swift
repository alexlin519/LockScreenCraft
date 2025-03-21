import Foundation

class BundleLocalization: Bundle {
    // Make it accessible so we can reset it
    static var bundle: Bundle?
    
    static func localizedBundle() -> Bundle {
        if bundle == nil {
            let languageCode = UserDefaults.standard.string(forKey: "app_language") ?? "en"
            print("Loading bundle for language: \(languageCode)")
            if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj") {
                bundle = Bundle(path: path)
                print("Found language bundle at path: \(path)")
            } else {
                print("Language bundle not found, using main bundle")
                bundle = Bundle.main
            }
        }
        return bundle ?? Bundle.main
    }
    
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        let bundle = BundleLocalization.localizedBundle()
        let result = bundle.localizedString(forKey: key, value: value, table: tableName)
        print("Localizing key: \(key) -> \(result)")
        return result
    }
}

extension Bundle {
    static func setupLocalizationBundle() {
        // Only do this once to avoid issues
        if !(Bundle.main is BundleLocalization) {
            print("⭐️ Setting up localization bundle override")
            object_setClass(Bundle.main, BundleLocalization.self)
        }
    }
} 