import Cocoa
import Carbon

let defaultShortcutKeyCode: UInt16 = 0x0F
let defaultShortcutModifiers: UInt32 = UInt32(controlKey | shiftKey)

func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
    var result: UInt32 = 0
    if flags.contains(.command) {
        result |= UInt32(cmdKey)
    }
    if flags.contains(.shift) {
        result |= UInt32(shiftKey)
    }
    if flags.contains(.option) {
        result |= UInt32(optionKey)
    }
    if flags.contains(.control) {
        result |= UInt32(controlKey)
    }
    return result
}

func modifiersLabel(_ modifiers: UInt32) -> String {
    var parts: [String] = []
    if (modifiers & UInt32(controlKey)) != 0 {
        parts.append("Control")
    }
    if (modifiers & UInt32(optionKey)) != 0 {
        parts.append("Option")
    }
    if (modifiers & UInt32(shiftKey)) != 0 {
        parts.append("Shift")
    }
    if (modifiers & UInt32(cmdKey)) != 0 {
        parts.append("Command")
    }
    return parts.joined(separator: "+")
}

func keyCodeToString(_ keyCode: UInt16) -> String {
    guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue() else {
        return "Key \(keyCode)"
    }
    guard let layoutDataPtr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
        return "Key \(keyCode)"
    }
    let layoutData = unsafeBitCast(layoutDataPtr, to: CFData.self)
    let layout = unsafeBitCast(CFDataGetBytePtr(layoutData), to: UnsafePointer<UCKeyboardLayout>.self)

    var deadKeyState: UInt32 = 0
    let maxStringLength = 4
    var actualStringLength = 0
    var chars = [UniChar](repeating: 0, count: maxStringLength)

    let result = UCKeyTranslate(
        layout,
        keyCode,
        UInt16(kUCKeyActionDisplay),
        0,
        UInt32(LMGetKbdType()),
        UInt32(kUCKeyTranslateNoDeadKeysBit),
        &deadKeyState,
        maxStringLength,
        &actualStringLength,
        &chars
    )

    if result == noErr, actualStringLength > 0 {
        return String(utf16CodeUnits: chars, count: actualStringLength).uppercased()
    }

    return "Key \(keyCode)"
}

func shortcutLabel(keyCode: UInt16, modifiers: UInt32) -> String {
    let mods = modifiersLabel(modifiers)
    let key = keyCodeToString(keyCode)
    if mods.isEmpty {
        return key
    }
    return "\(mods)+\(key)"
}
