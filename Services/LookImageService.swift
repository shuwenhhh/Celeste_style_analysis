import Foundation
import UIKit

// Keep provider credentials on a server. No network requests or uploads occur
// in the default source delivery. Replace this service with your own authenticated
// HTTPS service when you connect AI; never put an AI API key in the iOS app.
enum LookImageKind: String, CaseIterable, Hashable {
    case full, closeup
    var title: String { self == .full ? "Full look" : "Makeup close-up" }
}
struct LookKey: Hashable {
    let occasion: String
    let kind: LookImageKind
}
enum LookImageState {
    case loading
    case available(UIImage)
    case failed
}
@MainActor
protocol LookImageService {
    func generate(selfie: UIImage, occasion: String, kind: LookImageKind, look: Look) async throws -> UIImage
}
struct UnconnectedLookImageService: LookImageService {
    func generate(selfie: UIImage, occasion: String, kind: LookImageKind, look: Look) async throws -> UIImage {
        throw URLError(.unsupportedURL)
    }
}
