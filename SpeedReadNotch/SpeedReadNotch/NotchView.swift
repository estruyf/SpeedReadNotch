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
    @State private var countdownProgress: Double = 1.0
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
    @AppStorage("cleanWords") private var cleanWords: Bool = false

    @State private var timer: Timer?
    @State private var dismissTimer: DispatchWorkItem?
    @State private var notchWidth: CGFloat = 500

    // Animation constants
    private let springAnimation = Animation.interactiveSpring(
        response: 0.35,
        dampingFraction: 0.75,
        blendDuration: 0
    )
    
    // Color constants
    private let accentColor = Color(red: 206/255, green: 71/255, blue: 96/255)

    enum ViewMode {
        case countdown
        case reading
        case finished
    }

    // Geometry constants
    private let cornerRadius: CGFloat = 12
    private let spacing: CGFloat = 8
    private let baseBodyHeight: CGFloat = 116
    private let expandedBodyHeight: CGFloat = 250
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
                        if showSettings {
                            orpWordContent(word: "SpeedReadNotch")
                        } else if !words.isEmpty {
                            ZStack {
                                orpWordContent(word: words[0])
                                // Countdown overlay
                                GeometryReader { geometry in
                                    HStack(spacing: 0) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: (geometry.size.width / 2) * countdownProgress)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: (geometry.size.width / 2) * countdownProgress)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                        }
                    case .reading:
                        if showSettings {
                            orpWordContent(word: "SpeedReadNotch")
                        } else if !words.isEmpty && currentIndex < words.count {
                            orpWordContent(word: words[currentIndex])
                        }
                    case .finished:
                        if showSettings {
                            orpWordContent(word: "SpeedReadNotch")
                        } else {
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
                }
                .frame(height: 56 + fontSizeExtraHeight)

                // Controls
                if mode == .reading || mode == .countdown || (mode == .finished && showSettings) {
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            if mode == .reading {
                                // Restart button
                                HoverButton(icon: "backward.end.fill", iconColor: .white) {
                                    restart()
                                }
                                .help("Restart")
                                // Previous word button
                                HoverButton(
                                    icon: "backward.fill",
                                    iconColor: currentIndex == 0 ? .gray : .white
                                ) {
                                    goBack1Word()
                                }
                                .help("Previous word")
                                .disabled(currentIndex == 0)
                                // Play/Pause button
                                HoverButton(
                                    icon: isPlaying ? "pause.fill" : "play.fill", iconColor: .white
                                ) {
                                    togglePlayPause()
                                }
                                .help(isPlaying ? "Pause" : "Play")
                                // Next word button
                                HoverButton(
                                    icon: "forward.fill",
                                    iconColor: currentIndex >= words.count - 1 ? .gray : .white
                                ) {
                                    goForward1Word()
                                }
                                .help("Next word")
                                .disabled(currentIndex >= words.count - 1)
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
                        
                        // Reading progress bar
                        if mode == .reading {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.gray.opacity(0.3))
                                    Capsule().fill(accentColor)
                                        .frame(width: geo.size.width * readingProgress)
                                }
                            }
                            .frame(height: 2)
                            .padding(.horizontal, textHorizontalPadding)
                        }
                    }
                }

                // Settings panel
                if showSettings && (mode == .reading || mode == .countdown) {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Speed (WPM):")
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                                .frame(width: 80, alignment: .leading)
                            Slider(value: $wpm, in: 100...1000, step: 25)
                            Text("\(Int(wpm))")
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                                .frame(width: 40)
                        }
                        .frame(maxWidth: .infinity)

                        HStack {
                            Text("Font Size:")
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                                .frame(width: 80, alignment: .leading)
                            Slider(value: $fontSize, in: 25...75, step: 1)
                            Text("\(Int(fontSize))")
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                                .frame(width: 40)
                        }
                        .frame(maxWidth: .infinity)

                        HStack {
                            Text("Shortcut:")
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                                .frame(width: 80, alignment: .leading)
                            ShortcutRecorder(
                                keyCode: $shortcutKeyCode,
                                modifiers: $shortcutModifiers
                            ) {
                                ShortcutManager.shared.register()
                            }
                            .frame(maxWidth: .infinity)

                            Button("Reset") {
                                shortcutKeyCode = Int(defaultShortcutKeyCode)
                                shortcutModifiers = Int(defaultShortcutModifiers)
                                ShortcutManager.shared.register()
                            }
                            .font(.system(size: 11))
                        }
                        .frame(maxWidth: .infinity)
                        
                        Toggle("Remove special characters", isOn: $cleanWords)
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, textHorizontalPadding)
                    .padding(.vertical, 8)
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
            processText()
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
        .onChange(of: cleanWords) { _, _ in
            processText()
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
                    resumeCountdown()
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
        countdownProgress = 1.0
        cancelAutoDismiss()
        resumeCountdown()
    }
    
    func processText() {
        let initialWords = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if cleanWords {
            words = initialWords.map {
                $0.trimmingCharacters(in: .punctuationCharacters.union(.symbols))
            }.filter { !$0.isEmpty }
        } else {
            words = initialWords
        }
    }

    func resumeCountdown() {
        timer?.invalidate()
        let interval = 0.02
        let totalDuration = 3.0
        let decrement = interval / totalDuration

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
            if countdownProgress > 0 {
                countdownProgress -= decrement
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
        scheduleNextWord()
    }

    private func scheduleNextWord() {
        guard isPlaying, !words.isEmpty, currentIndex < words.count else { return }

        let delay = delayForWord(words[currentIndex])

        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            guard self.isPlaying else { return }

            if self.currentIndex < self.words.count - 1 {
                self.currentIndex += 1
                self.scheduleNextWord()
            } else {
                self.mode = .finished
                self.autoDismiss()
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

    func goBack1Word() {
        currentIndex = max(0, currentIndex - 1)
        if isPlaying {
            timer?.invalidate()
            scheduleNextWord()
        }
    }

    func goForward1Word() {
        if currentIndex < words.count - 1 {
            currentIndex += 1
            if isPlaying {
                timer?.invalidate()
                scheduleNextWord()
            }
        }
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
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)
        
        let maxDistanceFromORP = words.map { word -> CGFloat in
            let parts = splitWord(word)
            let beforeWidth = textWidth(parts.before, font: font)
            let orpCharWidth = textWidth(String(parts.orp), font: font)
            let afterWidth = textWidth(parts.after, font: font)
            
            let distanceToStart = beforeWidth + orpCharWidth / 2
            let distanceToEnd = orpCharWidth / 2 + afterWidth
            
            return max(distanceToStart, distanceToEnd)
        }.max() ?? 0
        
        // Since the ORP is centered, we need maxDistanceFromORP on both sides
        let paddedWidth =
            maxDistanceFromORP * 2
            + (contentHorizontalPadding * 2)
            + widthBuffer
        notchWidth = max(minWidth, paddedWidth)
    }

    // MARK: - ORP (Optimal Recognition Point) Helpers

    private func calculateORPIndex(for word: String) -> Int {
        let letters = word.drop(while: { !$0.isLetter && !$0.isNumber })
        let leadingPunctCount = word.count - letters.count
        let letterCount = letters.count

        let orpOffset: Int
        switch letterCount {
        case 0: return 0
        case 1...3: orpOffset = 0
        case 4...5: orpOffset = 1
        case 6...9: orpOffset = 2
        case 10...13: orpOffset = 3
        default: orpOffset = 4
        }

        return leadingPunctCount + orpOffset
    }

    private func splitWord(_ word: String) -> (before: String, orp: Character, after: String) {
        guard !word.isEmpty else { return ("", " ", "") }
        let index = calculateORPIndex(for: word)
        let safeIndex = min(index, word.count - 1)
        let wordIndex = word.index(word.startIndex, offsetBy: safeIndex)
        let before = String(word[word.startIndex..<wordIndex])
        let orp = word[wordIndex]
        let afterStartIndex = word.index(after: wordIndex)
        let after = afterStartIndex < word.endIndex ? String(word[afterStartIndex...]) : ""
        return (before, orp, after)
    }

    private func textWidth(_ string: String, font: NSFont) -> CGFloat {
        (string as NSString).size(withAttributes: [.font: font]).width
    }

    private func delayForWord(_ word: String) -> Double {
        let baseDelay = 60.0 / wpm
        var multiplier = 1.0

        if word.count >= 7 {
            multiplier = 1.5
        }

        if let lastChar = word.last {
            if ".!?".contains(lastChar) {
                multiplier = max(multiplier, 2.0)
            } else if ",;:".contains(lastChar) {
                multiplier = max(multiplier, 1.5)
            }
        }

        return baseDelay * multiplier
    }

    private var readingProgress: CGFloat {
        guard words.count > 1 else { return 1 }
        return CGFloat(currentIndex) / CGFloat(words.count - 1)
    }

    @ViewBuilder
    private func orpWordContent(word: String) -> some View {
        let parts = splitWord(word)
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)
        let beforeWidth = textWidth(parts.before, font: font)
        let orpCharWidth = textWidth(String(parts.orp), font: font)

        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let offsetX = centerX - beforeWidth - orpCharWidth / 2

            ZStack {
                // Vertical guide line at center — top tick and bottom tick
                VStack {
                    Rectangle()
                        .fill(accentColor.opacity(0.5))
                        .frame(width: 1.5, height: 10)
                    Spacer()
                    Rectangle()
                        .fill(accentColor.opacity(0.5))
                        .frame(width: 1.5, height: 10)
                }

                // Word with ORP highlighting
                HStack(spacing: 0) {
                    Text(parts.before)
                        .foregroundColor(.white)
                    Text(String(parts.orp))
                        .foregroundColor(accentColor)
                    Text(parts.after)
                        .foregroundColor(.white)
                }
                .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                .lineLimit(1)
                .fixedSize()
                .padding(.vertical, 12)
                .frame(width: geometry.size.width, alignment: .leading)
                .offset(x: offsetX)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
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
