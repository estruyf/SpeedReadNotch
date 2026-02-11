import Carbon
import Cocoa

class ShortcutManager {
    static let shared = ShortcutManager()

    private var hotKeyRef: EventHotKeyRef?

    // Store the handler reference to keep it alive
    private var eventHandler: EventHandlerRef?

    func register() {
        // Define the event type for hotkey press
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        if eventHandler == nil {
            // Create a non-capturing handler using a static function
            let handler: EventHandlerUPP = { _, _, _ -> OSStatus in
                // Use the shared instance to handle the shortcut
                DispatchQueue.main.async {
                    ShortcutManager.shared.handleShortcut()
                }
                return noErr
            }

            InstallEventHandler(
                GetApplicationEventTarget(), handler, 1, &eventType, nil, &eventHandler)
        }

        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        // Register configured shortcut
        let rKey = currentKeyCode()
        let modifiers = currentModifiers()

        let hotKeyID = EventHotKeyID(signature: OSType(0x1111), id: 1)

        RegisterEventHotKey(rKey, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        let label = shortcutLabel(keyCode: UInt16(rKey), modifiers: modifiers)
        print("Global Shortcut \(label) registered")
    }

    private func currentModifiers() -> UInt32 {
        let storedModifiers = UserDefaults.standard.integer(forKey: "shortcutModifiers")
        if storedModifiers == 0 {
            return defaultShortcutModifiers
        }
        return UInt32(storedModifiers)
    }

    private func currentKeyCode() -> UInt32 {
        let storedKeyCode = UserDefaults.standard.integer(forKey: "shortcutKeyCode")
        if storedKeyCode == 0 {
            return UInt32(defaultShortcutKeyCode)
        }
        return UInt32(storedKeyCode)
    }

    private func handleShortcut() {
        // Copy selected text from frontmost app
        copySelectedText()

        // Give the copy operation a moment to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Trigger the reading with auto-start
            NotchWindowController.shared.toggleAndRead()
        }
    }

    private func copySelectedText() {
        // Create a keyboard event to send Cmd+C to the frontmost app
        let source = CGEventSource(stateID: .hidSystemState)

        // Create key down event for 'C' key
        let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true)
        keyDownEvent?.flags = .maskCommand

        // Create key up event for 'C' key
        let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false)
        keyUpEvent?.flags = .maskCommand

        // Post the events to copy selected text
        keyDownEvent?.post(tap: .cghidEventTap)
        keyUpEvent?.post(tap: .cghidEventTap)
    }
}
