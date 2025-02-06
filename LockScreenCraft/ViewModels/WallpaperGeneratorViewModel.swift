import SwiftUI
import UIKit

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
    @Published var generatedImage: UIImage?
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Text Styling Properties
    @Published var fontSize: Double = 90.0
    @Published var textAlignment: NSTextAlignment = .center
    @Published var selectedFontCategory: FontCategory = .system
    @Published var selectedFont: String = "System"
    @Published var isLoadingFonts: Bool = false
    
    // MARK: - Font Management
    enum FontCategory: String, CaseIterable {
        case system = "System"
        case chinese = "Chinese"
        case english = "English"
        case handwriting = "Handwriting"
    }
    
    private var fontDebounceTimer: Timer?
    private let textRenderer = TextRenderer.shared
    private let photoService = PhotoService.shared
    
    init() {
        //self.selectedDevice = DeviceManager.shared.defaultDevice
        // Ensure default device exists in `availableDevices`
        self.selectedDevice = DeviceConfig.iPhone12ProMax  // Replace with your own default
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
    func setFontCategory(_ category: FontCategory) {
        selectedFontCategory = category
        // Reset to default font for the category
        selectedFont = getFontsForCategory(category).first ?? "System"
        updateWallpaperWithDebounce()
    }
    
    func setFont(_ fontName: String) {
        selectedFont = fontName
        updateWallpaperWithDebounce()
    }
    
    func getFontsForCategory(_ category: FontCategory) -> [String] {
        switch category {
        case .system:
            return ["System"]
        case .chinese:
            return ["LXGW WenKai", "Source Han Sans CN"]
        case .english:
            return ["SF Pro", "SF Mono", "New York"]
        case .handwriting:
            return ["SF Pro Rounded", "Comic Sans MS"]
        }
    }
    
    // MARK: - Wallpaper Generation
    private func updateWallpaperWithDebounce() {
        fontDebounceTimer?.invalidate()
        fontDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.generateWallpaper()
        }
    }
    
    func generateWallpaper() {
        // Use default text when input is empty
        let finalText = inputText.isEmpty ? "test test \\ 在黑洞边缘坍塌，//我喝多了火焰，又发誓与神为敌。" : inputText
        
        // Process text with line breaks
        let processedText = finalText  // Changed from inputText to finalText
            .replacingOccurrences(of: "\\\\", with: "\n")  // Handle escaped backslashes
            .replacingOccurrences(of: "\\", with: "\n")     // Replace single backslashes
            .replacingOccurrences(of: "//", with: "\n")
            
        guard processedText.count <= 200 else {
            showError(message: "Text must be 200 characters or less")
            return
        }
        
        isGenerating = true
        
        let font = UIFont(name: selectedFont, size: CGFloat(fontSize)) ?? .systemFont(ofSize: CGFloat(fontSize))
        
        generatedImage = textRenderer.renderText(
            processedText,
            font: font,
            color: .black,
            device: selectedDevice,
            alignment: textAlignment
        )
        
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
