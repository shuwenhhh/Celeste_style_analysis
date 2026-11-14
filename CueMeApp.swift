import SwiftUI

@main
struct CueMeApp: App {
    var body: some Scene {
        WindowGroup {
            AppEntryView()
                .preferredColorScheme(.light)
                .environment(\.locale, Locale(identifier: "en"))
        }
    }
}
struct AppEntryView: View {
    private let result = Result { try AnalysisResult.load() }
    var body: some View {
        switch result {
        case .success(let analysis): ContentView(result: analysis)
        case .failure:
            ContentUnavailableView("Cue Me could not open", systemImage: "exclamationmark.triangle",
                description: Text("The style guide is missing. Please reinstall the app."))
        }
    }
}
