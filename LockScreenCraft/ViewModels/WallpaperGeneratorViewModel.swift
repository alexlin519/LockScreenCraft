import SwiftUI
import Foundation
import Photos

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
    @Published var currentProcessingFile: String?
    @Published var currentFileIndex: Int = 0
    
    // MARK: - Text Styling Properties
    private let maxFontSize: Double = 600.0  // Maximum font size limit
    private let minFontSize: Double = 3.0    // Minimum font size limit
    @Published var fontSize: Double = 100.0   // Default font size
    @Published var textAlignment: NSTextAlignment = .center
    @Published var isLoadingFonts: Bool = false
    @Published var lineSpacing: Double = -20.0 {  // Default line spacing
        didSet {
            updateWallpaperWithDebounce()
        }
    }
    @Published var wordSpacing: Double = 0.0 {  // Default word spacing
        didSet {
            updateWallpaperWithDebounce()
        }
    }
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
    
    // MARK: - Font Size Methods
    private var fontSizeDebounceTimer: Timer?
    @Published private(set) var fontSizeText: String = "300" {
        didSet {
            // Only validate if the text is not empty (user hasn't deleted all characters)
            if !fontSizeText.isEmpty {
                // Cancel any existing timer
                fontSizeDebounceTimer?.invalidate()
                
                // Create new timer that fires after user stops typing
                fontSizeDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    if let size = Double(self.fontSizeText) {
                        Task { @MainActor in
                            await self.validateAndSetFontSize(size)
                        }
                    }
                }
            }
        }
    }
    
    func updateFontSizeText(_ newText: String) {
        // Allow empty string during deletion
        if newText.isEmpty {
            fontSizeText = newText
            return
        }
        
        // Only accept numeric input
        if let _ = Double(newText) {
            fontSizeText = newText
        }
    }
    
    private func validateAndSetFontSize(_ size: Double) async {
        if size > maxFontSize {
            fontSize = maxFontSize
            fontSizeText = String(Int(maxFontSize))
            showError(message: "Font size cannot exceed \(Int(maxFontSize))")
        } else if size < minFontSize {
            fontSize = minFontSize
            fontSizeText = String(Int(minFontSize))
            showError(message: "Font size cannot be smaller than \(Int(minFontSize))")
        } else {
            fontSize = size.rounded()
            updateWallpaperWithDebounce()
        }
    }
    
    func increaseFontSize() {
        if fontSize < maxFontSize {
            fontSize += 1.0
            fontSizeText = String(Int(fontSize))
            updateWallpaperWithDebounce()
        } else {
            showError(message: "Font size cannot exceed \(Int(maxFontSize))")
        }
    }
    
    func decreaseFontSize() {
        if fontSize > minFontSize {
            fontSize -= 1.0
            fontSizeText = String(Int(fontSize))
            updateWallpaperWithDebounce()
        } else {
            showError(message: "Font size cannot be smaller than \(Int(minFontSize))")
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
        
        isGenerating = true
        print("🔤 Using font: \(selectedFont.fontName) with size: \(fontSize)")
        
        // Use FontManager to get the correct font
        let font = fontManager.getFont(name: selectedFont.fontName, size: CGFloat(fontSize))
        
        // Generate the text image with spacing parameters
        let textImage = textRenderer.renderText(
            processedText,
            font: font,
            color: UIColor(selectedColor),
            device: selectedDevice,
            alignment: textAlignment,
            lineSpacing: CGFloat(lineSpacing),
            wordSpacing: CGFloat(wordSpacing)
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
    
    // MARK: - Wallpaper Saving
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
    
    // MARK: - Development Helpers
    #if DEBUG
    @Published var availableTextFiles: [String] = []
    
    func loadAvailableTextFiles() async {
        print("📖 Loading available text files")
        let fileManager = FileManager.default
        let projectPath = "/Users/alexlin/project_code/LockScreenCraft/LockScreenCraft/Resources"
        let inputPath = projectPath + "/Input_text"
        
        do {
            // Create Input_text directory if it doesn't exist
            if !fileManager.fileExists(atPath: inputPath) {
                try fileManager.createDirectory(atPath: inputPath,
                                             withIntermediateDirectories: true)
                print("📁 Created Input_text directory")
                showError(message: "Please place your text files in Resources/Input_text folder")
                return
            }
            
            // Get all .txt files in the directory
            let files = try fileManager.contentsOfDirectory(atPath: inputPath)
                .filter { $0.hasSuffix(".txt") }
                .sorted()
            
            await MainActor.run {
                self.availableTextFiles = files
            }
            
            if files.isEmpty {
                print("❌ No .txt files found in Input_text directory")
                showError(message: "No .txt files found in Input_text folder")
            } else {
                print("📄 Found \(files.count) text files")
            }
        } catch {
            print("❌ Failed to read directory: \(error.localizedDescription)")
            showError(message: "Failed to read text files directory")
        }
    }
    
    func loadTextFromFile(_ filename: String) async {
        print("📖 Loading text from file: \(filename)")
        let projectPath = "/Users/alexlin/project_code/LockScreenCraft/LockScreenCraft/Resources"
        let inputPath = projectPath + "/Input_text"
        let filePath = (inputPath as NSString).appendingPathComponent(filename)
        
        do {
            // Read the file content
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            print("✅ Successfully read text from file")
            
            // Update the input text on the main thread
            await MainActor.run {
                self.inputText = content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            showError(message: "Text loaded from \(filename)")
        } catch {
            print("❌ Failed to read text file: \(error.localizedDescription)")
            showError(message: "Failed to read text file: \(error.localizedDescription)")
        }
    }
    
    private func showSuccess(message: String) {
        errorMessage = message  // We can use the same message property
        showError = true       // But maybe rename this property to something like 'showAlert'
    }
    
    func saveWallpaperToDesktop() async -> URL? {
        print("💾 Saving wallpaper to external folder")
        guard let image = generatedImage else {
            showError(message: "No wallpaper generated")
            return nil
        }
        
        let fileManager = FileManager.default
        // Use external output path
        let outputPath = "/Users/alexlin/Downloads/wallpaper-out-xcode"
        
        // Create a filename-safe timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let deviceName = selectedDevice.modelName.replacingOccurrences(of: " ", with: "_")
        let filename = "Wallpaper_\(deviceName)_\(timestamp).png"
        
        // Create URL for the save location
        let fileURL = URL(fileURLWithPath: outputPath).appendingPathComponent(filename)
        
        print("📝 Attempting to save to: \(fileURL.path)")
        
        do {
            if let imageData = image.pngData() {
                try fileManager.createDirectory(atPath: outputPath,
                                             withIntermediateDirectories: true)
                
                try imageData.write(to: fileURL, options: .atomic)
                print("✅ Wallpaper saved successfully to: \(fileURL.path)")
                showSuccess(message: "Wallpaper saved successfully")
                return fileURL
            } else {
                print("❌ Failed to convert image to PNG data")
                showError(message: "Failed to convert image to PNG")
                return nil
            }
        } catch {
            print("❌ Failed to save wallpaper: \(error.localizedDescription)")
            print("🔍 Error details: \(error)")
            showError(message: "Failed to save wallpaper: \(error.localizedDescription)")
            return nil
        }
    }
    #endif
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    // MARK: - Randomization Methods
    func randomizeAll() {
        randomizeFont()
        randomizeColor()
        randomizeBackground()
    }
    
    private func randomizeFont() {
        guard !availableFonts.isEmpty else { return }
        let randomFont = availableFonts.randomElement()!
        selectedFont = randomFont
    }
    
    private func randomizeColor() {
        // Define a range of vibrant colors
        let colors: [Color] = [
            .black, .blue, .red, .green, .purple, .orange,
            .pink, .indigo, .mint, .teal, .cyan, .brown
        ]
        selectedColor = colors.randomElement()!
    }
    
    private func randomizeBackground() {
        let compositionManager = WallpaperCompositionManager.shared
        
        // Only select from available background images
        if let randomImage = compositionManager.availableBackgrounds.randomElement() {
            compositionManager.selectBackground(named: randomImage)
        }
    }
    
    init() {
        print("⚙️ Starting ViewModel initialization")
        self.selectedDevice = DeviceConfig.iPhone12ProMax
        self.selectedFont = FontDisplayInfo(fontName: "System Font", displayName: "系统字体")
        
        print("🚀 Initializing WallpaperGeneratorViewModel")
        fontManager.registerFonts()
        updateAvailableFonts()
        
        createRequiredDirectories()
        print("✅ ViewModel initialization complete")
    }
    
    private func createRequiredDirectories() {
        let fileManager = FileManager.default
        // Use hardcoded project path for development
        let projectPath = "/Users/alexlin/project_code/LockScreenCraft/LockScreenCraft/Resources"
        
        // First ensure Resources directory exists
        if !fileManager.fileExists(atPath: projectPath) {
            do {
                try fileManager.createDirectory(atPath: projectPath,
                                             withIntermediateDirectories: true)
                print("📁 Created Resources directory")
            } catch {
                print("❌ Failed to create Resources directory: \(error.localizedDescription)")
            }
        }
        
        let directories = [
            projectPath + "/Input_text",
            projectPath + "/WallpaperGenerated"
        ]
        
        for directory in directories {
            if !fileManager.fileExists(atPath: directory) {
                do {
                    try fileManager.createDirectory(atPath: directory,
                                                 withIntermediateDirectories: true)
                    print("📁 Created directory: \(directory)")
                } catch {
                    print("❌ Failed to create directory \(directory): \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateAvailableFonts() {
        print("🔄 Updating available fonts")
        isLoadingFonts = true
        
        // Get all fonts
        availableFonts = fontManager.getAllAvailableFonts()
        print("📚 Found \(availableFonts.count) fonts")
        
        isLoadingFonts = false
    }
    
    // Add this struct
    struct TextFileSettings {
        let filename: String
        var fontName: String
        var fontSize: Double
        var lineSpacing: Double
        var wordSpacing: Double
        var color: Color
        var backgroundType: BackgroundType
    }
    
    // Add settings storage
    @Published private var fileSettings: [String: TextFileSettings] = [:]
    
    // Save settings when generating wallpaper
    func saveCurrentSettings(for filename: String) {
        let settings = TextFileSettings(
            filename: filename,
            fontName: selectedFont.fontName,
            fontSize: fontSize,
            lineSpacing: lineSpacing,
            wordSpacing: wordSpacing,
            color: selectedColor,
            backgroundType: WallpaperCompositionManager.shared.backgroundType ?? .solidColor(.white) // Provide default
        )
        fileSettings[filename] = settings
    }
    
    // Load settings for a file
    func loadTextAndSettings(_ filename: String) async {
        await loadTextFromFile(filename)
        if let settings = fileSettings[filename] {
            // Restore previous settings
            selectedFont = FontDisplayInfo(fontName: settings.fontName, displayName: "")
            fontSize = settings.fontSize
            lineSpacing = settings.lineSpacing
            wordSpacing = settings.wordSpacing
            selectedColor = settings.color
            WallpaperCompositionManager.shared.backgroundType = settings.backgroundType
        }
    }
    
    // New property for iOS
    @Published var showingFilePicker: Bool = false
    
    // Store selected file URLs
    private var selectedFileURLs: [URL] = []
    
    // MARK: - File Processing Methods
    
    // Show file picker on iOS
    func startProcessingAllFiles() async {
        showingFilePicker = true
    }
    
    // Process files selected from iOS file picker
    func processSelectedFiles(_ urls: [URL]) async {
        guard !urls.isEmpty else { return }
        
        selectedFileURLs = urls
        availableTextFiles = urls.map { $0.lastPathComponent }
        
        currentFileIndex = 0
        currentProcessingFile = availableTextFiles.first
        
        if let firstURL = urls.first {
            do {
                let content = try String(contentsOf: firstURL)
                inputText = content
                await generateWallpaper()
            } catch {
                print("Error loading file: \(error)")
            }
        }
    }
    
    // Select a specific file
    func selectFileAt(index: Int) async {
        guard index >= 0, index < selectedFileURLs.count else { return }
        
        currentFileIndex = index
        currentProcessingFile = availableTextFiles[index]
        
        do {
            let content = try String(contentsOf: selectedFileURLs[index])
            inputText = content
            await generateWallpaper()
        } catch {
            print("Error loading file: \(error)")
        }
    }
    
    // Load text from a URL
    func loadTextFromURL(_ url: URL) async {
        do {
            let content = try String(contentsOf: url)
            await MainActor.run {
                inputText = content
            }
            print("📄 Loaded text from \(url.lastPathComponent)")
        } catch {
            print("❌ Error loading text: \(error)")
        }
    }
    
    // Save and move to next file
    func saveAndProcessNext() async {
        // Always save to Photos
        await saveToPhotos()
        
        // Only process next file if we have files
        if !availableTextFiles.isEmpty {
            // Move to next file
            currentFileIndex += 1
            if currentFileIndex < availableTextFiles.count {
                currentProcessingFile = availableTextFiles[currentFileIndex]
                
                if currentFileIndex < selectedFileURLs.count {
                    do {
                        let content = try String(contentsOf: selectedFileURLs[currentFileIndex])
                        inputText = content
                        await generateWallpaper()
                    } catch {
                        print("Error loading file: \(error)")
                    }
                }
            } else {
                currentProcessingFile = nil
            }
        }
    }
    
    // MARK: - Image Methods
    
    @Published var successMessage: String = ""
    @Published var showSuccess: Bool = false
    
    func saveToPhotos() async {
        guard let image = generatedImage else {
            print("No image to save")
            showError(message: "No image to save")
            return
        }
        
        // Actual save implementation with minimal code
        await MainActor.run {
            // Most basic implementation possible
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            
            // Show success message using your existing method
            showSuccess(message: "Wallpaper saved to Photos")
        }
    }
} 
