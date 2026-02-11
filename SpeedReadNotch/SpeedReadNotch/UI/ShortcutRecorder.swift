import AppKit
import SwiftUI

struct ShortcutRecorder: View {
  @Binding var keyCode: Int
  @Binding var modifiers: Int
  var onChange: () -> Void

  @State private var isRecording = false
  @State private var eventMonitor: Any?

  var body: some View {
    Button(action: startRecording) {
      Text(
        isRecording
          ? "Type Shortcut..."
          : shortcutLabel(keyCode: UInt16(keyCode), modifiers: UInt32(modifiers))
      )
      .font(.system(size: 11, weight: .medium))
      .frame(maxWidth: .infinity)
    }
    .buttonStyle(.bordered)
    .onDisappear {
      stopRecording()
    }
  }

  private func startRecording() {
    if isRecording {
      return
    }
    isRecording = true
    eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
      if isModifierOnlyKey(event.keyCode) {
        return event
      }
      let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
      let newModifiers = carbonModifiers(from: flags)
      keyCode = Int(event.keyCode)
      modifiers = Int(newModifiers)
      isRecording = false
      stopRecording()
      onChange()
      return nil
    }
  }

  private func stopRecording() {
    if let eventMonitor {
      NSEvent.removeMonitor(eventMonitor)
      self.eventMonitor = nil
    }
  }

  private func isModifierOnlyKey(_ keyCode: UInt16) -> Bool {
    let modifierKeyCodes: Set<UInt16> = [0x38, 0x3B, 0x3A, 0x37, 0x3C, 0x3D, 0x3E]
    return modifierKeyCodes.contains(keyCode)
  }
}
