# Changelog

All notable changes to this project will be documented in this file.

The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-02-12

### Added
- **Automatic Update Checker**: New `UpdateChecker` class that queries GitHub
  API for latest releases
- **Update Menu Option**: "Check for Updates" menu item in status bar for manual
  update checks
- **Silent Background Updates**: Automatic update checking on app launch without
  user notification
- **Version Comparison**: Intelligent version comparison logic to detect newer
  releases
- **Update Alerts**: User-friendly alerts for available updates and current
  version status
- **Read Clipboard Feature**: New "Read Clipboard" menu item to quickly read
  text from your clipboard without needing to select it first
- **RSVP Word Display with ORP**: Words are now displayed with Optimal
  Recognition Point highlighting — the ORP letter is shown in red and aligned to
  a fixed vertical guide line so the reader's eyes never move
- **Smart Timing**: Word display duration now adapts based on word length (1.5×
  for 7+ chars) and punctuation (2× for sentence endings, 1.5× for clauses)
- **Reading Progress Bar**: A red progress bar below the word shows reading
  progress through the text
- **Prev/Next Word Controls**: Navigate forward or backward one word at a time
  during reading

### Changed
- Replaced number countdown with a progress bar animation behind the first word
- Switched to monospaced bold font for consistent character-width alignment
- Updated notch width calculation to account for ORP-centered word positioning
- Enhanced startup routine in `AppDelegate` to include silent update checks

## [1.0.0] - 2026-02-11

### Added
- **Speed Reading Feature**: Display text one word at a time with adjustable
  words-per-minute (WPM) settings
- **Global Shortcut Support**: Press `Control + Shift + R` to instantly read any
  selected text
- **Notch Integration**: Native integration with MacBook notch for unobtrusive
  reading experience
- **Customizable Settings**: Adjust reading speed, font size, and appearance
  preferences
- **Status Bar Menu**: Quick access to reading features and settings from the
  menu bar
- **Playback Controls**:
  - Space bar to pause/resume reading
  - Escape key to stop reading
  - Visual countdown display before reading starts
  - Reading completion notifications
- **Global Event Listener**: Detect and respond to global shortcuts without
  requiring app focus

[1.0.0]: https://github.com/estruyf/speedreadnotch/releases/tag/v1.0.0
