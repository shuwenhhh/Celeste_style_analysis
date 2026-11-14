import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let value = UInt64(cleaned, radix: 16) ?? 0
        self.init(.sRGB, red: Double((value >> 16) & 255) / 255,
                  green: Double((value >> 8) & 255) / 255,
                  blue: Double(value & 255) / 255, opacity: 1)
    }
}
enum Theme {
    static let background = Color(hex: "FAF6F1")
    static let ink = Color(hex: "3B2F2A")
    static let rose = Color(hex: "C98B8B")
    static let mocha = Color(hex: "A67C68")
    static let muted = Color(hex: "806F67")
    static let border = Color(hex: "E4D9D1")
    static let accent = Color(hex: "F0DFDD")
    static let surface = Color(hex: "FFFFFF")
    static let success = Color(hex: "57785F")
    static func heading(_ size: CGFloat) -> Font { .custom("PlayfairDisplay-Regular", size: size, relativeTo: .title) }
    static func body(_ size: CGFloat = 14) -> Font { .custom("Inter-Regular", size: size, relativeTo: .body) }
}
struct CueButtonStyle: ButtonStyle {
    var outlined = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body(14)).fontWeight(.medium)
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(outlined ? Theme.ink : Theme.surface)
            .background(outlined ? Theme.background : Theme.rose)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(outlined ? Theme.border : Theme.rose))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
struct Wordmark: View {
    var body: some View {
        (Text("Cue ").foregroundColor(Theme.ink) + Text("Me").foregroundColor(Theme.rose))
            .font(Theme.heading(28))
    }
}
struct Eyebrow: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View { Text(title.uppercased()).font(Theme.body(10)).foregroundStyle(Theme.mocha) }
}
struct PrivacyNote: View {
    var body: some View {
        Label("Photos are used for this analysis only and never stored.", systemImage: "lock")
            .font(Theme.body(10)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
    }
}
struct SectionHeading: View {
    let title: String
    var body: some View { Text(title).font(Theme.heading(24)).frame(maxWidth: .infinity, alignment: .leading) }
}
struct DetailRows: View {
    let rows: [Detail]
    var body: some View {
        ForEach(rows) { row in
            HStack(alignment: .top, spacing: 12) {
                Text(row.label).fontWeight(.semibold).frame(width: 65, alignment: .leading)
                Text(row.tip).foregroundStyle(Theme.muted).frame(maxWidth: .infinity, alignment: .leading)
            }.font(Theme.body(12)).padding(.vertical, 10)
            if row.id != rows.last?.id { Divider().overlay(Theme.border) }
        }
    }
}
struct PaletteView: View {
    let colors: [PaletteColor]
    let columns: Int
    var named = false
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns), spacing: 12) {
            ForEach(colors) { color in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: named ? 8 : 24)
                        .fill(Color(hex: color.hex)).frame(height: named ? 52 : 36)
                    if named { Text(color.name).font(Theme.body(10)).foregroundStyle(Theme.muted) }
                }.accessibilityElement(children: .ignore).accessibilityLabel(color.name)
            }
        }
    }
}
