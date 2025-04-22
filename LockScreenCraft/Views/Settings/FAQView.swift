import SwiftUI

struct FAQView: View {
    @State private var expandedItems: Set<String> = []
    
    var body: some View {
        List {
            ForEach(faqItems, id: \.question) { item in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedItems.contains(item.question) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedItems.insert(item.question)
                            } else {
                                expandedItems.remove(item.question)
                            }
                        }
                    )
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(item.answer.localized)
                            .padding(.vertical, 8)
                        
                        if let helpImage = item.helpImage {
                            Image(helpImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(8)
                                .padding(.vertical, 4)
                        }
                    }
                    .padding(.vertical, 8)
                } label: {
                    Text(item.question.localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .navigationTitle("Frequently Asked Questions".localized)
        .listStyle(InsetGroupedListStyle())
    }
    
    // Sample FAQ items
    private var faqItems: [FAQItem] = [
        FAQItem(
            question: "How do I save my wallpaper?",
            answer: "After creating your wallpaper, go to the Preview tab and tap the Save button in the top right corner. The wallpaper will be saved to your Photos app."
        ),
        FAQItem(
            question: "Can I use my own background images?",
            answer: "Yes! Go to the Preview tab, select the Background section, then choose 'Upload' to select an image from your photo library."
        ),
        FAQItem(
            question: "How do I change the font?",
            answer: "In the Preview tab, select the Text section. You'll find a font picker at the top where you can choose from various fonts."
        ),
        FAQItem(
            question: "Can I process multiple text files at once?",
            answer: "Yes. In the Generate tab, tap 'Process Text Files' and select multiple text files. You can then navigate between them in the Preview tab."
        ),
        FAQItem(
            question: "How do I adjust the background?",
            answer: "Go to the Adjust tab and tap on the preview. You can then zoom and pan the background image to position it exactly as you want."
        ),
        FAQItem(
            question: "Why is my text hard to read on certain backgrounds?",
            answer: "Try changing the text color or using a different background with better contrast. You can also try adding a drop shadow or gradient to improve visibility."
        ),
        FAQItem(
            question: "How do I create line breaks in my text?",
            answer: "You can use '\\' or '//' characters in your text to create line breaks."
        ),
        FAQItem(
            question: "Can I set this as my lock screen automatically?",
            answer: "Currently, you need to manually set the saved image as your lock screen through iOS Settings. This is an iOS limitation that we cannot bypass for security reasons."
        )
    ]
}

struct FAQItem {
    let question: String
    let answer: String
    let helpImage: String? // Optional image name for visual guidance
    
    init(question: String, answer: String, helpImage: String? = nil) {
        self.question = question
        self.answer = answer
        self.helpImage = helpImage
    }
}

#Preview {
    NavigationView {
        FAQView()
    }
} 