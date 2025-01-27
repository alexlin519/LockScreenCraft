import Photos
import UIKit

enum PhotoServiceError: Error {
    case permissionDenied
    case saveFailed
}

class PhotoService {
    static let shared = PhotoService()
    
    func requestPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            return await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    func saveImage(_ image: UIImage) async throws {
        guard await requestPermission() else {
            throw PhotoServiceError.permissionDenied
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PhotoServiceError.saveFailed)
                }
            }
        }
    }
} 