import AppKit
import Carbon
import SwiftUI

struct NotchView: View {
    let text: String
    var onDismiss: () -> Void
    var autoStart: Bool = false
    let topInset: CGFloat

    @State private var words: [String] = []
    @State private var currentIndex = 0
    @State private var countdown = 3
    @State private var mode: ViewMode = .countdown
    @State private var isPlaying = false
    @State private var showSettings = false

    init(
        text: String,
        onDismiss: @escaping () -> Void,
        autoStart: Bool = false,
        topInset: CGFloat,
        startWithSettings: Bool = false
    ) {
        self.text = text
        self.onDismiss = onDismiss
        self.autoStart = autoStart
        self.topInset = topInset
        self._showSettings = State(initialValue: startWithSettings)
    }

    // Settings
    @AppStorage("wpm") private var wpm: Double = 300
    @AppStorage("fontSize") private var fontSize: Double = 20
    @AppStorage("shortcutKeyCode") private var shortcutKeyCode: Int = Int(defaultShortcutKeyCode)
    @AppStorage("shortcutModifiers") private var shortcutModifiers: Int = Int(
        defaultShortcutModifiers)
    @AppStorage("shortcutModifier") private var shortcutModifier: String = "control"

    @State private var timer: Timer?
    @State private var dismissTimer: DispatchWorkItem?
    @State private var notchWidth: CGFloat = 500

    // Animation constants
    private let springAnimation = Animation.interactiveSpring(
        response: 0.35,
        dampingFraction: 0.75,
        blendDuration: 0
    )

    enum ViewMode {
        case countdown
        case reading
        case finished
    }

    // Geometry constants
    private let cornerRadius: CGFloat = 12
    private let spacing: CGFloat = 8
    private let baseBodyHeight: CGFloat = 92
    private let expandedBodyHeight: CGFloat = 192
    private let contentHorizontalPadding: CGFloat = 16
    private let textHorizontalPadding: CGFloat = 16
    private let widthBuffer: CGFloat = 12

    private var notchBodyHeight: CGFloat {
        showSettings && (mode == .reading || mode == .countdown)
            ? expandedBodyHeight : baseBodyHeight
    }

    private var fontSizeExtraHeight: CGFloat {
        max(0, fontSize - 50)
    }

    private var notchHeight: CGFloat {
        notchBodyHeight + topInset + fontSizeExtraHeight
    }

    var body: some View {
        ZStack(alignment: .top) {
            // The notch background shape using mask
            notchBackground

            // Content
            VStack(spacing: 8) {
                // Main content area
                Group {
                    switch mode {
                    case .countdown:
                        Text("\(countdown)")
                            .font(.system(size: fontSize, weight: .bold))
                            .foregroundColor(.red)
                            .transition(.scale)
                    case .reading:
                        if !words.isEmpty && currentIndex < words.count {
                            Text(words[currentIndex])
                                .font(.system(size: fontSize, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .padding(.horizontal, textHorizontalPadding)
                        }
                    case .finished:
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 24))
                                .foregroundColor(.green)

                            HStack(spacing: 8) {
                                Button(action: restart) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.counterclockwise")
                                        Text("Restart")
                                    }
                                    .font(.system(size: 12))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(6)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("Restart")

                                HoverButton(icon: "xmark", iconColor: .white) {
                                    dismissNow()
                                }
                                .help("Close")
                            }
                        }
                    }
                }
                .frame(height: 40 + fontSizeExtraHeight)

                // Controls
                if mode == .reading || mode == .countdown {
                    HStack(spacing: 8) {
                        if mode == .reading {
                            // Play/Pause button
                            HoverButton(
                                icon: isPlaying ? "pause.fill" : "play.fill", iconColor: .white
                            ) {
                                togglePlayPause()
                            }
                            .help(isPlaying ? "Pause" : "Play")
                            // Go back 5 words button
                            HoverButton(
                                icon: "gobackward.5",
                                iconColor: currentIndex == 0 ? .gray : .white
                            ) {
                                goBack5Words()
                            }
                            .help("Go back 5 words")
                            .disabled(currentIndex == 0)

                            // Restart button
                            HoverButton(icon: "arrow.counterclockwise", iconColor: .white) {
                                restart()
                            }
                            .help("Restart")
                        }
                        Spacer()
                        if mode == .reading {
                            // Progress indicator
                            Text("\(currentIndex + 1)/\(words.count)")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                        // Settings gear icon (always visible in countdown/reading)
                        HoverButton(icon: "gear", iconColor: .white) {
                            showSettings.toggle()
                        }
                        .help("Settings")
                        // Close button (always visible in countdown/reading)
                        HoverButton(icon: "xmark", iconColor: .white) {
                            dismissNow()
                        }
                        .help("Close")
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 20)
                }

                // Settings panel
                if showSettings && (mode == .reading || mode == .countdown) {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Speed (WPM):")
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                            Slider(value: $wpm, in: 100...1000, step: 25)
                                .frame(width: 350)
                            Text("\(Int(wpm))")
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                                .frame(width: 40)
                        }

                        HStack {
                            Text("Font Size:")
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                            Slider(value: $fontSize, in: 25...75, step: 1)
                                .frame(width: 300)
                            Text("\(Int(fontSize))")
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                                .frame(width: 40)
                        }

                        HStack {
                            Text("Shortcut:")
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                            ShortcutRecorder(
                                keyCode: $shortcutKeyCode,
                                modifiers: $shortcutModifiers
                            ) {
                                ShortcutManager.shared.register()
                            }
                            .frame(width: 240)

                            Button("Reset") {
                                shortcutKeyCode = Int(defaultShortcutKeyCode)
                                shortcutModifiers = Int(defaultShortcutModifiers)
                                ShortcutManager.shared.register()
                            }
                            .font(.system(size: 11))
                        }
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, topInset)
            .padding(.vertical, 12)
            .padding(.horizontal, contentHorizontalPadding)
        }
        .frame(height: notchHeight)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            updateNotchWidth()
            postNotchHeightChange()
            postNotchWidthChange()
            postReadingStateChange()
            if words.isEmpty {
                mode = .finished
                autoDismiss()
            } else {
                if autoStart {
                    // Skip countdown and start reading immediately
                    startReading()
                } else {
                    startCountdown()
                }
            }
            if showSettings {
                timer?.invalidate()
                isPlaying = false
                postNotchHeightChange()
            }
        }
        .onDisappear {
            timer?.invalidate()
            cancelAutoDismiss()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: NSNotification.Name("SpacebarPressed"))
        ) { _ in
            if mode == .reading {
                togglePlayPause()
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: NSNotification.Name("NotchEscapePressed"))
        ) { _ in
            if mode == .reading {
                onDismiss()
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: NSNotification.Name("NotchOpenSettings"))
        ) { _ in
            showSettings = true
        }
        .onChange(of: showSettings) { _, newValue in
            postNotchHeightChange()
            if newValue {
                // Pause reading or countdown
                timer?.invalidate()
                isPlaying = false
            } else {
                // Resume reading or countdown
                if mode == .reading {
                    if currentIndex < words.count - 1 {
                        isPlaying = true
                        resumeReading()
                    }
                } else if mode == .countdown {
                    timer?.invalidate()
                    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
                        if countdown > 1 {
                            withAnimation {
                                countdown -= 1
                            }
                        } else {
                            t.invalidate()
                            startReading()
                        }
                    }
                }
            }
        }
        .onChange(of: mode) { _, _ in
            postNotchHeightChange()
            postReadingStateChange()
        }
        .onChange(of: fontSize) { _, _ in
            updateNotchWidth()
            postNotchWidthChange()
            postNotchHeightChange()
        }
    }

    func startCountdown() {
        mode = .countdown
        countdown = 3
        cancelAutoDismiss()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if countdown > 1 {
                withAnimation {
                    countdown -= 1
                }
            } else {
                t.invalidate()
                startReading()
            }
        }
    }

    func startReading() {
        mode = .reading
        isPlaying = true
        cancelAutoDismiss()
        resumeReading()
    }

    func resumeReading() {
        timer?.invalidate()

        let interval = 60.0 / wpm

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
            if !isPlaying {
                return
            }

            if currentIndex < words.count - 1 {
                currentIndex += 1
            } else {
                t.invalidate()
                mode = .finished
                autoDismiss()
            }
        }
    }

    func togglePlayPause() {
        isPlaying.toggle()

        if isPlaying {
            resumeReading()
        } else {
            timer?.invalidate()
        }
    }

    func goBack5Words() {
        currentIndex = max(0, currentIndex - 5)
    }

    func restart() {
        cancelAutoDismiss()
        timer?.invalidate()
        currentIndex = 0
        isPlaying = false
        startReading()
    }

    func autoDismiss() {
        cancelAutoDismiss()
        let workItem = DispatchWorkItem {
            self.onDismiss()
        }
        dismissTimer = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: workItem)
    }

    func dismissNow() {
        cancelAutoDismiss()
        onDismiss()
    }

    func cancelAutoDismiss() {
        dismissTimer?.cancel()
        dismissTimer = nil
    }

    private func postNotchHeightChange() {
        NotificationCenter.default.post(
            name: NSNotification.Name("NotchHeightChanged"),
            object: nil,
            userInfo: ["height": notchHeight]
        )
    }

    private func postNotchWidthChange() {
        NotificationCenter.default.post(
            name: NSNotification.Name("NotchWidthChanged"),
            object: nil,
            userInfo: ["width": notchWidth]
        )
    }

    private func postReadingStateChange() {
        NotificationCenter.default.post(
            name: NSNotification.Name("NotchReadingStateChanged"),
            object: nil,
            userInfo: ["isReading": mode == .reading]
        )
    }

    private func updateNotchWidth() {
        let minWidth: CGFloat = 500
        let font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
        let maxWordWidth =
            words
            .map { word in
                (word as NSString).size(withAttributes: [.font: font]).width
            }
            .max() ?? 0
        let paddedWidth =
            maxWordWidth
            + (contentHorizontalPadding * 2)
            + (textHorizontalPadding * 2)
            + widthBuffer
        notchWidth = max(minWidth, paddedWidth)
    }

    // MARK: - Visual Components
    var notchBackground: some View {
        Rectangle()
            .foregroundStyle(Color.black.opacity(0.90))
            .mask(notchBackgroundMaskGroup)
            .frame(
                width: notchWidth + cornerRadius * 2,
                height: notchHeight
            )
    }
    var notchBackgroundMaskGroup: some View {
        Rectangle()
            .foregroundStyle(.black)
            .frame(
                width: notchWidth,
                height: notchHeight
            )
            .clipShape(
                .rect(
                    bottomLeadingRadius: cornerRadius,
                    bottomTrailingRadius: cornerRadius
                )
            )
            .overlay {
                // Top Right "Liquid" Corner
                ZStack(alignment: .topTrailing) {
                    Rectangle()
                        .frame(width: cornerRadius, height: cornerRadius)
                        .foregroundStyle(.black)
                    Rectangle()
                        .clipShape(.rect(topTrailingRadius: cornerRadius))
                        .foregroundStyle(.white)
                        .frame(
                            width: cornerRadius + spacing,
                            height: cornerRadius + spacing
                        )
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .offset(x: -cornerRadius - spacing + 0.5, y: -0.5)
            }
            .overlay {
                // Top Left "Liquid" Corner
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .frame(width: cornerRadius, height: cornerRadius)
                        .foregroundStyle(.black)
                    Rectangle()
                        .clipShape(.rect(topLeadingRadius: cornerRadius))
                        .foregroundStyle(.white)
                        .frame(
                            width: cornerRadius + spacing,
                            height: cornerRadius + spacing
                        )
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: cornerRadius + spacing - 0.5, y: -0.5)
            }
    }
}
