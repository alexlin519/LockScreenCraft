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
    private var imageCache = NSCache<NSString, UIImage>()
    
    private init() {
        // Get documents directory for storing uploaded images
        documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        
        // Configure image cache
        imageCache.countLimit = 50 // Maximum number of images to cache
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB cache limit
        
        loadAvailableBackgrounds()
        loadUserUploadedBackgrounds()
    }
    
    // Add cache helper methods
    func getCachedImage(for filename: String) -> UIImage? {
        return imageCache.object(forKey: filename as NSString)
    }
    
    func cacheImage(_ image: UIImage, for filename: String) {
        imageCache.setObject(image, forKey: filename as NSString)
    }
    
    func clearCache() {
        imageCache.removeAllObjects()
    }
    
    private func loadAvailableBackgrounds() {
        // Use the actual names from your asset catalog
        let backgroundNames = [
            "Simple Texture Image",
            "Simple Texture Image (1)",
            "Simple Texture Image (2)",
            "Simple Texture Image (3)",
            "Simple Texture Image (4)",
            "Simple Texture Image (5)",
            "Simple Texture Image (6)",
            "Simple Texture Image (7)",
            "Simple Texture Image (8)",
            "Simple Texture Image (9)",
            "Simple Texture Image (10)",
            "Simple Texture Image (11)",
            "Simple Texture Image (12)",
            "Simple Texture Image (13)",
            "Simple Texture Image (14)",
            "Simple Texture Image (15)",
            "Simple Texture Image (16)",
            "Simple Texture Image (17)",
            "Simple Texture Image (18)",
            "Simple Texture Image (19)"
        ]
        
        // Store these names for use in selection
        availableBackgrounds = backgroundNames
        
        // For debugging
        print("📸 Available backgrounds: \(availableBackgrounds.count)")
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
        // Instead of constructing paths manually:
        if let image = loadBackgroundImage(named: filename) {
            backgroundType = .image(image)
        } else {
            print("⚠️ Could not load background image: \(filename)")
        }
    }
    
    func randomizeBackground() {
        if !availableBackgrounds.isEmpty {
            let randomFileName = availableBackgrounds.randomElement()!
            selectBackground(named: randomFileName)
        } else {
            // Fallback to a solid color if no backgrounds are available
            backgroundType = .solidColor(.blue)
        }
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

// MARK: - New Helper Methods
extension WallpaperCompositionManager {
    func loadBackgroundImage(named filename: String) -> UIImage? {
        // First try loading from the asset catalog with the correct folder path
        if let image = UIImage(named: "Backgrounds_gallery/\(filename)") {
            return image
        }
        
        // Then try directly (in case the path structure is different)
        if let image = UIImage(named: filename) {
            return image
        }
        
        print("⚠️ Failed to load background: \(filename)")
        return nil
    }
} 