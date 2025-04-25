import UIKit

class TextRenderer {
    static let shared = TextRenderer()
    
    private let minimumFontSize: CGFloat = 12
    private let maximumFontSize: CGFloat = 120
    private let fontSizeStep: CGFloat = 1
    
    func renderText(
        _ text: String,
        font: UIFont,
        color: UIColor,
        device: DeviceConfig,
        alignment: NSTextAlignment = .center,
        lineSpacing: CGFloat = 0.0,
        wordSpacing: CGFloat = 0.0
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        let renderer = UIGraphicsImageRenderer(
            size: device.resolution,
            format: format
        )
        
        let renderedImage = renderer.image { context in
            // Use clear background instead of white
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: device.resolution))
            
            // Calculate optimal font size
            let safeArea = DeviceManager.shared.getSafeAreaRect(for: device)
            let optimizedFont = calculateOptimalFont(
                for: text,
                startingFont: font,
                safeArea: safeArea
            )
            
            // Setup text attributes
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = alignment
            paragraphStyle.lineSpacing = lineSpacing
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: optimizedFont,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle,
                .kern: wordSpacing // Add word spacing using kerning
            ]
            
            // Calculate text bounds
            let textSize = text.boundingRect(
                with: safeArea.size,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes,
                context: nil
            )
            
            // Position text based on alignment
            var textX: CGFloat
            switch alignment {
            case .left:
                textX = safeArea.minX
            case .center:
                textX = safeArea.minX + (safeArea.width - textSize.width) / 2
            case .right:
                textX = safeArea.maxX - textSize.width
            case .justified:
                textX = safeArea.minX
            default:
                textX = safeArea.minX + (safeArea.width - textSize.width) / 2
            }
            
            let textY = safeArea.minY + (safeArea.height - textSize.height) / 2
            
            text.draw(
                with: CGRect(x: textX, y: textY, width: textSize.width, height: textSize.height),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes,
                context: nil
            )
        }
        
        return renderedImage
    }
    
    private func calculateOptimalFont(
        for text: String,
        startingFont: UIFont,
        safeArea: CGRect
    ) -> UIFont {
        var currentSize = startingFont.pointSize
        var font = startingFont
        
        while currentSize > minimumFontSize {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font
            ]
            
            let textSize = text.boundingRect(
                with: safeArea.size,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes,
                context: nil
            )
            
            if textSize.width <= safeArea.width && textSize.height <= safeArea.height {
                break
            }
            
            currentSize -= fontSizeStep
            font = font.withSize(currentSize)
        }
        
        return font
    }
} 