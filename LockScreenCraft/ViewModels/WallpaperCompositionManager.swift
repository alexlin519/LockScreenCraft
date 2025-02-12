import SwiftUI

// MARK: - Background Types
enum BackgroundType {
    case image(UIImage)
    // Future types:
    // case solidColor(Color)
    // case gradient(GradientConfig)
    // case frosted(Color, Double)
}

// MARK: - Transform
struct Transform {
    var scale: CGFloat = 1.0
    var offset: CGSize = .zero
    
    mutating func reset() {
        scale = 1.0
        offset = .zero
    }
}

// MARK: - Manager
class WallpaperCompositionManager: ObservableObject {
    static let shared = WallpaperCompositionManager()
    
    @Published var backgroundType: BackgroundType?
    @Published var backgroundTransform = Transform()
    @Published var availableBackgrounds: [String] = []
    @Published var errorMessage: String?
    @Published var showError = false
    
    private init() {
        loadAvailableBackgrounds()
    }
    
    private func loadAvailableBackgrounds() {
        print("\n=== 🔍 DEBUG: Loading Available Backgrounds ===")
        
        // Debug bundle paths
        let bundle = Bundle.main
        print("📂 Bundle Path: \(bundle.bundlePath)")
        print("📂 Resource Path: \(bundle.resourcePath ?? "nil")")
        
        // Try direct file system access first
        let fileManager = FileManager.default
        let backgroundPath = "\(bundle.bundlePath)/Resources/Background"
        print("\n📂 Checking direct file system path: \(backgroundPath)")
        
        // Try loading directly from the workspace path
        let workspacePath = "/Users/alexlin/LockScreenCraft/LockScreenCraft/Resources/Background"
        print("\n📂 Checking workspace path: \(workspacePath)")
        if fileManager.fileExists(atPath: workspacePath) {
            print("✅ Background directory exists in workspace")
            do {
                let items = try fileManager.contentsOfDirectory(atPath: workspacePath)
                print("📝 Found \(items.count) items in workspace directory:")
                items.forEach { print("   • \($0)") }
                
                // Add these files to our available backgrounds
                availableBackgrounds = items.filter { 
                    let fileExtension = ($0 as NSString).pathExtension.lowercased()
                    return ["jpg", "jpeg", "png"].contains(fileExtension)
                }
            } catch {
                print("❌ Error reading workspace directory: \(error.localizedDescription)")
            }
        } else {
            print("❌ Background directory not found in workspace")
        }
        
        // If we found backgrounds in the workspace, try to load them
        if !availableBackgrounds.isEmpty {
            print("\n📝 Found \(availableBackgrounds.count) background images:")
            availableBackgrounds.forEach { print("   • \($0)") }
        } else {
            print("\n❌ No background images found in workspace")
            
            // Try alternative paths
            print("\n🔍 Trying alternative resource paths:")
            ["Resources/Background", "Background", "Resources/Backgrounds", "Backgrounds"].forEach { path in
                if let urls = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: path) {
                    print("   ✅ Found resources in: \(path)")
                    urls.forEach { print("      • \($0.lastPathComponent)") }
                } else {
                    print("   ❌ No resources found in: \(path)")
                }
            }
        }
        
        print("\n📝 Final Summary:")
        print("• Bundle Path: \(bundle.bundlePath)")
        print("• Resource Path: \(bundle.resourcePath ?? "nil")")
        print("• Available Backgrounds Count: \(availableBackgrounds.count)")
        print("• Background Names: \(availableBackgrounds)")
        print("=== 🔍 DEBUG: Background Loading End ===\n")
    }
    
    func selectBackground(named filename: String) {
        print("\n=== 🔍 DEBUG: Selecting Background ===")
        print("📝 Attempting to load background: \(filename)")
        
        // Try loading from workspace path first
        let workspacePath = "/Users/alexlin/LockScreenCraft/LockScreenCraft/Resources/Background/\(filename)"
        print("📂 Trying workspace path: \(workspacePath)")
        if let image = UIImage(contentsOfFile: workspacePath) {
            print("✅ Successfully loaded image from workspace path")
            print("   Image size: \(image.size)")
            print("   Image scale: \(image.scale)")
            self.backgroundType = .image(image)
            print("✅ Background type set to image")
            return
        }
        
        // Try bundle loading
        print("📂 Trying bundle path: Resources/Background/\(filename)")
        if let image = UIImage(named: "Resources/Background/\(filename)") {
            print("✅ Successfully loaded image from bundle")
            print("   Image size: \(image.size)")
            print("   Image scale: \(image.scale)")
            self.backgroundType = .image(image)
            print("✅ Background type set to image")
        } else {
            print("❌ Failed to load image from bundle")
            print("🔍 Trying alternate paths...")
            
            // Try loading with bundle path
            if let resourcePath = Bundle.main.path(forResource: filename, ofType: nil, inDirectory: "Resources/Background") {
                print("📂 Found resource path: \(resourcePath)")
                if let image = UIImage(contentsOfFile: resourcePath) {
                    print("✅ Successfully loaded image from resource path")
                    print("   Image size: \(image.size)")
                    print("   Image scale: \(image.scale)")
                    self.backgroundType = .image(image)
                    print("✅ Background type set to image")
                    return
                } else {
                    print("❌ Failed to load image from resource path")
                }
            } else {
                print("❌ Could not find resource path for: \(filename)")
            }
            
            showError("Failed to load background image")
        }
        
        // Verify final state
        if case .image(let finalImage) = self.backgroundType {
            print("✅ Final verification: Background image is set")
            print("   Final image size: \(finalImage.size)")
            print("   Final image scale: \(finalImage.scale)")
        } else {
            print("❌ Final verification: No background image is set")
        }
        print("=== 🔍 DEBUG: Background Selection End ===\n")
    }
    
    func applyTransform(_ transform: Transform) {
        backgroundTransform = transform
    }
    
    func resetTransform() {
        backgroundTransform.reset()
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    // This will be expanded later to handle composition with text
    func generateFinalImage(withText textImage: UIImage, device: DeviceConfig) -> UIImage? {
        print("\n=== 🎨 DEBUG: Generating Final Image ===")
        
        // Debug background state
        if case .image(let bgImage) = backgroundType {
            print("✅ Background image exists:")
            print("   Size: \(bgImage.size)")
            print("   Scale: \(bgImage.scale)")
        } else {
            print("❌ No background image set in backgroundType")
        }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        print("📐 Device Resolution: \(device.resolution)")
        
        let renderer = UIGraphicsImageRenderer(
            size: device.resolution,
            format: format
        )
        
        let finalImage = renderer.image { context in
            // Draw background first if available
            if case .image(let backgroundImage) = backgroundType {
                print("✅ Drawing background image")
                
                // Scale background to fill the device resolution while maintaining aspect ratio
                let bgSize = backgroundImage.size
                let deviceSize = device.resolution
                
                let widthRatio = deviceSize.width / bgSize.width
                let heightRatio = deviceSize.height / bgSize.height
                let scale = max(widthRatio, heightRatio)
                
                let scaledWidth = bgSize.width * scale
                let scaledHeight = bgSize.height * scale
                
                // Center the background
                let x = (deviceSize.width - scaledWidth) / 2
                let y = (deviceSize.height - scaledHeight) / 2
                
                print("   Background original size: \(bgSize)")
                print("   Scaled size: \(scaledWidth) x \(scaledHeight)")
                print("   Position: (\(x), \(y))")
                
                backgroundImage.draw(in: CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight))
                print("✅ Background drawn successfully")
            } else {
                print("ℹ️ No background image, using white background")
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: device.resolution))
            }
            
            // Draw text image on top
            print("✅ Drawing text overlay")
            textImage.draw(in: CGRect(origin: .zero, size: device.resolution))
        }
        
        print("📱 Final image size: \(finalImage.size)")
        return finalImage
    }
} 