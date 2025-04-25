import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Generation Tab View
struct GenerationTabView: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    TextInputSection(inputText: $viewModel.inputText)
                    DeviceSelectionSection(viewModel: viewModel)
                    ActionButtonsSection(viewModel: viewModel, selectedTab: $selectedTab)
                }
                .padding(.vertical)
            }
            .navigationTitle("Generate".localized)
        }
        .id(LocalizationManager.shared.refreshID)
    }
}

// MARK: - Preview Tab View
struct PreviewTabView: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    @Binding var selectedTab: Int
    @Binding var isFullScreenPreview: Bool
    @Binding var thumbnailScale: CGFloat
    
    var body: some View {
        VStack {
            // If we have a generated image, show it
            // If not, show a placeholder instead of trying to generate one
            if viewModel.generatedImage != nil {
                PreviewSection(
                    viewModel: viewModel,
                    isFullScreenPreview: $isFullScreenPreview,
                    thumbnailScale: $thumbnailScale
                )
                .frame(maxHeight: UIScreen.main.bounds.height * 0.4)
                .onTapGesture {
                    isFullScreenPreview = true
                }
                
                TextControlPanel(viewModel: viewModel)
                    .padding(.horizontal)
            } else {
                // Show a helpful message when no image exists
                VStack(spacing: 25) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                        
                    Text("No Preview Available".localized)
                        .font(.title2)
                        .fontWeight(.medium)
                        
                    Text("Generate a wallpaper first by entering text in the Generate tab".localized)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        
                    Button("Go to Generate Tab".localized) {
                        selectedTab = 0
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Spacer(minLength: 0)
            
            // Emergency tab navigation
            HStack {
                Text("Tab Navigation")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Go to Generate") {
                    // Use NotificationCenter to tell the app to switch tabs
                    NotificationCenter.default.post(
                        name: .switchToTab,
                        object: 0 // Index of Generate tab
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Go to Settings") {
                    NotificationCenter.default.post(
                        name: .switchToTab,
                        object: 1 // Index of Settings tab
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .background(Color(.systemBackground))
        }
        .navigationTitle("Preview".localized)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if let currentFile = viewModel.currentProcessingFile {
                    Text("\(currentFile) (\(viewModel.currentFileIndex + 1)/\(viewModel.availableTextFiles.count))")
                        .foregroundStyle(.secondary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.generatedImage != nil {
                    HStack(spacing: 20) {
                        ParagraphNavigationControls(viewModel: viewModel)
                        SaveButton(viewModel: viewModel)
                    }
                }
            }
        }
        .sheet(isPresented: $isFullScreenPreview) {
            if let image = viewModel.generatedImage {
                FullScreenPreview(
                    image: image,
                    device: viewModel.selectedDevice,
                    isPresented: $isFullScreenPreview
                )
            }
        }
        .id(LocalizationManager.shared.refreshID)
    }
}

// MARK: - Adjust Tab View
struct AdjustTabView: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    @State private var isAdjusting = false
    
    var body: some View {
        NavigationView {
            VStack {
                if let image = viewModel.generatedImage {
                    Button(action: {
                        isAdjusting = true
                    }) {
                        VStack {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: UIScreen.main.bounds.height * 0.4)
                                .cornerRadius(20)
                                .shadow(radius: 5)
                                .overlay(DeviceFrameOverlay(device: viewModel.selectedDevice))
                            
                            Label("Tap to Adjust".localized, systemImage: "crop")
                                .font(.headline)
                                .padding(.top)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    ContentUnavailableView("Generate a wallpaper first".localized, systemImage: "photo")
                }
            }
            .padding()
            .navigationTitle("Adjust".localized)
            .fullScreenCover(isPresented: $isAdjusting) {
                AdjustmentView(viewModel: viewModel, isPresented: $isAdjusting)
            }
        }
        .id(LocalizationManager.shared.refreshID)
    }
}

// MARK: - Adjustment View
struct AdjustmentView: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    @ObservedObject private var compositionManager = WallpaperCompositionManager.shared
    @Binding var isPresented: Bool
    
    // Gesture State
    @State private var scale: CGFloat = 1.0
    @State private var offset = CGSize.zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset = CGSize.zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                if let image = viewModel.generatedImage {
                    // Calculate scale factor to match device resolution
                    let screenScale = UIScreen.main.scale
                    let deviceWidth = viewModel.selectedDevice.resolution.width / screenScale
                    let deviceHeight = viewModel.selectedDevice.resolution.height / screenScale
                    let screenWidth = geometry.size.width
                    let screenHeight = geometry.size.height
                    
                    // Calculate scaling to fit screen while maintaining aspect ratio
                    let widthRatio = screenWidth / deviceWidth
                    let heightRatio = screenHeight / deviceHeight
                    let scale = min(widthRatio, heightRatio)
                    
                    // Device frame with background image
                    ZStack {
                        // Background image (if it exists)
                        if case .image(let bgImage) = compositionManager.backgroundType {
                            Image(uiImage: bgImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .scaleEffect(self.scale)
                                .offset(x: offset.width, y: offset.height)
                        }
                        
                        // Wallpaper preview
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .frame(
                        width: deviceWidth * scale,
                        height: deviceHeight * scale
                    )
                    .overlay(
                        DeviceFrameOverlay(device: viewModel.selectedDevice)
                            .opacity(0.3)
                    )
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    self.scale = lastScale * value
                                }
                                .onEnded { value in
                                    lastScale = self.scale
                                    updateTransform()
                                },
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { value in
                                    lastOffset = offset
                                    updateTransform()
                                }
                        )
                    )
                }
                
                // Toolbar overlay
                VStack {
                    // Add spacer to push buttons down below status bar
                    Spacer().frame(height: 55)
                    
                    HStack {
                        Button(action: {
                            resetTransform()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.headline)
                                .padding(8)
                                .background(Circle().fill(Color.black.opacity(0.4)))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            isPresented = false
                        }) {
                            Text("Done".localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.black.opacity(0.4)))
                        }
                    }
                    .padding()
                    .foregroundColor(.white)
                    
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private func updateTransform() {
        let transform = Transform(scale: scale, offset: offset)
        compositionManager.applyTransform(transform)
        Task {
            await viewModel.generateWallpaper()
        }
    }
    
    private func resetTransform() {
        scale = 1.0
        offset = .zero
        lastScale = 1.0
        lastOffset = .zero
        compositionManager.resetTransform()
        Task {
            await viewModel.generateWallpaper()
        }
    }
}

// MARK: - Main View
struct WallpaperGeneratorView: View {
    @StateObject private var viewModel = WallpaperGeneratorViewModel()
    @State private var selectedTab = 0
    @State private var isFullScreenPreview = false
    @State private var thumbnailScale: CGFloat = 1.0
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        // THIS IS THE CRITICAL PART - Use a ZStack to ensure the TabView is always accessible
        ZStack(alignment: .bottom) {
            // Inner tab content
            Group {
                if selectedTab == 0 {
                    // GENERATE TAB
                    NavigationView {
                        ScrollView {
                            VStack(spacing: 24) {
                                TextInputSection(inputText: $viewModel.inputText)
                                DeviceSelectionSection(viewModel: viewModel)
                                ActionButtonsSection(viewModel: viewModel, selectedTab: $selectedTab)
                            }
                            .padding(.vertical)
                        }
                        .navigationTitle("Generate".localized)
                    }
                } else if selectedTab == 1 {
                    // PREVIEW TAB
                    NavigationView {
                        VStack {
                            if viewModel.generatedImage != nil {
                                PreviewSection(
                                    viewModel: viewModel,
                                    isFullScreenPreview: $isFullScreenPreview,
                                    thumbnailScale: $thumbnailScale
                                )
                                .frame(maxHeight: UIScreen.main.bounds.height * 0.4)
                                .onTapGesture {
                                    isFullScreenPreview = true
                                }
                                
                                TextControlPanel(viewModel: viewModel)
                                    .padding(.horizontal)
                            } else {
                                // Show a helpful message when no image exists
                                VStack(spacing: 25) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 60))
                                        .foregroundColor(.secondary)
                                        
                                    Text("No Preview Available".localized)
                                        .font(.title2)
                                        .fontWeight(.medium)
                                        
                                    Text("Generate a wallpaper first by entering text in the Generate tab".localized)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.secondary)
                                        
                                    Button("Go to Generate Tab".localized) {
                                        selectedTab = 0
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .padding(.top)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            
                            Spacer(minLength: 100) // Important: Add extra space at bottom
                        }
                        .navigationTitle("Preview".localized)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                if let currentFile = viewModel.currentProcessingFile {
                                    Text("\(currentFile) (\(viewModel.currentFileIndex + 1)/\(viewModel.availableTextFiles.count))")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            ToolbarItem(placement: .navigationBarTrailing) {
                                if viewModel.generatedImage != nil {
                                    HStack(spacing: 20) {
                                        ParagraphNavigationControls(viewModel: viewModel)
                                        SaveButton(viewModel: viewModel)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // ADJUST TAB - Whatever this contains
                    AdjustTabView(viewModel: viewModel)
                }
            }
            .padding(.bottom, 50) // Add padding to prevent content from covering the tab bar
            
            // Custom tab bar - THIS IS CRITICAL - it's always on top and accessible
            HStack(spacing: 0) {
                ForEach(0..<3) { index in
                    Button(action: {
                        selectedTab = index
                    }) {
                        VStack {
                            Image(systemName: getTabIcon(index))
                                .imageScale(.large)
                            Text(getTabTitle(index))
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundColor(selectedTab == index ? .blue : .gray)
                    }
                }
            }
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .top
            )
        }
        .sheet(isPresented: $isFullScreenPreview) {
            if let image = viewModel.generatedImage {
                FullScreenPreview(
                    image: image,
                    device: viewModel.selectedDevice,
                    isPresented: $isFullScreenPreview
                )
            }
        }
        .sheet(isPresented: $viewModel.showingFilePicker) {
            DocumentPicker(
                allowedContentTypes: [.plainText],
                onPick: { urls in
                    Task {
                        await viewModel.processSelectedFiles(urls)
                        selectedTab = 1 // Switch to preview tab
                    }
                }
            )
        }
        .sheet(isPresented: $viewModel.showingTextSplitterSheet) {
            TextSplitterView(textToProcess: $viewModel.inputText)
        }
        .sheet(isPresented: $viewModel.showingParagraphBrowser) {
            ParagraphBrowserView(
                paragraphs: viewModel.splitParagraphs,
                selectedText: $viewModel.inputText
            )
        }
    }
    
    // Helper functions for tab bar
    private func getTabIcon(_ index: Int) -> String {
        switch index {
        case 0: return "pencil"
        case 1: return "eye"
        case 2: return "slider.horizontal.3"
        default: return "questionmark"
        }
    }
    
    private func getTabTitle(_ index: Int) -> String {
        switch index {
        case 0: return "Generate".localized
        case 1: return "Preview".localized
        case 2: return "Adjust".localized
        default: return ""
        }
    }
}

// MARK: - Supporting Views
struct TextInputSection: View {
    @Binding var inputText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enter Text".localized)
                .font(.headline)
            
            TextEditor(text: $inputText)
                .textFieldStyle(.roundedBorder)
                .frame(height: 200)
                .lineLimit(5...)
                .textInputAutocapitalization(.none)
                .autocorrectionDisabled()
                .textContentType(.none)
                .keyboardShortcut("v", modifiers: .command)
            
            Text("Tip: Use \\ or // or \\\\ to create line breaks".localized)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Add a paste button
            Button("Paste".localized) {
                if let string = UIPasteboard.general.string {
                    inputText = string
                }
            }
        }
        .padding(.horizontal)
    }
}

struct DeviceSelectionSection: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("Select Device".localized)
                .font(.headline)
            
            Picker("Device".localized, selection: $viewModel.selectedDevice) {
                ForEach(viewModel.availableDevices, id: \.self) { device in
                    Text(device.modelName)
                        .tag(device)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(.horizontal)
    }
}

struct ActionButtonsSection: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Generate Wallpaper button
            Button {
                Task {
                    await viewModel.generateWallpaper()
                    selectedTab = 1 // Switch to preview
                }
            } label: {
                Label("Generate Wallpaper".localized, systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isGenerating)
            
            // Process Text Files button
            Button {
                Task {
                    await viewModel.startProcessingAllFiles()
                }
            } label: {
                Label("Process Text Files".localized, systemImage: "doc.text.magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            // Import from TXT button
            Button {
                Task {
                    viewModel.showingFilePicker = true
                }
            } label: {
                Label("Import from TXT".localized, systemImage: "doc.text")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal)
            
            // Split Paragraphs button
            Button(action: {
                viewModel.showingTextSplitterSheet = true
            }) {
                Label("Split Paragraphs", systemImage: "doc.plaintext")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            // Browse All Paragraphs button
            if !viewModel.splitParagraphs.isEmpty {
                Button(action: {
                    viewModel.browseAllParagraphs()
                }) {
                    Label("Browse All Paragraphs (\(viewModel.splitParagraphs.count))", systemImage: "list.bullet")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $viewModel.showingFilePicker) {
            DocumentPicker(
                allowedContentTypes: [.plainText],
                onPick: { urls in
                    Task {
                        await viewModel.processSelectedFiles(urls)
                        selectedTab = 1 // Switch to preview tab
                    }
                }
            )
        }
        .sheet(isPresented: $viewModel.showingTextSplitterSheet) {
            TextSplitterView(textToProcess: $viewModel.inputText)
        }
        .sheet(isPresented: $viewModel.showingParagraphBrowser) {
            ParagraphBrowserView(
                paragraphs: viewModel.splitParagraphs,
                selectedText: $viewModel.inputText
            )
        }
    }
}

struct PreviewSection: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    @ObservedObject private var compositionManager = WallpaperCompositionManager.shared
    @Binding var isFullScreenPreview: Bool
    @Binding var thumbnailScale: CGFloat
    
    var body: some View {
        VStack(spacing: 16) {
        if let image = viewModel.generatedImage {
            GeometryReader { geometry in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 400)
                        .cornerRadius(20)
                        .shadow(radius: 5)
                        .overlay(DeviceFrameOverlay(device: viewModel.selectedDevice))
                        .clipped()
                        .scaleEffect(thumbnailScale)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                thumbnailScale = 1.02
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.spring(response: 0.3)) {
                                        thumbnailScale = 1.0
                                    }
                                }
                                isFullScreenPreview = true
                            }
                        }
            }
            .frame(height: 400)
        } else {
            ContentUnavailableView("No Preview".localized, systemImage: "photo")
            }
        }
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ProgressView()
            .scaleEffect(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.ultraThinMaterial)
    }
}

struct FullScreenPreview: View {
    let image: UIImage?
    let device: DeviceConfig
    @Binding var isPresented: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                if let image = image {
                    // Calculate scale factor to match device resolution
                    let screenScale = UIScreen.main.scale
                    let deviceWidth = device.resolution.width / screenScale
                    let deviceHeight = device.resolution.height / screenScale
                    let screenWidth = geometry.size.width
                    let screenHeight = geometry.size.height
                    
                    // Calculate scaling to fit screen while maintaining aspect ratio
                    let widthRatio = screenWidth / deviceWidth
                    let heightRatio = screenHeight / deviceHeight
                    let scale = min(widthRatio, heightRatio)
                    
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            width: deviceWidth * scale,
                            height: deviceHeight * scale
                        )
                        .overlay(
                            DeviceFrameOverlay(device: device)
                                .opacity(0.3)
                        )
                }
            }
            .onTapGesture {
                withAnimation(.linear(duration: 0.25)) {
                    isPresented = false
                }
            }
        }
    }
}

struct DeviceFrameOverlay: View {
    let device: DeviceConfig
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let cornerRadius: CGFloat = 40
            
            Path { path in
                // Device outline with rounded corners
                let rect = CGRect(x: 0, y: 0, width: width, height: height)
                let cornerSize = CGSize(width: cornerRadius, height: cornerRadius)
                path.addRoundedRect(in: rect, cornerSize: cornerSize)
                
                // Notch
                let notchWidth = width * 0.5
                let notchHeight = height * 0.03
                let notchX = (width - notchWidth) / 2
                path.addRect(CGRect(x: notchX, y: 0, width: notchWidth, height: notchHeight))
            }
            .stroke(Color.white, lineWidth: 2)
        }
    }
}

// MARK: - Color Picker Views
struct ColorPickerButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 25, height: 15)
                .overlay(
                    Circle()
                        .stroke(isSelected ? .blue : .gray, lineWidth: 1.5)
                )
        }
    }
}

struct CompactColorPicker: View {
    @Binding var selection: Color
    
    var body: some View {
        ColorPicker("", selection: $selection)
            .labelsHidden()
            .scaleEffect(0.8)
            .frame(height: 25)
            .presentationCompactAdaptation(.popover)
    }
}

// MARK: - Text Control Panel
struct TextControlPanel: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    @State private var selectedSection = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Section Picker with localized text 
            Picker("Settings Section".localized, selection: $selectedSection) {
                Text("Text".localized).tag(0)
                Text("Background".localized).tag(1)
                Text("Templates".localized).tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Content based on selection
            switch selectedSection {
            case 0:
                TextStyleSection(viewModel: viewModel)
            case 1:
                BackgroundSettingsSection(viewModel: viewModel)
            case 2:
                TemplatesSection()
            default:
                EmptyView()
            }
        }
    }
}

struct TextStyleSection: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Font Picker and Size Controls in one row
            HStack(spacing: 12) {
                // Font Picker
                if !viewModel.availableFonts.isEmpty {
                    Picker("Font".localized, selection: $viewModel.selectedFont) {
                        ForEach(viewModel.availableFonts, id: \.fontName) { font in
                            Text(font.displayName)
                                .tag(font)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Add Randomize button here
                Button(action: {
                    viewModel.randomizeAll()
                    Task {
                        await viewModel.generateWallpaper()
                    }
                }) {
                    Label("", systemImage: "dice.fill")
                        .font(.footnote)
                }
                .buttonStyle(.bordered)
                
                // Font Size Controls
                HStack {
                    Button(action: { viewModel.decreaseFontSize() }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                    }
                    
                    TextField("", text: Binding(
                        get: { viewModel.fontSizeText },
                        set: { viewModel.updateFontSizeText($0) }
                    ))
                        .multilineTextAlignment(.center)
                        .frame(width: 50)
                        
                    Button(action: { viewModel.increaseFontSize() }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            
            // Spacing Controls
            VStack(spacing: 12) {
                // Line Spacing
                HStack {
                    Text("Line Space".localized)
                    Slider(value: $viewModel.lineSpacing, in: -200...200, step: 1)
                        .frame(maxWidth: .infinity)
                    
                    // Add number input with +/- buttons
                    HStack {
                        Button(action: { viewModel.lineSpacing -= 1 }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                        }
                        
                        Text("\(Int(viewModel.lineSpacing))")
                            .frame(width: 40)
                            .monospacedDigit()
                        
                        Button(action: { viewModel.lineSpacing += 1 }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                }
                
                // Word Spacing
                HStack {
                    Text("Word Space".localized)
                    Slider(value: $viewModel.wordSpacing, in: -100...100, step: 1)
                        .frame(maxWidth: .infinity)
                    
                    // Add number input with +/- buttons
                    HStack {
                        Button(action: { viewModel.wordSpacing -= 1 }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                        }
                        
                        Text("\(Int(viewModel.wordSpacing))")
                            .frame(width: 40)
                            .monospacedDigit()
                        
                        Button(action: { viewModel.wordSpacing += 1 }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                }
            }
            
            // Color Selection
            VStack(alignment: .leading, spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        // Native Color Picker with compact presentation
                        CompactColorPicker(selection: $viewModel.selectedColor)
                        
                        // Preset colors
                        ForEach(viewModel.savedColors, id: \.self) { color in
                            ColorPickerButton(
                                color: color,
                                isSelected: color == viewModel.selectedColor
                            ) {
                                viewModel.selectedColor = color
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
                
            // Text Alignment Controls
            HStack {
                ForEach([NSTextAlignment.left, .center, .right], id: \.self) { alignment in
                    Button(action: { viewModel.setTextAlignment(alignment) }) {
                        Image(systemName: alignmentIcon(for: alignment))
                            .foregroundColor(viewModel.textAlignment == alignment ? .accentColor : .primary)
                    }
                }
            }
        }
    }
    
    private func alignmentIcon(for alignment: NSTextAlignment) -> String {
        switch alignment {
        case .left: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .right: return "text.alignright"
        default: return "text.alignleft"
        }
    }
}

struct BackgroundSettingsSection: View {
    @StateObject private var compositionManager = WallpaperCompositionManager.shared
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    @State private var selectedBackgroundType = 0
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Background Type Selector with localized text
            Picker("Background Type".localized, selection: $selectedBackgroundType) {
                Text("Gallery".localized).tag(0)
                Text("Solid".localized).tag(1)
                Text("Gradient".localized).tag(2)
                Text("Frosted".localized).tag(3)
                Text("Upload".localized).tag(4)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Background Content
            ScrollView {
                switch selectedBackgroundType {
                case 0:
                    GalleryBackgroundView(viewModel: viewModel)
                case 1:
                    SolidColorBackgroundView(viewModel: viewModel)
                case 2:
                    GradientBackgroundView(viewModel: viewModel)
                case 3:
                    FrostedBackgroundView(viewModel: viewModel)
                case 4:
                    UploadBackgroundView(viewModel: viewModel)
                default:
                    EmptyView()
                }
            }
        }
    }
}

// MARK: - Gallery Background View
struct GalleryBackgroundView: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    @ObservedObject private var compositionManager = WallpaperCompositionManager.shared
    @State private var loadedImages: [String: UIImage] = [:]
    @State private var isLoading = true
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(compositionManager.availableBackgrounds, id: \.self) { filename in
                        Button(action: {
                            compositionManager.selectBackground(named: filename)
                            Task {
                                await viewModel.generateWallpaper()
                            }
                        }) {
                            if let image = loadedImages[filename] {
                                // Show loaded image
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            } else {
                                // Placeholder while loading
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
        .onAppear {
            loadThumbnails()
        }
    }
    
    private func loadThumbnails() {
        isLoading = true
        
        // Load thumbnails progressively to improve performance
        Task {
            for filename in compositionManager.availableBackgrounds {
                if loadedImages[filename] == nil, 
                   let image = compositionManager.loadBackgroundImage(named: filename) {
                    // Generate smaller thumbnail for faster loading
                    let thumbnail = await generateThumbnail(from: image)
                    
                    await MainActor.run {
                        loadedImages[filename] = thumbnail
                    }
                    
                    // Add a small delay to prevent UI freezing
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms delay
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func generateThumbnail(from image: UIImage) async -> UIImage {
        // Create thumbnail on background thread
        let size = CGSize(width: 200, height: 200)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Solid Color Background View
struct SolidColorBackgroundView: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    @ObservedObject private var compositionManager = WallpaperCompositionManager.shared
    @State private var selectedColor: Color = .white
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private let presetColors: [Color] = [
        .white, .black, .gray,
        .red, .orange, .yellow,
        .green, .blue, .purple,
        .pink, .indigo, .mint
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Color Preview
            RoundedRectangle(cornerRadius: 12)
                .fill(selectedColor)
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            // Preset Colors Grid
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(presetColors, id: \.self) { color in
                    ColorButton(color: color, isSelected: selectedColor == color) {
                        selectedColor = color
                        compositionManager.backgroundType = .solidColor(color)
                        Task {
                            await viewModel.generateWallpaper()
                        }
                    }
                }
            }
            
            // Custom Color Picker
            ColorPicker("Custom Color".localized, selection: $selectedColor)
                .onChange(of: selectedColor) { _, newColor in
                    compositionManager.backgroundType = .solidColor(newColor)
                    Task {
                        await viewModel.generateWallpaper()
                    }
                }
        }
        .padding(.horizontal)
    }
}

struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(isSelected ? .blue : .gray.opacity(0.3), lineWidth: 2)
                )
        }
    }
}

// MARK: - Gradient Background View
struct GradientBackgroundView: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    @ObservedObject private var compositionManager = WallpaperCompositionManager.shared
    @State private var startColor: Color = .blue
    @State private var endColor: Color = .purple
    @State private var isRadial: Bool = false
    @State private var angle: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Preview
            ZStack {
                if isRadial {
                    RadialGradient(colors: [startColor, endColor],
                                 center: .center,
                                 startRadius: 0,
                                 endRadius: 200)
                } else {
                    LinearGradient(colors: [startColor, endColor],
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .frame(height: 100)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            
            // Controls
            VStack(alignment: .leading, spacing: 12) {
                // Gradient Type
                Toggle("Radial Gradient".localized, isOn: $isRadial)
                
                // Start Color
                ColorPicker("Start Color".localized, selection: $startColor)
                
                // End Color
                ColorPicker("End Color".localized, selection: $endColor)
                
                // Angle (for linear gradient)
                if !isRadial {
                    VStack(alignment: .leading) {
                        Text(String(format: "Angle: %d°".localized, Int(angle)))
                        
                        Slider(value: $angle, in: 0...360)
                    }
                }
            }
            .onChange(of: startColor) { _, _ in updateGradient() }
            .onChange(of: endColor) { _, _ in updateGradient() }
            .onChange(of: isRadial) { _, _ in updateGradient() }
            .onChange(of: angle) { _, _ in updateGradient() }
        }
        .padding(.horizontal)
    }
    
    private func updateGradient() {
        let direction: GradientDirection = isRadial ? .radial : .linear(angle: angle)
        let config = GradientConfig(startColor: startColor, endColor: endColor, direction: direction)
        compositionManager.backgroundType = .gradient(config)
        Task {
            await viewModel.generateWallpaper()
        }
    }
}

// MARK: - Frosted Background View
struct FrostedBackgroundView: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    @ObservedObject private var compositionManager = WallpaperCompositionManager.shared
    @State private var baseColor: Color = .white
    @State private var intensity: Double = 0.5
    @State private var opacity: Double = 0.8
    
    var body: some View {
        VStack(spacing: 16) {
            // Preview
            RoundedRectangle(cornerRadius: 12)
                .fill(baseColor.opacity(opacity))
                .frame(height: 100)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            // Controls
            VStack(alignment: .leading, spacing: 12) {
                // Base Color
                ColorPicker("Base Color".localized, selection: $baseColor)
                
                // Intensity
                VStack(alignment: .leading) {
                    Text(String(format: "Blur Intensity: %d%%".localized, Int(intensity * 100)))
                    Slider(value: $intensity)
                }
                
                // Opacity
                VStack(alignment: .leading) {
                    Text(String(format: "Opacity: %d%%".localized, Int(opacity * 100)))
                    Slider(value: $opacity)
                }
            }
            .onChange(of: baseColor) { _, _ in updateFrosted() }
            .onChange(of: intensity) { _, _ in updateFrosted() }
            .onChange(of: opacity) { _, _ in updateFrosted() }
        }
        .padding(.horizontal)
    }
    
    private func updateFrosted() {
        let config = FrostedConfig(baseColor: baseColor, intensity: intensity, opacity: opacity)
        compositionManager.backgroundType = .frosted(config)
        Task {
            await viewModel.generateWallpaper()
        }
    }
}

// MARK: - Upload Background View
struct UploadBackgroundView: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    @ObservedObject private var compositionManager = WallpaperCompositionManager.shared
    @State private var isShowingImagePicker = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Upload Button
            Button(action: {
                isShowingImagePicker = true
            }) {
                VStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.largeTitle)
                    Text("Upload Image".localized)
                } 
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Uploaded Images Grid (similar to Gallery)
            if !compositionManager.userUploadedBackgrounds.isEmpty {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(compositionManager.userUploadedBackgrounds, id: \.self) { image in
                        Button(action: {
                            compositionManager.selectUploadedBackground(image)
                            Task {
                                await viewModel.generateWallpaper()
                            }
                        }) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(selectedImage: { image in
                compositionManager.addUploadedBackground(image)
                compositionManager.selectUploadedBackground(image)
                Task {
                    await viewModel.generateWallpaper()
                }
            })
        }
    }
}

struct TemplatesSection: View {
    var body: some View {
        VStack(spacing: 16) {
            ContentUnavailableView {
                Label("Coming Soon".localized, systemImage: "square.grid.2x2.fill")
            } description: {
                Text("Template and layout options will be available in a future update".localized)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    WallpaperGeneratorView()
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

struct ParagraphNavigationControls: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    
    var body: some View {
        if !viewModel.splitParagraphs.isEmpty {
            HStack(spacing: 8) {
                Button(action: {
                    navigateToPrevious()
                }) {
                    Image(systemName: "arrow.left")
                }
                .disabled(!viewModel.hasPreviousParagraph())

                Text("\(viewModel.currentParagraphIndex() ?? 0 + 1)/\(viewModel.splitParagraphs.count)")
                    .font(.caption)
                    .frame(minWidth: 40)
                
                Button(action: {
                    navigateToNext()
                }) {
                    Image(systemName: "arrow.right")
                }
                .disabled(!viewModel.hasNextParagraph())
            }
            .padding(6)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func navigateToPrevious() {
        guard let currentText = viewModel.splitParagraphs.firstIndex(of: viewModel.inputText),
              currentText > 0 else { return }
        
        viewModel.inputText = viewModel.splitParagraphs[currentText - 1]
        Task {
            await viewModel.generateWallpaper()
        }
    }
    
    private func navigateToNext() {
        guard let currentText = viewModel.splitParagraphs.firstIndex(of: viewModel.inputText),
              currentText < viewModel.splitParagraphs.count - 1 else { return }
        
        viewModel.inputText = viewModel.splitParagraphs[currentText + 1]
        Task {
            await viewModel.generateWallpaper()
        }
    }
}

struct SaveButton: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    
    var body: some View {
        Button(action: {
            saveAndAdvance()
        }) {
            if !viewModel.availableTextFiles.isEmpty || viewModel.hasNextParagraph() {
                Label("Save & Next".localized, systemImage: "arrow.right.circle.fill")
            } else {
                Label("Save".localized, systemImage: "square.and.arrow.down")
            }
        }
        .keyboardShortcut("s", modifiers: .command)
    }
    
    private func saveAndAdvance() {
        Task {
            await viewModel.saveToPhotos()
            
            // If we have split paragraphs, try to move to the next one
            if !viewModel.splitParagraphs.isEmpty {
                if viewModel.hasNextParagraph() {
                    // Move to next paragraph
                    if let currentIndex = viewModel.currentParagraphIndex(),
                       currentIndex < viewModel.splitParagraphs.count - 1 {
                        viewModel.inputText = viewModel.splitParagraphs[currentIndex + 1]
                        Task {
                            await viewModel.generateWallpaper()
                        }
                    }
                }
            } else if !viewModel.availableTextFiles.isEmpty {
                // Handle text files as before
                let nextIndex = viewModel.currentFileIndex + 1
                if nextIndex < viewModel.availableTextFiles.count {
                    await viewModel.selectFileAt(index: nextIndex)
                } else {
                    viewModel.currentProcessingFile = nil
                }
            }
        }
    }
}

