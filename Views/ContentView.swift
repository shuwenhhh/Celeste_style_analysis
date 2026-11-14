import SwiftUI
import PhotosUI
import AVFoundation

private enum Screen: Hashable { case welcome, tips, camera, analyzing, result, share }

struct ContentView: View {
    let result: AnalysisResult
    private let imageService: any LookImageService = UnconnectedLookImageService()
    @State private var screen: Screen = .welcome
    @State private var photo: UIImage?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var occasion = "Work"
    @State private var kind: LookImageKind = .full
    @State private var images: [LookKey: LookImageState] = [:]
    @State private var cameraPresented = false
    @State private var sharePresented = false
    @State private var shareImage: UIImage?
    @State private var error = ""
    @State private var completed = 0
    @State private var generation = UUID()
    @State private var saving = false
    @State private var saved = false

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    switch screen {
                    case .welcome: welcome
                    case .tips: tips
                    case .camera: cameraFallback
                    case .analyzing: analyzing
                    case .result: resultView
                    case .share: shareView
                    }
                    if !error.isEmpty { Text(error).font(Theme.body(12)).foregroundStyle(Theme.muted).accessibilityLabel(error) }
                }.padding(.horizontal, 26).padding(.top, 12).padding(.bottom, 32)
                    .frame(maxWidth: 430)
                    .frame(maxWidth: .infinity)
            }.id(screen)
        }
        .font(Theme.body()).foregroundStyle(Theme.ink).background(Theme.background)
        .fullScreenCover(isPresented: $cameraPresented) {
            PhotoCapture(onPhoto: { image in cameraPresented = false; accept(image) },
                         onCancel: { cameraPresented = false; screen = .tips })
                .ignoresSafeArea()
        }
        .sheet(isPresented: $sharePresented) {
            if let shareImage { NativeShareSheet(image: shareImage) }
        }
        .onChange(of: selectedPhoto) { _, item in
            Task { @MainActor in
                do {
                    guard let data = try await item?.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                        error = "This photo could not be opened. Please choose another."; return
                    }
                    accept(image)
                    selectedPhoto = nil
                } catch { self.error = "This photo could not be opened. Please choose another." }
            }
        }
        .task(id: screen) {
            guard screen == .analyzing else { return }
            for step in 1...result.analysisSteps.count {
                do { try await Task.sleep(for: .milliseconds(1500)) } catch { return }
                guard !Task.isCancelled else { return }
                completed = step
            }
            screen = .result
            request(.full)
        }
    }

    private var header: some View {
        HStack {
            Button { back() } label: { Image(systemName: "arrow.left").frame(width: 44, height: 44) }
                .accessibilityLabel("Go back")
                .opacity(screen == .welcome || screen == .analyzing ? 0 : 1)
                .disabled(screen == .welcome || screen == .analyzing)
            Spacer(); Wordmark(); Spacer()
            Image(systemName: "sparkles").foregroundStyle(Theme.rose).frame(width: 44, height: 44)
        }.padding(.horizontal, 20).frame(height: 70)
    }
    private var welcome: some View {
        VStack(spacing: 20) {
            Image("cue-portrait.jpg").resizable().scaledToFill().frame(height: 300).clipped()
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 145, bottomLeadingRadius: 16, bottomTrailingRadius: 16, topTrailingRadius: 145))
                .accessibilityLabel("A woman in a soft mauve blouse in natural daylight")
            Eyebrow("Your personal color story")
            Text("Find the colors\nthat suit you").font(Theme.heading(35)).multilineTextAlignment(.center)
            Text("One selfie. Your color season, makeup and outfit guide in a minute.")
                .foregroundStyle(Theme.muted).multilineTextAlignment(.center)
            Button { screen = .tips } label: { Label("Get started", systemImage: "arrow.right") }.buttonStyle(CueButtonStyle())
            PrivacyNote()
            Divider()
            HStack { Label("Your colors", systemImage: "sun.max"); Spacer(); Label("Your style", systemImage: "sparkles") }
                .font(Theme.body(11)).foregroundStyle(Theme.mocha)
        }
    }
    private var tips: some View {
        VStack(alignment: .leading, spacing: 22) {
            Eyebrow("A good photo makes all the difference")
            Text("Let’s see the real you.").font(Theme.heading(31))
            Text("A little daylight. A fresh face. Just you.").foregroundStyle(Theme.muted)
            HStack(spacing: 12) { tipExample(good: true); tipExample(good: false) }
            ForEach(["Face a window for natural daylight", "Start with a bare face, no makeup", "Turn off any beauty filter", "Keep your hairline visible"], id: \.self) { tip in
                Label(tip, systemImage: "checkmark.circle").foregroundStyle(Theme.success)
            }
            Button { openCamera() } label: { Label("Open camera", systemImage: "camera") }.buttonStyle(CueButtonStyle())
            libraryButton
            PrivacyNote()
        }
    }
    private func tipExample(good: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image("cue-portrait.jpg").resizable().scaledToFill().frame(height: 160).clipped()
                .brightness(good ? 0 : -0.35).saturation(good ? 1 : 0.4)
            Label(good ? "Good" : "Avoid", systemImage: good ? "checkmark.circle" : "xmark").padding(.horizontal, 12)
            Text(good ? "Soft, natural daylight" : "Shadows and filters").font(Theme.body(10)).padding(.horizontal, 12).padding(.bottom, 12)
        }.frame(maxWidth: .infinity).background(Theme.surface).clipShape(RoundedRectangle(cornerRadius: 16))
    }
    private var libraryButton: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            Label("Choose from library", systemImage: "photo")
        }.buttonStyle(CueButtonStyle(outlined: true))
    }
    private var cameraFallback: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Hello, beautiful.").font(Theme.heading(31))
            Image(systemName: "camera").font(.system(size: 48)).foregroundStyle(Theme.mocha).frame(maxWidth: .infinity, minHeight: 240)
            libraryButton
        }
    }
    private var analyzing: some View {
        VStack(spacing: 24) {
            selfieCircle(size: 160)
            Eyebrow("A moment just for you")
            Text("Finding your harmony.").font(Theme.heading(31))
            Text("Your personal color story is coming together.").foregroundStyle(Theme.muted).multilineTextAlignment(.center)
            ForEach(Array(result.analysisSteps.enumerated()), id: \.offset) { index, step in
                HStack {
                    if index < completed { Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.success) }
                    else if index == completed { ProgressView().tint(Theme.rose) }
                    else { Image(systemName: "circle").foregroundStyle(Theme.border) }
                    Text(step); Spacer()
                }.padding(.vertical, 5)
            }
        }.frame(maxWidth: .infinity).padding(.top, 30)
    }
    private func selfieCircle(size: CGFloat) -> some View {
        Group { if let photo { Image(uiImage: photo).resizable().scaledToFill() } }
            .frame(width: size, height: size).clipShape(Circle()).accessibilityLabel("Your selfie")
    }
    private var resultView: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(spacing: 14) {
                selfieCircle(size: 110)
                Eyebrow("Your color season")
                Text(result.season).font(Theme.heading(31))
                ViewThatFits(in: .horizontal) {
                    HStack { ForEach(result.tags, id: \.self) { Text($0).font(Theme.body(10)) } }
                    VStack { ForEach(result.tags, id: \.self) { Text($0).font(Theme.body(11)) } }
                }
            }.frame(maxWidth: .infinity).padding(24).background(Theme.accent).clipShape(RoundedRectangle(cornerRadius: 16))
            SectionHeading(title: "Looks by occasion")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(result.occasions, id: \.self) { item in
                    Button {
                        occasion = item; kind = .full; request(.full)
                    } label: {
                        Text(item).font(Theme.body(12)).frame(maxWidth: .infinity, minHeight: 44)
                            .foregroundStyle(occasion == item ? Theme.surface : Theme.ink)
                            .background(occasion == item ? Theme.mocha : Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }.accessibilityAddTraits(occasion == item ? .isSelected : [])
                }
            }
            if let look = result.looks[occasion] {
                gallery(look: look)
                Text(look.title).font(Theme.heading(26))
                Text(look.tagline).foregroundStyle(Theme.muted)
                SectionHeading(title: "Makeup")
                ForEach(look.makeup) { row in
                    HStack(alignment: .top, spacing: 10) {
                        Text(row.label).fontWeight(.semibold).frame(width: 47, alignment: .leading)
                        Text(row.tip).foregroundStyle(Theme.muted).frame(maxWidth: .infinity, alignment: .leading)
                        HStack(spacing: 3) { ForEach(row.colors, id: \.self) { hex in Circle().fill(Color(hex: hex)).frame(width: 10, height: 10) } }
                    }.font(Theme.body(12))
                    Divider()
                }
                SectionHeading(title: "Outfit and accessories"); DetailRows(rows: look.outfit)
                SectionHeading(title: "Colors for this look"); PaletteView(colors: look.colors, columns: 4, named: true)
                SectionHeading(title: "Hair"); DetailRows(rows: look.hair)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Good to know").fontWeight(.semibold)
                    Text(look.goodToKnow).foregroundStyle(Theme.muted)
                }.font(Theme.body(12)).padding(.leading, 14).overlay(alignment: .leading) { Rectangle().fill(Theme.rose).frame(width: 2) }
            }
            Divider(); SectionHeading(title: "Your features"); DetailRows(rows: result.features)
            Divider(); SectionHeading(title: "Your palette")
            Text("Best colors (12)").font(Theme.body(12)); PaletteView(colors: result.bestColors, columns: 6)
            Text("Use with care (4)").font(Theme.body(12)); PaletteView(colors: result.careColors, columns: 6)
            Button { saved = false; error = ""; screen = .share } label: { Label("Share this look", systemImage: "square.and.arrow.up") }.buttonStyle(CueButtonStyle())
            Button { reset() } label: { Label("Retake photo", systemImage: "arrow.counterclockwise") }.buttonStyle(CueButtonStyle(outlined: true))
        }
    }
    private func gallery(look: Look) -> some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    switch images[LookKey(occasion: occasion, kind: kind)] {
                    case .available(let image): Image(uiImage: image).resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).clipped()
                    case .failed:
                        if let photo { Image(uiImage: photo).resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).clipped() }
                        Text("Preview unavailable").font(Theme.body(14)).padding(12).background(Theme.background.opacity(0.9)).frame(maxWidth: .infinity, maxHeight: .infinity)
                    default:
                        VStack(spacing: 12) { ProgressView().tint(Theme.rose); Text("Creating your look…") }.frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    Text(look.intensity).font(Theme.body(11)).padding(10).background(Theme.background).clipShape(Capsule()).padding(12)
                }.background(Theme.accent).clipShape(RoundedRectangle(cornerRadius: 16))
            }.aspectRatio(3 / 4, contentMode: .fit)
            HStack(spacing: 10) {
                ForEach(LookImageKind.allCases, id: \.self) { type in
                    Button { kind = type; request(type) } label: {
                        HStack(spacing: 8) {
                            thumbnail(type).frame(width: 32, height: 43).clipped().clipShape(RoundedRectangle(cornerRadius: 5))
                            Text(type.title).font(Theme.body(11)).multilineTextAlignment(.leading)
                        }.frame(maxWidth: .infinity, minHeight: 58).padding(.horizontal, 6)
                            .background(Theme.surface).clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(kind == type ? Theme.ink : Theme.border))
                    }.accessibilityAddTraits(kind == type ? .isSelected : [])
                }
            }
        }
    }
    @ViewBuilder private func thumbnail(_ type: LookImageKind) -> some View {
        if case .available(let image) = images[LookKey(occasion: occasion, kind: type)] {
            Image(uiImage: image).resizable().scaledToFill()
        } else { Image(systemName: "sparkles").foregroundStyle(Theme.mocha) }
    }
    private var fullImage: UIImage? {
        if case .available(let image) = images[LookKey(occasion: occasion, kind: .full)] { return image }
        return photo
    }
    private var shareView: some View {
        VStack(alignment: .leading, spacing: 22) {
            Eyebrow("Made for you")
            Text("Your colors, to keep.").font(Theme.heading(31))
            ShareCardView(image: fullImage, result: result).aspectRatio(9 / 16, contentMode: .fit)
            Button {
                Task { @MainActor in
                    saving = true; error = ""
                    defer { saving = false }
                    guard let image = renderShare() else { error = "Your image could not be created."; return }
                    do { try await PhotoSaver.save(image); saved = true }
                    catch { self.error = "Your image could not be saved. Allow photo access in Settings and try again." }
                }
            } label: { Label(saving ? "Saving…" : saved ? "Save image again" : "Save image", systemImage: "arrow.down.to.line") }
                .buttonStyle(CueButtonStyle()).disabled(saving)
            Button("Done") { screen = .result }.buttonStyle(CueButtonStyle(outlined: true))
        }
    }
    @MainActor private func renderShare() -> UIImage? {
        let renderer = ImageRenderer(content: ShareCardView(image: fullImage, result: result)
            .frame(width: 360, height: 640).environment(\.locale, Locale(identifier: "en")))
        renderer.scale = 3
        return renderer.uiImage
    }
    private func accept(_ image: UIImage) {
        generation = UUID(); images.removeAll(); photo = image
        completed = 0; occasion = "Work"; kind = .full; error = ""; screen = .analyzing
    }
    private func reset() {
        generation = UUID(); photo = nil; shareImage = nil; images.removeAll(); error = ""; screen = .tips
    }
    private func back() {
        error = ""
        switch screen {
        case .share: screen = .result
        case .result: screen = .tips
        default: screen = .welcome
        }
    }
    private func openCamera() {
        screen = .camera; error = ""
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            error = "Camera access is unavailable. Choose a photo from your library instead."; return
        }
        Task { @MainActor in
            let allowed: Bool
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: allowed = true
            case .notDetermined: allowed = await AVCaptureDevice.requestAccess(for: .video)
            default: allowed = false
            }
            if allowed { cameraPresented = true }
            else { error = "Camera access is unavailable. Choose a photo from your library instead." }
        }
    }
    private func request(_ type: LookImageKind) {
        let key = LookKey(occasion: occasion, kind: type)
        guard images[key] == nil, let photo, let look = result.looks[occasion] else { return }
        images[key] = .loading
        let token = generation
        Task { @MainActor in
            do {
                let image = try await imageService.generate(selfie: photo, occasion: key.occasion, kind: type, look: look)
                guard generation == token else { return }
                images[key] = .available(image)
            } catch {
                guard generation == token else { return }
                images[key] = .failed
            }
        }
    }
}
