import AppKit
import ClackCore

@MainActor
final class PasteboardMonitor {
  private let pasteboard: NSPasteboard
  private let store: ClipboardHistoryStore
  private var timer: Timer?
  private var lastChangeCount: Int
  private var ignoredChangeCount: Int?

  init(
    store: ClipboardHistoryStore,
    pasteboard: NSPasteboard = .general
  ) {
    self.store = store
    self.pasteboard = pasteboard
    self.lastChangeCount = pasteboard.changeCount
  }

  deinit {
    timer?.invalidate()
  }

  func start() {
    guard timer == nil else {
      return
    }

    let timer = Timer(timeInterval: 0.55, repeats: true) { [weak self] _ in
      Task { @MainActor in
        self?.poll()
      }
    }

    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  func ignoreChange(count: Int) {
    ignoredChangeCount = count
    lastChangeCount = count
  }

  private func poll() {
    let currentChangeCount = pasteboard.changeCount

    guard currentChangeCount != lastChangeCount else {
      return
    }

    lastChangeCount = currentChangeCount

    if ignoredChangeCount == currentChangeCount {
      ignoredChangeCount = nil
      return
    }

    guard
      let content = pasteboard.string(forType: .string),
      !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      return
    }

    let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName
    store.recordCopy(content, sourceApp: sourceApp)
  }
}
