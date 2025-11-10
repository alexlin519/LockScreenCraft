import SwiftUI
import Foundation
import Photos
import UIKit

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
    @Published var fontSize: Double = 100.0 {   // Default font size
        didSet {
            // Trigger fast wallpaper update when fontSize changes (shorter debounce for slider responsiveness)
            updateWallpaperFast()
        }
    }
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
    
    // MARK: - Font Category Filter for Randomization
    @Published var randomFontCategoryFilter: FontCategory? = nil // nil means "全部风格" (All Styles)
    
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
            // Note: didSet on fontSize will trigger update automatically
        }
    }
    
    func increaseFontSize() {
        if fontSize < maxFontSize {
            fontSize += 1.0
            fontSizeText = String(Int(fontSize))
            // Note: didSet on fontSize will trigger update automatically
        } else {
            showError(message: "Font size cannot exceed \(Int(maxFontSize))")
        }
    }
    
    func decreaseFontSize() {
        if fontSize > minFontSize {
            fontSize -= 1.0
            fontSizeText = String(Int(fontSize))
            // Note: didSet on fontSize will trigger update automatically
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
    private func updateWallpaperWithDebounce(delay: TimeInterval = 0.5) {
        fontDebounceTimer?.invalidate()
        fontDebounceTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.generateWallpaper()
            }
        }
    }
    
    // Fast update for slider dragging (shorter debounce for better responsiveness)
    private func updateWallpaperFast() {
        updateWallpaperWithDebounce(delay: 0.1)
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
    
    // MARK: - Randomization Methods
    func randomizeAll() {
        randomizeFont()
        randomizeColor()
        randomizeBackground()
    }
    
    private func randomizeFont() {
        // Get fonts filtered by selected category (nil means all fonts)
        let filteredFonts = fontManager.getFonts(byCategory: randomFontCategoryFilter)
        
        guard !filteredFonts.isEmpty else {
            // If no fonts in selected category, fallback to all fonts
            guard !availableFonts.isEmpty else { return }
            let randomFont = availableFonts.randomElement()!
            selectedFont = randomFont
            return
        }
        
        let randomFont = filteredFonts.randomElement()!
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
        
        // Get counts from both sources
        let galleryCount = compositionManager.availableBackgrounds.count
        let uploadedCount = compositionManager.userUploadedBackgrounds.count
        let totalCount = galleryCount + uploadedCount
        
        // If no backgrounds available, fallback to a random solid color
        guard totalCount > 0 else {
            let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .red]
            compositionManager.backgroundType = .solidColor(colors.randomElement() ?? .blue)
            return
        }
        
        // Generate a random index from 0 to totalCount - 1
        // This ensures each background has equal probability of being selected
        let randomIndex = Int.random(in: 0..<totalCount)
        
        // If randomIndex is within gallery range, select from gallery
        // Otherwise, select from uploaded backgrounds
        if randomIndex < galleryCount {
            // Select from gallery backgrounds
            let selectedBackground = compositionManager.availableBackgrounds[randomIndex]
            compositionManager.selectBackground(named: selectedBackground)
        } else {
            // Select from uploaded backgrounds
            let uploadedIndex = randomIndex - galleryCount
            let selectedImage = compositionManager.userUploadedBackgrounds[uploadedIndex]
            compositionManager.selectUploadedBackground(selectedImage)
        }
    }
    
    init() {
        print("⚙️ Starting ViewModel initialization")
        
        // Initialize all stored properties first
        self.selectedDevice = DeviceConfig.iPhone12ProMax
        // Initialize selectedFont with a temporary value to satisfy Swift's initialization requirements
        // We'll update it after availableFonts is populated
        self.selectedFont = FontDisplayInfo(fontName: "System Font", displayName: "系统字体")
        
        print("🚀 Initializing WallpaperGeneratorViewModel")
        fontManager.registerFonts()
        
        // Now we can safely call methods since all stored properties are initialized
        // Update available fonts (this accesses availableFonts which is already initialized to [])
        availableFonts = fontManager.getAllAvailableFonts()
        print("📚 Found \(availableFonts.count) fonts")
        
        // Set default font to first available font (since System Font is removed)
        if let firstFont = availableFonts.first {
            self.selectedFont = firstFont
            print("✅ Set default font to: \(firstFont.displayName)")
        } else {
            // Fallback if no fonts available (shouldn't happen)
            print("⚠️ No fonts available, using fallback")
        }
        
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
    
    // MARK: - File Processing Properties
    @Published var availableTextFiles: [String] = []
    @Published var showingFilePicker: Bool = false
    private var selectedFileURLs: [URL] = []
    
    // MARK: - File Processing Methods
    
    func startProcessingAllFiles() async {
        showingFilePicker = true
    }
    
    func processSelectedFiles(_ urls: [URL]) async {
        guard !urls.isEmpty else { return }
        
        selectedFileURLs = urls
        availableTextFiles = urls.map { $0.lastPathComponent }
        
        currentFileIndex = 0
        currentProcessingFile = availableTextFiles.first
        
        if let firstURL = urls.first {
            await loadTextFromURL(firstURL)
        }
    }
    
    func selectFileAt(index: Int) async {
        guard index >= 0, index < selectedFileURLs.count else { return }
        
        currentFileIndex = index
        currentProcessingFile = availableTextFiles[index]
        
        if index < selectedFileURLs.count {
            await loadTextFromURL(selectedFileURLs[index])
        }
    }
    
    func loadTextFromURL(_ url: URL) async {
        do {
            let content = try String(contentsOf: url)
            inputText = content
            await generateWallpaper()
            print("📄 Loaded text from \(url.lastPathComponent)")
        } catch {
            print("❌ Error loading text: \(error)")
        }
    }
    
    func loadTextFromFile(_ filename: String) async {
        if let index = availableTextFiles.firstIndex(of: filename),
           index < selectedFileURLs.count {
            await loadTextFromURL(selectedFileURLs[index])
        } else {
            print("⚠️ Could not find file: \(filename)")
        }
    }
    
    func saveAndProcessNext() async {
        // Save current wallpaper
        await saveToPhotos()
        
        // Process next file if available
        if !availableTextFiles.isEmpty {
            let nextIndex = currentFileIndex + 1
            if nextIndex < availableTextFiles.count {
                await selectFileAt(index: nextIndex)
            } else {
                currentProcessingFile = nil
            }
        }
    }
    
    // MARK: - Photo Library Methods
    
    func saveToPhotos() async {
        guard let image = generatedImage else {
            print("❌ No image to save")
            showError(message: "No image to save")
            return
        }
        
        // Use the simplest implementation that works reliably
        UIImageWriteToSavedPhotosAlbum(
            image,
            nil,  // No delegate needed for simple implementation
            nil,  // No callback method
            nil   // No context info
        )
        
        // Show success message
        print("✅ Image saved to Photos")
        showSuccess(message: "Wallpaper saved to Photos")
    }
    
    // MARK: - Image Methods
    
    @Published var successMessage: String = ""
    @Published var showSuccess: Bool = false
    
    // Helper method to show error messages
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }

    // Helper method to show success messages
    func showSuccess(message: String) {
        errorMessage = message  // Using errorMessage for both error and success
        showError = true        // Using showError as a general alert flag
    }

    // Add these properties to your existing WallpaperGeneratorViewModel class
    @Published var splitParagraphs: [String] = []
    @Published var showingTextSplitterSheet = false
    @Published var showingParagraphBrowser = false

    // Add these methods to your existing WallpaperGeneratorViewModel class
    func setSplitParagraphs(_ paragraphs: [String]) {
        splitParagraphs = paragraphs
        
        // Simply store the paragraphs but don't auto-load anything
        // Don't trigger any automatic generation
        // Don't jump tabs
        
        // Just close the sheet
        showingTextSplitterSheet = false
    }

    func useFirstParagraph() {
        if let firstParagraph = splitParagraphs.first, !firstParagraph.isEmpty {
            inputText = firstParagraph
            // Generate the wallpaper but don't switch tabs
            Task {
                await generateWallpaper()
            }
        }
    }

    func useNextParagraph() {
        guard let currentIndex = currentParagraphIndex(),
              currentIndex < splitParagraphs.count - 1 else { return }
        
        // Set the input text to the next paragraph
        inputText = splitParagraphs[currentIndex + 1]
        
        // Generate the wallpaper with the new text
        Task {
            await generateWallpaper()
        }
    }

    func browseAllParagraphs() {
        if !splitParagraphs.isEmpty {
            showingParagraphBrowser = true
        }
    }

    // Add these helper methods for paragraph navigation
    func currentParagraphIndex() -> Int? {
        return splitParagraphs.firstIndex(of: inputText)
    }

    func hasPreviousParagraph() -> Bool {
        guard let currentIndex = currentParagraphIndex() else { return false }
        return currentIndex > 0
    }

    func hasNextParagraph() -> Bool {
        guard let currentIndex = currentParagraphIndex() else { return false }
        return currentIndex < splitParagraphs.count - 1
    }

    // Add this method to handle paragraph operations without locking tab navigation
    func handleSplitParagraphs() {
        // Allow processing paragraphs without restricting navigation
        if !splitParagraphs.isEmpty {
            // Use the first paragraph if available
            if let firstParagraph = splitParagraphs.first, !firstParagraph.isEmpty {
                inputText = firstParagraph
                Task {
                    await generateWallpaper()
                    // Suggest switching to preview but don't force it
                    NotificationCenter.default.post(name: .suggestPreviewTab, object: nil)
                }
            }
        }
    }
} 

