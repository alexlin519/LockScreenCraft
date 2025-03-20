#if DEBUG
import SwiftUI

struct TextFileListView: View {
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Available Text Files")
                    .font(.headline)
                    .padding(.horizontal)
                
                Divider()
                
                if viewModel.availableTextFiles.isEmpty {
                    Text("No text files available")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(0..<viewModel.availableTextFiles.count, id: \.self) { index in
                        Button(action: {
                            Task {
                                await viewModel.selectFileAt(index: index)
                            }
                        }) {
                            HStack {
                                Text(viewModel.availableTextFiles[index])
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Text Files")
    }
}
#endif 