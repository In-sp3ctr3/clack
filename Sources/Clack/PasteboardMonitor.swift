import AppKit
import ClackCore

@MainActor
final class PasteboardMonitor {
  private let pasteboard: NSPasteboard
  private let store: ClipboardHistoryStore
  private let preferences: ClackPreferences
  private var timer: Timer?
  private var lastChangeCount: Int
  private var ignoredChangeCount: Int?

  init(
    store: ClipboardHistoryStore,
    preferences: ClackPreferences,
    pasteboard: NSPasteboard = .general
  ) {
    self.store = store
    self.preferences = preferences
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
    preferences.refreshRuntimeControls()

    guard !preferences.temporarilyIgnoreNewCopies else {
      return
    }

    if preferences.ignoreOnlyNextCopy {
      preferences.ignoreOnlyNextCopy = false
      return
    }

    if ignoredChangeCount == currentChangeCount {
      ignoredChangeCount = nil
      return
    }

    guard !pasteboardContainsIgnoredType() else {
      return
    }

    guard
      let content = pasteboard.string(forType: .string),
      !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      return
    }

    let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName
    guard !isIgnored(sourceApp: sourceApp, content: content) else {
      return
    }

    store.recordCopy(content, sourceApp: sourceApp)
  }

  private func pasteboardContainsIgnoredType() -> Bool {
    let ignoredTypes = Set(preferences.ignoredPasteboardTypes.map { $0.lowercased() })

    guard !ignoredTypes.isEmpty else {
      return false
    }

    return pasteboard.types?.contains { type in
      ignoredTypes.contains(type.rawValue.lowercased())
    } ?? false
  }

  private func isIgnored(sourceApp: String?, content: String) -> Bool {
    if !preferences.saveText {
      return true
    }

    let ignoredApps = preferences.ignoredApplications.map { $0.lowercased() }
    let normalizedSourceApp = sourceApp?.lowercased()
    let appIsListed = normalizedSourceApp.map { ignoredApps.contains($0) } ?? false

    if preferences.ignoreAllApplicationsExceptListed {
      guard appIsListed else {
        return true
      }
    } else if appIsListed {
      return true
    }

    return preferences.ignoredRegularExpressions.contains { pattern in
      guard let expression = try? NSRegularExpression(pattern: pattern) else {
        return false
      }

      let range = NSRange(location: 0, length: (content as NSString).length)
      return expression.firstMatch(in: content, options: [], range: range) != nil
    }
  }
}
