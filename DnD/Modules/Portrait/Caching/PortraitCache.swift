import SwiftUI
import CryptoKit

class PortraitCache {
    static let shared = PortraitCache()
    private let cacheDirectory: URL
    
    private init() {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("PortraitCache")
        
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    private func hash(for string: String) -> String {
        let inputData = Data(string.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func saveImage(_ image: UIImage, for key: String) {
        let filename = hash(for: key) + ".png"
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        if let data = image.pngData() {
            try? data.write(to: fileURL)
        }
    }
    
    func getImage(for key: String) -> UIImage? {
        let filename = hash(for: key) + ".png"
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        if let data = try? Data(contentsOf: fileURL) {
            return UIImage(data: data)
        }
        return nil
    }
}
