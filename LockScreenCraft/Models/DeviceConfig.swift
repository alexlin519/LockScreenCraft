import SwiftUI

struct DeviceConfig {
    let modelName: String
    let resolution: CGSize
    let safeArea: UIEdgeInsets
    
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