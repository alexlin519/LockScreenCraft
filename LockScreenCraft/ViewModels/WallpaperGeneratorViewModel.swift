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
    private let maxFontSize: Double = 600.0  // Maximum font size limit
    private let minFontSize: Double = 3.0    // Minimum font size limit
    @Published var fontSize: Double = 300.0   // Default font size
    @Published var textAlignment: NSTextAlignment = .center
    @Published var isLoadingFonts: Bool = false
    @Published var selectedColor: Color = .black {
        didSet {
            updateWallpaperWithDebounce()
        }
    }
    @Published var showColorPicker = false {
        didSet {
            if !showColorPicker {
                // When color picker is dismissed, update the wallpaper
                updateWallpaperWithDebounce()
            }
        }
    }
    @Published var savedColors: [Color] = [
        .black,
        .gray,
        .white,
        .red,
        .orange,
        .yellow,
        .green,
        .blue,
        .purple,
        .pink
    ]
    
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
        if fontSize < maxFontSize {
            fontSize += 1.0
            updateWallpaperWithDebounce()
        } else {
            showError(message: "Font size cannot exceed \(Int(maxFontSize))")
        }
    }
    
    func decreaseFontSize() {
        if fontSize > minFontSize {
            fontSize -= 1.0
            updateWallpaperWithDebounce()
        } else {
            showError(message: "Font size cannot be smaller than \(Int(minFontSize))")
        }
    }
    
    func setFontSize(_ size: Double) {
        if size > maxFontSize {
            showError(message: "Font size cannot exceed \(Int(maxFontSize))")
            fontSize = maxFontSize
        } else if size < minFontSize {
            showError(message: "Font size cannot be smaller than \(Int(minFontSize))")
            fontSize = minFontSize
        } else {
            fontSize = size.rounded()
        }
        updateWallpaperWithDebounce()
    }
    
    func setFontSizeFromString(_ sizeString: String) {
        if let size = Double(sizeString) {
            setFontSize(size)
        } else {
            showError(message: "Please enter a valid number")
        }
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
        let finalText = inputText.isEmpty ? " 浮生暂寄梦中梦，\\ 世事如闻风里风。\\qyilofjlk \\ 1237890" : inputText
        
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
        
        // Generate the text image
        let textImage = textRenderer.renderText(
            processedText,
            font: font,
            color: UIColor(selectedColor),
            device: selectedDevice,
            alignment: textAlignment
        )
        
        // Generate the final composite image
        let compositionManager = WallpaperCompositionManager.shared
        if let finalImage = compositionManager.generateFinalImage(withText: textImage, device: selectedDevice) {
            print("✅ Successfully generated wallpaper with background")
            generatedImage = finalImage
        } else {
            print("⚠️ Failed to composite with background, using text-only image")
            generatedImage = textImage
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
