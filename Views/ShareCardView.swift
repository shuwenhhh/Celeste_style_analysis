import SwiftUI

struct ShareCardView: View {
    let image: UIImage?
    let result: AnalysisResult
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 14) {
                Wordmark()
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                        .frame(width: geometry.size.width * 0.58, height: geometry.size.height * 0.40)
                        .clipped().clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Eyebrow("Your color season")
                Text(result.season).font(Theme.heading(30)).foregroundStyle(Theme.ink)
                PaletteView(colors: result.bestColors, columns: 4)
                Text("Your colors. Your kind of beautiful.").font(Theme.heading(13)).foregroundStyle(Theme.ink)
            }.padding(24).frame(width: geometry.size.width, height: geometry.size.height)
                .background(Theme.accent).clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
