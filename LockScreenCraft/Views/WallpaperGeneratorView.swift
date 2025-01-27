import SwiftUI

struct WallpaperGeneratorView: View {
    @StateObject private var viewModel = WallpaperGeneratorViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Text Input
                TextField("Enter your text (max 200 characters)", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(5)
                    .padding()
                
                // Device Selection
                Picker("Device", selection: $viewModel.selectedDevice) {
                    Text(viewModel.selectedDevice.modelName)
                        .tag(viewModel.selectedDevice)
                }
                .pickerStyle(.menu)
                .padding()
                
                // Preview
                if let image = viewModel.generatedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .cornerRadius(20)
                        .shadow(radius: 5)
                } else {
                    ContentUnavailableView("No Preview", systemImage: "photo")
                }
                
                // Action Buttons
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.generateWallpaper()
                    }) {
                        Label("Generate", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.inputText.isEmpty)
                    
                    if viewModel.generatedImage != nil {
                        Button(action: {
                            Task {
                                await viewModel.saveWallpaper()
                            }
                        }) {
                            Label("Save", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle("LockScreen Crafter")
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .overlay {
                if viewModel.isGenerating {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
        }
    }
} 