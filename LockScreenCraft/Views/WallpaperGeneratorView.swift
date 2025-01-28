import SwiftUI

struct WallpaperGeneratorView: View {
    @StateObject private var viewModel = WallpaperGeneratorViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Text Input
                TextField("输入文字(最多200字)", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { /* Empty to capture return key */ }  
                    .lineLimit(5...) //  Changed to dynamic line limit using ...
                    .textInputAutocapitalization(.none) 
                    .autocorrectionDisabled() 
                    .textContentType(.none) // Added for Chinese input
                    .submitLabel(.return) // Added return key type
                    .padding()

                 Text("Tip: Use \\ or // or \\\\ to create line breaks in image")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                // Device Selection
                Picker("Device", selection: $viewModel.selectedDevice) {
                    ForEach(viewModel.availableDevices, id: \.self) { device in
                        Text(device.modelName)
                            .tag(device)
                    }
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

#Preview {
    WallpaperGeneratorView()
} 

