import SwiftUI

struct DeviceConfig: Hashable {
    let modelName: String
    let resolution: CGSize
    let safeArea: UIEdgeInsets
    
    // Implement Hashable conformance
    static func == (lhs: DeviceConfig, rhs: DeviceConfig) -> Bool {
        return lhs.modelName == rhs.modelName &&
               lhs.resolution.width == rhs.resolution.width &&
               lhs.resolution.height == rhs.resolution.height &&
               lhs.safeArea.top == rhs.safeArea.top &&
               lhs.safeArea.left == rhs.safeArea.left &&
               lhs.safeArea.bottom == rhs.safeArea.bottom &&
               lhs.safeArea.right == rhs.safeArea.right
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(modelName)
        hasher.combine(resolution.width)
        hasher.combine(resolution.height)
        hasher.combine(safeArea.top)
        hasher.combine(safeArea.left)
        hasher.combine(safeArea.bottom)
        hasher.combine(safeArea.right)
    }
    
    static let iPhone12ProMax = DeviceConfig(
        modelName: "iPhone 12 Pro Max",
        resolution: CGSize(width: 1284, height: 2778),
        safeArea: UIEdgeInsets(top: 200, left: 0, bottom: 150, right: 0)
    )
}

class DeviceManager {
    static let shared = DeviceManager()
    
    private let supportedDevices: [DeviceConfig] = [
        .iPhone12ProMax
    ]
    
    var defaultDevice: DeviceConfig {
        return DeviceConfig.iPhone12ProMax
    }
    
    func getDevice(byName name: String) -> DeviceConfig? {
        return supportedDevices.first { $0.modelName == name }
    }
    
    func getSafeAreaRect(for device: DeviceConfig) -> CGRect {
        return CGRect(
            x: device.safeArea.left,
            y: device.safeArea.top,
            width: device.resolution.width - device.safeArea.left - device.safeArea.right,
            height: device.resolution.height - device.safeArea.top - device.safeArea.bottom
        )
    }
} 