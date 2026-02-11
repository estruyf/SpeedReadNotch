import Cocoa
import Carbon

class ShortcutManager {
    static let shared = ShortcutManager()
    
    private var hotKeyRef: EventHotKeyRef?
    
    // Store the handler reference to keep it alive
    private var eventHandler: EventHandlerRef?
    
    func register() {
        // Define the event type for hotkey press
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        // Create a non-capturing handler using a static function
        let handler: EventHandlerUPP = { _, _, _ -> OSStatus in
            // Use the shared instance to handle the shortcut
            DispatchQueue.main.async {
                ShortcutManager.shared.handleShortcut()
            }
            return noErr
        }
        
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, &eventHandler)
        
        // Register Command + Shift + R
        // kVK_ANSI_R is 0x0F (15)
        let rKey: UInt32 = 0x0F 
        // cmdKey (256) + shiftKey (512)
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        
        let hotKeyID = EventHotKeyID(signature: OSType(0x1111), id: 1)
        
        RegisterEventHotKey(rKey, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        print("Global Shortcut Command+Shift+R registered")
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
