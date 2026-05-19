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

    let pasteboardTypes = pasteboard.types?.map(\.rawValue) ?? []

    guard !pasteboardContainsIgnoredType(pasteboardTypes) else {
      return
    }

    guard let payload = pasteboardPayload(types: pasteboardTypes) else {
      return
    }

    let source = currentSource()
    guard !isIgnored(source: source, payload: payload) else {
      return
    }

    store.recordItem(
      kind: payload.kind,
      content: payload.content,
      sourceApp: source.appName,
      sourceBundleIdentifier: source.bundleIdentifier,
      sourceProcessIdentifier: source.processIdentifier,
      pasteboardTypes: pasteboardTypes,
      fileURLs: payload.fileURLs,
      imageData: payload.imageData,
      imageContentType: payload.imageContentType,
      imagePixelWidth: payload.imagePixelWidth,
      imagePixelHeight: payload.imagePixelHeight
    )
  }

  private func pasteboardContainsIgnoredType(_ pasteboardTypes: [String]) -> Bool {
    let ignoredTypes = Set(preferences.ignoredPasteboardTypes.map { $0.lowercased() })

    guard !ignoredTypes.isEmpty else {
      return false
    }

    return pasteboardTypes.contains { type in
      ignoredTypes.contains(type.lowercased())
    }
  }

  private func pasteboardPayload(types: [String]) -> PasteboardPayload? {
    if let filePayload = filePayload(types: types) {
      return preferences.saveFiles ? filePayload : nil
    }

    if let imagePayload = imagePayload() {
      return preferences.saveImages ? imagePayload : nil
    }

    guard preferences.saveText else {
      return nil
    }

    guard
      let content = pasteboard.string(forType: .string),
      !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      return nil
    }

    return PasteboardPayload(kind: .text, content: content)
  }

  private func filePayload(types: [String]) -> PasteboardPayload? {
    let urls = pasteboard.readObjects(
      forClasses: [NSURL.self],
      options: [.urlReadingFileURLsOnly: true]
    ) as? [URL]

    let filePaths = (urls ?? [])
      .filter(\.isFileURL)
      .map(\.path)

    guard !filePaths.isEmpty else {
      return nil
    }

    let fileNames = filePaths.map { path in
      URL(fileURLWithPath: path).lastPathComponent
    }

    return PasteboardPayload(
      kind: .file,
      content: fileNames.joined(separator: "\n"),
      fileURLs: filePaths
    )
  }

  private func imagePayload() -> PasteboardPayload? {
    guard let image = NSImage(pasteboard: pasteboard) else {
      return nil
    }

    guard
      let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let imageData = bitmap.representation(using: .png, properties: [:])
    else {
      return nil
    }

    return PasteboardPayload(
      kind: .image,
      content: "Image",
      imageData: imageData,
      imageContentType: "public.png",
      imagePixelWidth: bitmap.pixelsWide,
      imagePixelHeight: bitmap.pixelsHigh
    )
  }

  private func currentSource() -> ClipboardSource {
    guard let app = NSWorkspace.shared.frontmostApplication else {
      return ClipboardSource()
    }

    return ClipboardSource(
      appName: app.localizedName,
      bundleIdentifier: app.bundleIdentifier,
      processIdentifier: Int(app.processIdentifier)
    )
  }

  private func isIgnored(source: ClipboardSource, payload: PasteboardPayload) -> Bool {
    if !isEnabled(payload.kind) {
      return true
    }

    let ignoredApps = preferences.ignoredApplications.map { $0.lowercased() }
    let sourceValues = [
      source.appName?.lowercased(),
      source.bundleIdentifier?.lowercased()
    ].compactMap { $0 }
    let appIsListed = sourceValues.contains { ignoredApps.contains($0) }

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

      let content = payload.contentForIgnoring
      let range = NSRange(location: 0, length: (content as NSString).length)
      return expression.firstMatch(in: content, options: [], range: range) != nil
    }
  }

  private func isEnabled(_ kind: ClipboardItemKind) -> Bool {
    switch kind {
    case .text:
      preferences.saveText
    case .file:
      preferences.saveFiles
    case .image:
      preferences.saveImages
    }
  }
}

private struct ClipboardSource {
  var appName: String?
  var bundleIdentifier: String?
  var processIdentifier: Int?
}

private struct PasteboardPayload {
  var kind: ClipboardItemKind
  var content: String
  var fileURLs: [String] = []
  var imageData: Data?
  var imageContentType: String?
  var imagePixelWidth: Int?
  var imagePixelHeight: Int?

  var contentForIgnoring: String {
    switch kind {
    case .text, .image:
      content
    case .file:
      (fileURLs + [content]).joined(separator: "\n")
    }
  }
}
