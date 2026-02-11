import SwiftUI

struct SettingsView: View {
    @AppStorage("wpm") private var wpm: Double = 300
    @AppStorage("fontSize") private var fontSize: Double = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SpeedRead Notch Settings")
                .font(.headline)

            HStack {
                Text("Speed (WPM)")
                Slider(value: $wpm, in: 100...1000, step: 25)
                Text("\(Int(wpm))")
                    .frame(width: 50, alignment: .trailing)
            }

            HStack {
                Text("Font Size")
                Slider(value: $fontSize, in: 25...75, step: 1)
                Text("\(Int(fontSize))")
                    .frame(width: 50, alignment: .trailing)
            }

            Spacer()
        }
        .padding(20)
        .frame(minWidth: 450, minHeight: 200)
    }
}
