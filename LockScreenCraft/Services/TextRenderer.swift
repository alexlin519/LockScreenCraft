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
        device: DeviceConfig
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        let renderer = UIGraphicsImageRenderer(
            size: device.resolution,
            format: format
        )
        
        return renderer.image { context in
            // Fill background with white
            UIColor.white.setFill()
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
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: optimizedFont,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle
            ]
            
            // Calculate text bounds
            let textSize = text.boundingRect(
                with: safeArea.size,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes,
                context: nil
            )
            
            // Center text in safe area
            let textX = safeArea.minX + (safeArea.width - textSize.width) / 2
            let textY = safeArea.minY + (safeArea.height - textSize.height) / 2
            
            text.draw(
                with: CGRect(x: textX, y: textY, width: textSize.width, height: textSize.height),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes,
                context: nil
            )
        }
    }
    
    private func calculateOptimalFont(
        for text: String,
        startingFont: UIFont,
        safeArea: CGRect
    ) -> UIFont {
        var currentSize = maximumFontSize
        var font = startingFont.withSize(currentSize)
        
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
            font = startingFont.withSize(currentSize)
        }
        
        return font
    }
} 