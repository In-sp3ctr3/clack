import AppKit

@MainActor
enum PasteExecutor {
  static func pasteAfterMenuCloses() {
    Task { @MainActor in
      try? await Task.sleep(nanoseconds: 140_000_000)
      paste()
    }
  }

  private static func paste() {
    guard
      let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true),
      let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: false)
    else {
      return
    }

    keyDown.flags = .maskCommand
    keyUp.flags = .maskCommand
    keyDown.post(tap: .cghidEventTap)
    keyUp.post(tap: .cghidEventTap)
  }
}
