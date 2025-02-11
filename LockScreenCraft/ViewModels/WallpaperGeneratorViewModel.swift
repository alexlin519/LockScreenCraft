import SwiftUI
import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// Remove the @_exported imports since we're in the same module

@MainActor
class WallpaperGeneratorViewModel: ObservableObject {

    // MARK: - Device Configuration
    let availableDevices: [DeviceConfig] = [
        .iPhone12ProMax,
        // Add other devices here
        DeviceConfig(
            modelName: "iPhone 15 Pro",
            resolution: CGSize(width: 1179, height: 2556),
            safeArea: UIEdgeInsets(top: 200, left: 0, bottom: 150, right: 0)
        )
    ]

    // MARK: - Published Properties
    @Published var inputText: String = ""
    @Published var selectedDevice: DeviceConfig
    @Published var generatedImage: PlatformImage?
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Text Styling Properties
    @Published var fontSize: Double = 90.0
    @Published var textAlignment: NSTextAlignment = .center
    @Published var isLoadingFonts: Bool = false
    
    // MARK: - Font Management
    private var fontDebounceTimer: Timer?
    private let textRenderer = TextRenderer.shared
    private let photoService = PhotoService.shared
    private let fontManager = FontManager.shared
    
    // MARK: - Published Properties for Fonts
    @Published var availableFonts: [FontDisplayInfo] = []
    @Published var selectedFont: FontDisplayInfo {
        didSet {
            print("📝 Font selected: \(selectedFont.fontName) (\(selectedFont.displayName))")
            updateWallpaperWithDebounce()
        }
    }
    
    init() {
        self.selectedDevice = DeviceConfig.iPhone12ProMax
        // Initialize with system font
        self.selectedFont = FontDisplayInfo(fontName: "System Font", displayName: "系统字体")
        
        // Initialize fonts
        print("🚀 Initializing WallpaperGeneratorViewModel")
        fontManager.registerFonts()
        updateAvailableFonts()
    }
    
    private func updateAvailableFonts() {
        print("🔄 Updating available fonts")
        isLoadingFonts = true
        
        // Get all fonts
        availableFonts = fontManager.getAllAvailableFonts()
        print("📚 Found \(availableFonts.count) fonts")
        
        isLoadingFonts = false
    }
    
    // MARK: - Font Size Methods
    func increaseFontSize() {
        if fontSize < 200.0 {
            fontSize += 1.0
            updateWallpaperWithDebounce()
        }
    }
    
    func decreaseFontSize() {
        if fontSize > 3.0 {
            fontSize -= 1.0
            updateWallpaperWithDebounce()
        }
    }
    
    func setFontSize(_ size: Double) {
        fontSize = min(max(size.rounded(), 3.0), 200.0)
        updateWallpaperWithDebounce()
    }
    
    // MARK: - Text Alignment Methods
    func setTextAlignment(_ alignment: NSTextAlignment) {
        textAlignment = alignment
        updateWallpaperWithDebounce()
    }
    
    // MARK: - Font Selection Methods
    func setFont(_ font: FontDisplayInfo) {
        print("✏️ Setting font to: \(font.fontName) (\(font.displayName))")
        selectedFont = font
    }
    
    // MARK: - Wallpaper Generation
    private func updateWallpaperWithDebounce() {
        fontDebounceTimer?.invalidate()
        fontDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.generateWallpaper()
            }
        }
    }
    
    func generateWallpaper() async {
        print("🎨 Starting wallpaper generation")
        // Use default text when input is empty
        let finalText = inputText.isEmpty ? "test test \\ 1237890\\ 在黑洞边缘坍塌，//我喝多了火焰，又发誓与神为敌。" : inputText
        
        // Process text with line breaks
        let processedText = finalText
            .replacingOccurrences(of: "\\\\", with: "\n")
            .replacingOccurrences(of: "\\", with: "\n")
            .replacingOccurrences(of: "//", with: "\n")
            
        guard processedText.count <= 200 else {
            showError(message: "Text must be 200 characters or less")
            return
        }
        
        isGenerating = true
        print("🔤 Using font: \(selectedFont.fontName) with size: \(fontSize)")
        
        // Use FontManager to get the correct font
        let font = fontManager.getFont(name: selectedFont.fontName, size: CGFloat(fontSize))
        
        generatedImage = textRenderer.renderText(
            processedText,
            font: font,
            color: .black,
            device: selectedDevice,
            alignment: textAlignment
        )
        
        if generatedImage == nil {
            print("⚠️ Failed to generate image")
            showError(message: "Failed to generate wallpaper")
        } else {
            print("✅ Successfully generated wallpaper")
        }
        
        isGenerating = false
    }
    
    func saveWallpaper() async {
        guard let image = generatedImage else {
            showError(message: "No wallpaper generated")
            return
        }
        
        do {
            try await photoService.saveImage(image)
        } catch PhotoServiceError.permissionDenied {
            showError(message: "Photo library access denied")
        } catch {
            showError(message: "Failed to save wallpaper")
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
} 
