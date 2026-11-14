import Foundation

struct PaletteColor: Decodable, Identifiable {
    var id: String { name }
    let name: String
    let hex: String
}
struct Detail: Decodable, Identifiable {
    var id: String { label }
    let label: String
    let tip: String
}
struct Makeup: Decodable, Identifiable {
    var id: String { label }
    let label: String
    let tip: String
    let colors: [String]
}
struct Look: Decodable {
    let title: String
    let tagline: String
    let intensity: String
    let makeup: [Makeup]
    let outfit: [Detail]
    let colors: [PaletteColor]
    let hair: [Detail]
    let goodToKnow: String
}
struct AnalysisResult: Decodable {
    let season: String
    let tags: [String]
    let features: [Detail]
    let bestColors: [PaletteColor]
    let careColors: [PaletteColor]
    let occasions: [String]
    let looks: [String: Look]
    let analysisSteps: [String]

    static func load() throws -> AnalysisResult {
        guard let url = Bundle.main.url(forResource: "analysis", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(AnalysisResult.self, from: Data(contentsOf: url))
    }
}
