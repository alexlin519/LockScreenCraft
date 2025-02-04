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
            VStack(spacing: 0) {
                PreviewSection(
                    viewModel: viewModel,
                    isFullScreenPreview: $isFullScreenPreview,
                    thumbnailScale: $thumbnailScale
                )
                
                FutureSettingsSection()
                
                if viewModel.generatedImage != nil {
                    SaveButton(viewModel: viewModel)
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
                        .frame(width: geometry.size.width * 0.6)
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
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .overlay(DeviceFrameOverlay(device: device))
            }
        }
        .onTapGesture {
            withAnimation(.linear(duration: 0.25)) {
                isPresented = false
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

#Preview {
    WallpaperGeneratorView()
} 


