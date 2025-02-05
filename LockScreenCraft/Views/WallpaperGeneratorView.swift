import SwiftUI

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
            ScrollView {
                VStack(spacing: 20) {
                    PreviewSection(
                        viewModel: viewModel,
                        isFullScreenPreview: $isFullScreenPreview,
                        thumbnailScale: $thumbnailScale
                    )
                    
                    // Show text controls regardless of image presence
                    TextControlPanel(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    if viewModel.generatedImage != nil {
                        SaveButton(viewModel: viewModel)
                    }
                }
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
                viewModel.generateWallpaper()
                selectedTab = 1
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
    @Binding var isFullScreenPreview: Bool
    @Binding var thumbnailScale: CGFloat
    
    var body: some View {
        if let image = viewModel.generatedImage {
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width)
                        .frame(maxHeight: 400)
                        .cornerRadius(20)
                        .shadow(radius: 5)
                        .overlay(DeviceFrameOverlay(device: viewModel.selectedDevice))
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
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 400)
        } else {
            ContentUnavailableView("No Preview", systemImage: "photo")
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

// MARK: - Text Control Panel
private struct TextControlPanel: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    @State private var isShowingFontInfo = false
    @State private var editingFontSize: String = ""
    
    var body: some View {
        GroupBox {
            VStack(spacing: 16) {
                // Font Size Controls
                HStack {
                    Text("Font Size")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: { viewModel.decreaseFontSize() }) {
                        Image(systemName: "minus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    
                    TextField("Size", text: Binding(
                        get: { String(format: "%.1f", viewModel.fontSize) },
                        set: { newValue in
                            if let size = Double(newValue) {
                                viewModel.setFontSize(size)
                            }
                        }
                    ))
                    .frame(width: 60)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.roundedBorder)
                    
                    Button(action: { viewModel.increaseFontSize() }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    
                    Text("pt")
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Text Alignment Controls
                VStack(alignment: .leading, spacing: 8) {
                    Text("Alignment")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        ForEach([NSTextAlignment.left, .center, .right, .justified], id: \.self) { alignment in
                            Button(action: { viewModel.setTextAlignment(alignment) }) {
                                Image(systemName: alignmentIcon(for: alignment))
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.bordered)
                            .tint(viewModel.textAlignment == alignment ? .purple : .gray)
                        }
                    }
                }
                
                Divider()
                
                // Font Selection Controls
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Font")
                            .font(.headline)
                        
                        Spacer()
                        
                        if viewModel.isLoadingFonts {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    HStack {
                        // Category Picker
                        Picker("Category", selection: $viewModel.selectedFontCategory) {
                            ForEach(WallpaperGeneratorViewModel.FontCategory.allCases, id: \.self) { category in
                                Text(category.rawValue)
                                    .tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Spacer()
                        
                        // Font Picker
                        Picker("Font", selection: $viewModel.selectedFont) {
                            ForEach(viewModel.getFontsForCategory(viewModel.selectedFontCategory), id: \.self) { font in
                                HStack {
                                    Text(font)
                                    Button(action: { isShowingFontInfo = true }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .tag(font)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .padding(12)
        }
        .alert("Font Information", isPresented: $isShowingFontInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Font: \(viewModel.selectedFont)\nCopyright information will be displayed here.")
        }
    }
    
    private func alignmentIcon(for alignment: NSTextAlignment) -> String {
        switch alignment {
        case .left:
            return "text.alignleft"
        case .center:
            return "text.aligncenter"
        case .right:
            return "text.alignright"
        case .justified:
            return "text.justify"
        default:
            return "text.aligncenter"
        }
    }
}

#Preview {
    WallpaperGeneratorView()
}

