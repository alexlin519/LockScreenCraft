import Foundation

class BundleLocalization: Bundle {
    private static var bundle: Bundle?
    
    static func localizedBundle() -> Bundle {
        if bundle == nil {
            let languageCode = UserDefaults.standard.string(forKey: "app_language") ?? "en"
            if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj") {
                bundle = Bundle(path: path)
            } else {
                bundle = Bundle.main
            }
        }
        return bundle ?? Bundle.main
    }
    
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        let bundle = BundleLocalization.localizedBundle()
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    static func setupLocalizationBundle() {
        // Only do this once to avoid issues
        if !(Bundle.main is BundleLocalization) {
            object_setClass(Bundle.main, BundleLocalization.self)
        }
    }
} 