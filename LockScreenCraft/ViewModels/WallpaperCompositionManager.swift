import SwiftUI

// MARK: - Background Types
enum GradientDirection {
    case linear(angle: Double)
    case radial
}

struct GradientConfig {
    var startColor: Color
    var endColor: Color
    var direction: GradientDirection
}

struct FrostedConfig {
    var baseColor: Color
    var intensity: Double  // 0-1
    var opacity: Double    // 0-1
}

enum BackgroundType {
    case image(UIImage)
    case solidColor(Color)
    case gradient(GradientConfig)
    case frosted(FrostedConfig)
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
    @Published var userUploadedBackgrounds: [UIImage] = []
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let fileManager = FileManager.default
    private let documentsPath: String
    
    private init() {
        // Get documents directory for storing uploaded images
        documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        loadAvailableBackgrounds()
        loadUserUploadedBackgrounds()
    }
    
    private func loadAvailableBackgrounds() {
        print("\n=== 🔍 DEBUG: Loading Available Backgrounds ===")
        
        // Try loading directly from the workspace path
        let workspacePath = "/Users/alexlin/LockScreenCraft/LockScreenCraft/Resources/Background"
        print("\n📂 Checking workspace path: \(workspacePath)")
        
        if FileManager.default.fileExists(atPath: workspacePath) {
            print("✅ Background directory exists in workspace")
            do {
                let items = try FileManager.default.contentsOfDirectory(atPath: workspacePath)
                let imageFiles = items.filter { 
                    let fileExtension = ($0 as NSString).pathExtension.lowercased()
                    return ["jpg", "jpeg", "png"].contains(fileExtension)
                }.sorted()
                
                print("📝 Found \(imageFiles.count) image files:")
                imageFiles.forEach { print("   • \($0)") }
                
                // Update available backgrounds
                availableBackgrounds = imageFiles
                
                // Verify each image can be loaded
                for filename in imageFiles {
                    let fullPath = (workspacePath as NSString).appendingPathComponent(filename)
                    if let _ = UIImage(contentsOfFile: fullPath) {
                        print("✅ Successfully verified image: \(filename)")
                    } else {
                        print("⚠️ Failed to load image: \(filename)")
                    }
                }
            } catch {
                print("❌ Error reading workspace directory: \(error.localizedDescription)")
            }
        } else {
            print("❌ Background directory not found in workspace")
        }
        
        print("\n📝 Final Summary:")
        print("• Available Backgrounds Count: \(availableBackgrounds.count)")
        print("=== 🔍 DEBUG: Background Loading End ===\n")
    }
    
    private func loadUserUploadedBackgrounds() {
        let uploadsPath = (documentsPath as NSString).appendingPathComponent("UploadedBackgrounds")
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: uploadsPath) {
            try? fileManager.createDirectory(atPath: uploadsPath, withIntermediateDirectories: true)
        }
        
        // Load existing uploaded images
        if let files = try? fileManager.contentsOfDirectory(atPath: uploadsPath) {
            for file in files {
                let filePath = (uploadsPath as NSString).appendingPathComponent(file)
                if let image = UIImage(contentsOfFile: filePath) {
                    userUploadedBackgrounds.append(image)
                }
            }
        }
    }
    
    func addUploadedBackground(_ image: UIImage) {
        userUploadedBackgrounds.append(image)
        
        // Save image to documents directory
        let uploadsPath = (documentsPath as NSString).appendingPathComponent("UploadedBackgrounds")
        let fileName = "upload_\(Date().timeIntervalSince1970).jpg"
        let filePath = (uploadsPath as NSString).appendingPathComponent(fileName)
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: URL(fileURLWithPath: filePath))
        }
    }
    
    func selectUploadedBackground(_ image: UIImage) {
        backgroundType = .image(image)
        backgroundTransform.reset()
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
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        print("📐 Device Resolution: \(device.resolution)")
        
        let renderer = UIGraphicsImageRenderer(
            size: device.resolution,
            format: format
        )
        
        return renderer.image { context in
            switch backgroundType {
            case .image(let backgroundImage):
                drawImage(backgroundImage, in: context, size: device.resolution)
                
            case .solidColor(let color):
                UIColor(color).setFill()
                context.fill(CGRect(origin: .zero, size: device.resolution))
                
            case .gradient(let config):
                drawGradient(config, in: context, size: device.resolution)
                
            case .frosted(let config):
                drawFrostedEffect(config, in: context, size: device.resolution)
                
            case .none:
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: device.resolution))
            }
            
            // Draw text image on top
            textImage.draw(in: CGRect(origin: .zero, size: device.resolution))
        }
    }
    
    private func drawImage(_ image: UIImage, in context: UIGraphicsImageRendererContext, size: CGSize) {
        let bgSize = image.size
        let widthRatio = size.width / bgSize.width
        let heightRatio = size.height / bgSize.height
        let baseScale = max(widthRatio, heightRatio)
        
        // Apply transform scale
        let finalScale = baseScale * backgroundTransform.scale
        let scaledWidth = bgSize.width * finalScale
        let scaledHeight = bgSize.height * finalScale
        
        // Calculate center position
        let centerX = (size.width - scaledWidth) / 2
        let centerY = (size.height - scaledHeight) / 2
        
        // Apply transform offset
        let finalX = centerX + backgroundTransform.offset.width
        let finalY = centerY + backgroundTransform.offset.height
        
        image.draw(in: CGRect(x: finalX, y: finalY, width: scaledWidth, height: scaledHeight))
    }
    
    private func drawGradient(_ config: GradientConfig, in context: UIGraphicsImageRendererContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        let context = context.cgContext
        
        switch config.direction {
        case .linear(let angle):
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [UIColor(config.startColor).cgColor, UIColor(config.endColor).cgColor] as CFArray,
                locations: [0, 1]
            )!
            
            let centerPoint = CGPoint(x: rect.midX, y: rect.midY)
            let radius = sqrt(pow(size.width, 2) + pow(size.height, 2)) / 2
            
            let angleInRadians = CGFloat(angle * .pi / 180)
            let startPoint = CGPoint(
                x: centerPoint.x - radius * CoreGraphics.cos(angleInRadians),
                y: centerPoint.y - radius * CoreGraphics.sin(angleInRadians)
            )
            let endPoint = CGPoint(
                x: centerPoint.x + radius * CoreGraphics.cos(angleInRadians),
                y: centerPoint.y + radius * CoreGraphics.sin(angleInRadians)
            )
            
            context.drawLinearGradient(
                gradient,
                start: startPoint,
                end: endPoint,
                options: []
            )
            
        case .radial:
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [UIColor(config.startColor).cgColor, UIColor(config.endColor).cgColor] as CFArray,
                locations: [0, 1]
            )!
            
            let centerPoint = CGPoint(x: rect.midX, y: rect.midY)
            let radius = sqrt(pow(size.width, 2) + pow(size.height, 2)) / 2
            
            context.drawRadialGradient(
                gradient,
                startCenter: centerPoint,
                startRadius: 0,
                endCenter: centerPoint,
                endRadius: radius,
                options: []
            )
        }
    }
    
    private func drawFrostedEffect(_ config: FrostedConfig, in context: UIGraphicsImageRendererContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        
        // Draw base color with opacity
        UIColor(config.baseColor).withAlphaComponent(config.opacity).setFill()
        context.fill(rect)
        
        // Apply blur effect
        let blur = CIFilter(name: "CIGaussianBlur")!
        blur.setValue(config.intensity * 20, forKey: kCIInputRadiusKey)
        
        if let blurredImage = context.currentImage.applyBlur(intensity: config.intensity) {
            blurredImage.draw(in: rect)
        }
    }
}

// MARK: - UIImage Extension for Blur
extension UIImage {
    func applyBlur(intensity: Double) -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }
        
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(intensity * 20, forKey: kCIInputRadiusKey)
        
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
} 