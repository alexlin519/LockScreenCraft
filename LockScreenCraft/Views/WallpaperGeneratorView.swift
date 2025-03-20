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
            .navigationTitle("Generate")
        }
    }
}

// MARK: - Preview Tab View
struct PreviewTabView: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    @Binding var selectedTab: Int
    @Binding var isFullScreenPreview: Bool
    @Binding var thumbnailScale: CGFloat
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
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
                            
                        Text("No Preview Available")
                            .font(.title2)
                            .fontWeight(.medium)
                            
                        Text("Generate a wallpaper first by entering text in the Generate tab")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            
                        Button("Go to Generate Tab") {
                            selectedTab = 0
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Spacer(minLength: 0)
            }
            .navigationTitle("Preview")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if let currentFile = viewModel.currentProcessingFile {
                        Text("\(currentFile) (\(viewModel.currentFileIndex + 1)/\(viewModel.availableTextFiles.count))")
                            .foregroundStyle(.secondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.generatedImage != nil {
                        Button(action: {
                            Task {
                                await viewModel.saveToPhotos()
                                
                                if !viewModel.availableTextFiles.isEmpty {
                                    let nextIndex = viewModel.currentFileIndex + 1
                                    if nextIndex < viewModel.availableTextFiles.count {
                                        await viewModel.selectFileAt(index: nextIndex)
                                    } else {
                                        viewModel.currentProcessingFile = nil
                                    }
                                }
                            }
                        }) {
                            if !viewModel.availableTextFiles.isEmpty {
                                Label("Save & Next", systemImage: "arrow.right.circle.fill")
                            } else {
                                Label("Save", systemImage: "square.and.arrow.down")
                            }
                        }
                        .keyboardShortcut("s", modifiers: .command)
                    }
                }
            }
            .fullScreenCover(isPresented: $isFullScreenPreview) {
                if let image = viewModel.generatedImage {
                    FullScreenPreview(
                        image: image,
                        device: viewModel.selectedDevice,
                        isPresented: $isFullScreenPreview
                    )
                }
            }
        }
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
                            
                            Label("Tap to Adjust", systemImage: "crop")
                                .font(.headline)
                                .padding(.top)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    ContentUnavailableView("Generate a wallpaper first", systemImage: "photo")
                }
            }
            .padding()
            .navigationTitle("Adjust")
            .fullScreenCover(isPresented: $isAdjusting) {
                AdjustmentView(viewModel: viewModel, isPresented: $isAdjusting)
            }
        }
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
                            Text("Done")
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
    
    var body: some View {
        print("📱 WallpaperGeneratorView body is rendering")
        
        return TabView(selection: $selectedTab) {
            GenerationTabView(viewModel: viewModel, selectedTab: $selectedTab)
                .tabItem {
                    Label("Generate", systemImage: "text.word.spacing")
                }
                .tag(0)
            
            PreviewTabView(
                viewModel: viewModel,
                selectedTab: $selectedTab,
                isFullScreenPreview: $isFullScreenPreview,
                thumbnailScale: $thumbnailScale
            )
            .tabItem {
                Label("Preview", systemImage: "photo")
            }
            .tag(1)
            
            AdjustTabView(viewModel: viewModel)
                .tabItem {
                    Label("Adjust", systemImage: "crop")
                }
                .tag(2)
        }
        .onAppear {
            print("🚀 WallpaperGeneratorView appeared")
        }
        .alert(viewModel.errorMessage?.starts(with: "Wallpaper saved") == true ? "Success" : "Error", 
               isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .overlay {
            if viewModel.isGenerating {
                LoadingOverlay()
            }
        }
    }
}

// MARK: - Supporting Views
struct TextInputSection: View {
    @Binding var inputText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enter Text")
                .font(.headline)
            
            TextEditor(text: $inputText)
                .textFieldStyle(.roundedBorder)
                .frame(height: 200)
                .lineLimit(5...)
                .textInputAutocapitalization(.none)
                .autocorrectionDisabled()
                .textContentType(.none)
                .keyboardShortcut("v", modifiers: .command)
            
            Text("Tip: Use \\ or // or \\\\ to create line breaks")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Add a paste button
            Button("Paste") {
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
            Text("Select Device")
                .font(.headline)
            
            Picker("Device", selection: $viewModel.selectedDevice) {
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
                Label("Generate Wallpaper", systemImage: "wand.and.stars")
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
                Label("Process Text Files", systemImage: "doc.text.magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            // Import from TXT button
            Button {
                Task {
                    viewModel.showingFilePicker = true
                }
            } label: {
                Label("Import from TXT", systemImage: "doc.text")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal)
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
            ContentUnavailableView("No Preview", systemImage: "photo")
            }
        }
    }
}

struct FutureSettingsSection: View {
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 4) {
                Label("Future Settings", systemImage: "gear")
                    .font(.headline)
                Text("• Font Selection")
                Text("• Text Size Adjustment")
                Text("• Background Options")
                Text("• Text Positioning")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .foregroundColor(.secondary)
        }
        .padding()
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
        .ignoresSafeArea()
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
            // Section Picker
            Picker("Settings Section", selection: $selectedSection) {
                Text("Text").tag(0)
                Text("Background").tag(1)
                Text("Templates").tag(2)
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
                    Picker("Font", selection: $viewModel.selectedFont) {
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
                    Text("Line Space")
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
                    Text("Word Space")
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
            // Background Type Selector
            Picker("Background Type", selection: $selectedBackgroundType) {
                Text("Gallery").tag(0)
                Text("Solid").tag(1)
                Text("Gradient").tag(2)
                Text("Frosted").tag(3)
                Text("Upload").tag(4)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Background Content
            ScrollView {
                switch selectedBackgroundType {
                case 0:
                    GalleryBackgroundView(viewModel: viewModel, isProcessing: $isProcessing)
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
    @Binding var isProcessing: Bool
    
    // Make grid more compact with 4 columns
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(compositionManager.availableBackgrounds, id: \.self) { filename in
                BackgroundThumbnailView(
                    filename: filename,
                    isProcessing: isProcessing,
                    onSelect: {
                        guard !isProcessing else { return }
                        isProcessing = true
                        compositionManager.selectBackground(named: filename)
                        Task {
                            await viewModel.generateWallpaper()
                            isProcessing = false
                        }
                    }
                )
                .frame(height: 80) // Smaller thumbnail size
            }
        }
        .padding(.horizontal, 8)
    }
}

// Separate view for thumbnail to improve performance
struct BackgroundThumbnailView: View {
    let filename: String
    let isProcessing: Bool
    let onSelect: () -> Void
    
    @State private var thumbnailImage: UIImage?
    
    private func loadThumbnail() async {
        // Update the path to match our project location
        let workspacePath = "/Users/alexlin/project_code/LockScreenCraft/LockScreenCraft/Resources/Background/\(filename)"
        guard let originalImage = UIImage(contentsOfFile: workspacePath) else { return }
        
        // Create thumbnail on background thread
        let thumbnail = await Task.detached(priority: .background) {
            return originalImage.preparingThumbnail(of: CGSize(width: 160, height: 160))
        }.value
        
        await MainActor.run {
            self.thumbnailImage = thumbnail
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            ZStack {
                if let image = thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                }
                
                if isProcessing {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                }
            }
        }
        .disabled(isProcessing)
        .task {
            await loadThumbnail()
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
            ColorPicker("Custom Color", selection: $selectedColor)
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
                Toggle("Radial Gradient", isOn: $isRadial)
                
                // Start Color
                ColorPicker("Start Color", selection: $startColor)
                
                // End Color
                ColorPicker("End Color", selection: $endColor)
                
                // Angle (for linear gradient)
                if !isRadial {
                    VStack(alignment: .leading) {
                        Text("Angle: \(Int(angle))°")
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
                ColorPicker("Base Color", selection: $baseColor)
                
                // Intensity
                VStack(alignment: .leading) {
                    Text("Blur Intensity: \(Int(intensity * 100))%")
                    Slider(value: $intensity)
                }
                
                // Opacity
                VStack(alignment: .leading) {
                    Text("Opacity: \(Int(opacity * 100))%")
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
                    Text("Upload Image")
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
                Label("Coming Soon", systemImage: "square.grid.2x2.fill")
            } description: {
                Text("Template and layout options will be available in a future update.")
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    WallpaperGeneratorView()
}

