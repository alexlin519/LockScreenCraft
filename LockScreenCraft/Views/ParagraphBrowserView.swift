import SwiftUI

struct ParagraphBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var paragraphs: [String]
    @State private var currentIndex = 0
    @Binding var selectedText: String
    
    init(paragraphs: [String], selectedText: Binding<String>) {
        self._paragraphs = State(initialValue: paragraphs)
        self._selectedText = selectedText
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Paragraph \(currentIndex + 1) of \(paragraphs.count)")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding(.horizontal)
            
            // Text preview
            ScrollView {
                Text(paragraphs[currentIndex])
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            
            // Navigation
            HStack {
                Button(action: {
                    if currentIndex > 0 {
                        currentIndex -= 1
                    }
                }) {
                    Image(systemName: "arrow.left")
                    Text("Previous")
                }
                .disabled(currentIndex == 0)
                
                Spacer()
                
                Button(action: {
                    selectedText = paragraphs[currentIndex]
                    dismiss()
                }) {
                    Text("Use This Paragraph")
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button(action: {
                    if currentIndex < paragraphs.count - 1 {
                        currentIndex += 1
                    }
                }) {
                    Text("Next")
                    Image(systemName: "arrow.right")
                }
                .disabled(currentIndex == paragraphs.count - 1)
            }
            .padding()
        }
        .padding(.vertical)
    }
} 