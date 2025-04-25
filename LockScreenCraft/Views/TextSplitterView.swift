import SwiftUI

struct TextSplitterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var textToProcess: String
    @ObservedObject var viewModel: WallpaperGeneratorViewModel
    @State private var inputText = ""
    @State private var splitParagraphs: [String] = []
    @State private var selectedDelimiter: SplitDelimiter = .emptyLine
    @State private var customDelimiter = ""
    @State private var showPreview = false
    
    enum SplitDelimiter: String, CaseIterable, Identifiable {
        case emptyLine = "Empty Line"
        case doubleLineBreak = "Double Line Break"
        case customText = "Custom Text"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Paste Text to Split")) {
                    TextEditor(text: $inputText)
                        .frame(minHeight: 150)
                        .padding(4)
                    
                    Button("Paste from Clipboard") {
                        if let text = UIPasteboard.general.string {
                            inputText = text
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Section(header: Text("Split Method")) {
                    Picker("Split by", selection: $selectedDelimiter) {
                        ForEach(SplitDelimiter.allCases) { delimiter in
                            Text(delimiter.rawValue).tag(delimiter)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if selectedDelimiter == .customText {
                        TextField("Enter custom delimiter", text: $customDelimiter)
                    }
                    
                    Button("Preview Split") {
                        splitAndPreview()
                    }
                    .disabled(inputText.isEmpty)
                }
                
                if showPreview {
                    Section(header: Text("Preview (\(splitParagraphs.count) paragraphs)")) {
                        ForEach(0..<min(splitParagraphs.count, 3), id: \.self) { index in
                            Text(splitParagraphs[index])
                                .lineLimit(2)
                                .font(.footnote)
                        }
                        
                        if splitParagraphs.count > 3 {
                            Text("... and \(splitParagraphs.count - 3) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Split Paragraphs")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Use First Paragraph") {
                    viewModel.setSplitParagraphs(splitParagraphs)
                    viewModel.useFirstParagraph()
                    dismiss()
                }
                .disabled(splitParagraphs.isEmpty)
            )
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    if !splitParagraphs.isEmpty {
                        Text("Tip: After using a paragraph, return here to select another")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func splitAndPreview() {
        switch selectedDelimiter {
        case .emptyLine:
            splitParagraphs = inputText.components(separatedBy: "\n\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        case .doubleLineBreak:
            splitParagraphs = inputText.components(separatedBy: "\n\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        case .customText:
            if !customDelimiter.isEmpty {
                splitParagraphs = inputText.components(separatedBy: customDelimiter)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            } else {
                splitParagraphs = [inputText]
            }
        }
        
        showPreview = true
    }
} 