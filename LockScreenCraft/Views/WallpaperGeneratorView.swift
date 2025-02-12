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
    @Binding var isFullScreenPreview: Bool
    @Binding var thumbnailScale: CGFloat
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                PreviewSection(
                    viewModel: viewModel,
                    isFullScreenPreview: $isFullScreenPreview,
                    thumbnailScale: $thumbnailScale
                )
                .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
                
                // Show text controls regardless of image presence
                TextControlPanel(viewModel: viewModel)
                    .padding(.horizontal)
                
                if viewModel.generatedImage != nil {
                    SaveButton(viewModel: viewModel)
                }
                
                Spacer(minLength: 0)
            }
            .navigationTitle("Preview")
            .fullScreenCover(isPresented: $isFullScreenPreview) {
                FullScreenPreview(
                    image: viewModel.generatedImage,
                    device: viewModel.selectedDevice,
                    isPresented: $isFullScreenPreview
                )
            }
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
        TabView(selection: $selectedTab) {
            GenerationTabView(viewModel: viewModel, selectedTab: $selectedTab)
                .tabItem {
                    Label("Generate", systemImage: "text.word.spacing")
                }
                .tag(0)
            
            PreviewTabView(
                viewModel: viewModel,
                isFullScreenPreview: $isFullScreenPreview,
                thumbnailScale: $thumbnailScale
            )
            .tabItem {
                Label("Preview", systemImage: "photo")
            }
            .tag(1)
        }
        .alert("Error", isPresented: $viewModel.showError) {
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
            
            TextField("输入文字(最多200字)", text: $inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .frame(height: 200)
                .lineLimit(5...) 
                .textInputAutocapitalization(.none)
                .autocorrectionDisabled()
                .textContentType(.none)
            
            Text("Tip: Use \\ or // or \\\\ to create line breaks")
                .font(.caption)
                .foregroundColor(.secondary)
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
            Button(action: {
                Task {
                    await viewModel.generateWallpaper()
                    selectedTab = 1
                }
            }) {
                Label("Generate Wallpaper", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            
            Button(action: {}) {
                Label("Import from TXT", systemImage: "doc.text")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(true)
        }
        .padding(.horizontal)
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

struct SaveButton: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    
    var body: some View {
        Button(action: {
            Task {
                await viewModel.saveWallpaper()
            }
        }) {
            Label("Save to Photos", systemImage: "square.and.arrow.down")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
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

// MARK: - Settings Sections
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
                
                Spacer()
                
                // Font Size Controls
                HStack {
                    Button(action: { viewModel.decreaseFontSize() }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                    }
                    
                    TextField("", text: Binding(
                        get: { String(Int(viewModel.fontSize)) },
                        set: { viewModel.setFontSizeFromString($0) }
                    ))
                        .multilineTextAlignment(.center)
                        .monospacedDigit()
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    
                    Button(action: { viewModel.increaseFontSize() }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
                .foregroundStyle(.primary)
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
        .padding(.horizontal)
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
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(compositionManager.availableBackgrounds, id: \.self) { filename in
                    Button(action: {
                        compositionManager.selectBackground(named: filename)
                        Task {
                            await viewModel.generateWallpaper()
                        }
                    }) {
                        let workspacePath = "/Users/alexlin/LockScreenCraft/LockScreenCraft/Resources/Background/\(filename)"
                        if let image = UIImage(contentsOfFile: workspacePath) {
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
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 100)
                                .overlay(
                                    Image(systemName: "photo.fill")
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding(.horizontal)
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

