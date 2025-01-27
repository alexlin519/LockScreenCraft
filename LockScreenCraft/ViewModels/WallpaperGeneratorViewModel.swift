import SwiftUI

@MainActor
class WallpaperGeneratorViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var selectedDevice: DeviceConfig
    @Published var generatedImage: UIImage?
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let textRenderer = TextRenderer.shared
    private let photoService = PhotoService.shared
    
    init() {
        self.selectedDevice = DeviceManager.shared.defaultDevice
    }
    
    func generateWallpaper() {
        guard !inputText.isEmpty else {
            showError(message: "Please enter some text")
            return
        }
        
        guard inputText.count <= 200 else {
            showError(message: "Text must be 200 characters or less")
            return
        }
        
        isGenerating = true
        
        // Use system font for now, can be customizable later
        let font = UIFont.systemFont(ofSize: 17)
        
        generatedImage = textRenderer.renderText(
            inputText,
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