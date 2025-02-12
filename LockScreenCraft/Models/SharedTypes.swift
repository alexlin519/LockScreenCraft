import SwiftUI

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
public typealias PlatformEdgeInsets = UIEdgeInsets
public typealias PlatformFont = UIFont
public typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
public typealias PlatformFont = NSFont
public typealias PlatformColor = NSColor
public struct PlatformEdgeInsets {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat
    
    public init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }
}
#endif

public struct FontDisplayInfo: Hashable {
    public let fontName: String
    public let displayName: String
    
    public init(fontName: String, displayName: String) {
        self.fontName = fontName
        self.displayName = displayName
    }
} 