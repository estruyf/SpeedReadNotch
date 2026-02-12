import Cocoa
import ServiceManagement

class StatusBarManager: NSObject {
    static let shared = StatusBarManager()

    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    private var startAtLoginItem: NSMenuItem?

    func setupStatusBar() {
        // Create status bar item
        let statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)

        // Set the button icon
        if let button = statusItem?.button {
            if let image = NSImage(named: NSImage.Name("TrayIcon")) {
                image.size = NSSize(width: 18, height: 18)
                image.isTemplate = true
                button.image = image
            } else {
                // Fallback to emoji if image not found
                button.title = "📖"
            }
        }

        // Create menu
        menu = NSMenu()
        menu?.addItem(
            NSMenuItem(title: "Run sample", action: #selector(runTest), keyEquivalent: ""))
        menu?.addItem(
            NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ""))
        let startItem = NSMenuItem(
            title: "Start at Login", action: #selector(toggleStartAtLogin), keyEquivalent: "")
        startAtLoginItem = startItem
        menu?.addItem(startItem)
        menu?.addItem(NSMenuItem.separator())
        let appVersion =
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let versionItem = NSMenuItem(title: "Version \(appVersion)", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        menu?.addItem(versionItem)
        menu?.addItem(
            NSMenuItem(title: "Check for Updates", action: #selector(checkForUpdates), keyEquivalent: ""))
        menu?.addItem(NSMenuItem.separator())
        menu?.addItem(
            NSMenuItem(title: "Support me ❤️", action: #selector(openSupport), keyEquivalent: ""))
        menu?.addItem(NSMenuItem.separator())
        menu?.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: ""))

        // Set menu target
        for item in menu?.items ?? [] {
            item.target = self
        }

        // Attach menu to status item
        statusItem?.menu = menu

        updateStartAtLoginItemState()
    }

    @objc private func toggleStartAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                } else {
                    try SMAppService.mainApp.register()
                }
            } catch {
                NSLog("Failed to toggle start at login: \(error)")
            }
        }
        updateStartAtLoginItemState()
    }

    private func updateStartAtLoginItemState() {
        if #available(macOS 13.0, *) {
            startAtLoginItem?.state = SMAppService.mainApp.status == .enabled ? .on : .off
        } else {
            startAtLoginItem?.state = .off
            startAtLoginItem?.isEnabled = false
        }
    }

    @objc private func runTest() {
        // Sample text for testing
        let sampleText = """
            This is a test of the SpeedRead Notch application. \
            You can use Control+Shift+R to quickly read any selected text. The app displays one word at a time \
            at your configured words per minute speed. You can pause, restart, adjust speed and font size. \
            This makes speed reading accessible and efficient right from your notch.
            """

        // Show the notch with sample text
        NotchWindowController.shared.show(text: sampleText)
    }

    @objc private func openSettings() {
        NotchWindowController.shared.showSettings()
    }

    @objc private func checkForUpdates() {
        UpdateChecker.shared.checkForUpdates(silent: false)
    }

    @objc private func openSupport() {
        guard let url = URL(string: "https://github.com/sponsors/estruyf") else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
