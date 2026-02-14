import SwiftUI

/// A mock class to simulate and verify image generation behavior without using a real AI API.
class MockImageGenerator: ImageGeneratorProtocol {
    var lastPromptReceived: String?
    var shouldFail: Bool = false
    var simulatedDelay: Double = 1.5
    
    func generateImage(prompt: String) async throws -> UIImage {
        lastPromptReceived = prompt
        
        // Simulate processing time
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        if shouldFail {
            throw NSError(domain: "MockImageGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Simulated generation failure"])
        }
        
        // Return a color-coded mock image based on the prompt hash to simulate "variation"
        let hash = prompt.hashValue
        let color = Color(
            hue: Double(abs(hash % 360)) / 360.0,
            saturation: 0.8,
            brightness: 0.9
        )
        
        return createMockImage(color: color)
    }
    
    private func createMockImage(color: Color) -> UIImage {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let uiColor = UIColor(color)
            uiColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Draw some "mythic" lines
            UIColor.white.withAlphaComponent(0.3).setStroke()
            context.cgContext.setLineWidth(10)
            context.cgContext.stroke(CGRect(x: 50, y: 50, width: 412, height: 412))
            context.cgContext.move(to: CGPoint(x: 0, y: 0))
            context.cgContext.addLine(to: CGPoint(x: 512, y: 512))
            context.cgContext.strokePath()
        }
    }
}
