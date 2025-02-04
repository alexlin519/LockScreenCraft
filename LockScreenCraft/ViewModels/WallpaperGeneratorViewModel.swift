import SwiftUI

@MainActor
class WallpaperGeneratorViewModel: ObservableObject {

    // Add AVAILABLE DEVICES list
    let availableDevices: [DeviceConfig] = [
        .iPhone12ProMax,
        // Add other devices here
        DeviceConfig(
            modelName: "iPhone 15 Pro",
            resolution: CGSize(width: 1179, height: 2556),
            safeArea: UIEdgeInsets(top: 200, left: 0, bottom: 150, right: 0)
        )
    ]

    @Published var inputText: String = ""
    @Published var selectedDevice: DeviceConfig
    @Published var generatedImage: UIImage?
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let textRenderer = TextRenderer.shared
    private let photoService = PhotoService.shared
    
    init() {
        //self.selectedDevice = DeviceManager.shared.defaultDevice
        // Ensure default device exists in `availableDevices`
        self.selectedDevice = DeviceConfig.iPhone12ProMax  // Replace with your own default
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
        
        // Use system font for now, can be customizable later
        let font = UIFont.systemFont(ofSize: 17)
        
        generatedImage = textRenderer.renderText(
            processedText, 
            font: font,
            color: .black,
            device: selectedDevice
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
