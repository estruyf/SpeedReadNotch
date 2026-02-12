import SwiftUI

@main
struct SpeedReadNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Register global shortcut
        ShortcutManager.shared.register()
        
        // Setup status bar menu
        StatusBarManager.shared.setupStatusBar()
        
        // Silent update check on launch
        UpdateChecker.shared.checkForUpdates(silent: true)
    }
}
