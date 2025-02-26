import SwiftUI

struct TextFileListView: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.availableTextFiles, id: \.self) { filename in
                HStack {
                    Text(filename)
                    Spacer()
                    // Show last used settings
                    if let settings = viewModel.getFileSettings(filename) {
                        Text(settings.fontName)
                            .foregroundColor(.gray)
                    }
                }
                .onTapGesture {
                    // Load text and its saved settings
                    Task {
                        await viewModel.loadTextAndSettings(filename)
                    }
                }
            }
        }
    }
} 