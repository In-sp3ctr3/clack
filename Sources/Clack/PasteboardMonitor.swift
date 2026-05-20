import AppKit
import ClackCore
import UniformTypeIdentifiers

@MainActor
final class PasteboardMonitor {
  private let pasteboard: NSPasteboard
  private let store: ClipboardHistoryStore
  private let preferences: ClackPreferences
  private let sourceTracker = ApplicationActivityTracker()
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
    MainActor.assumeIsolated {
      sourceTracker.stop()
    }
  }

  func start() {
    guard timer == nil else {
      return
    }

    sourceTracker.start()

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

    let observedAt = Date()
    let source = sourceTracker.source(at: observedAt)
    guard !isIgnored(source: source, payload: payload) else {
      return
    }

    store.recordItem(
      kind: payload.kind,
      content: payload.content,
      sourceApp: source.appName,
      sourceBundleIdentifier: source.bundleIdentifier,
      sourceProcessIdentifier: source.processIdentifier,
      sourceConfidence: source.confidence,
      sourceCapturedAt: source.capturedAt,
      pasteboardTypes: pasteboardTypes,
      fileURLs: payload.fileURLs,
      richTextRepresentations: payload.richTextRepresentations,
      imageData: payload.imageData,
      imageContentType: payload.imageContentType,
      imagePixelWidth: payload.imagePixelWidth,
      imagePixelHeight: payload.imagePixelHeight,
      at: observedAt
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

    if let richTextPayload = richTextPayload() {
      return preferences.saveText ? richTextPayload : nil
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
    let previewImage = preferences.saveImages ? imagePreview(for: filePaths) : nil

    return PasteboardPayload(
      kind: .file,
      content: fileNames.joined(separator: "\n"),
      fileURLs: filePaths,
      imageData: previewImage?.data,
      imageContentType: previewImage?.contentType,
      imagePixelWidth: previewImage?.pixelWidth,
      imagePixelHeight: previewImage?.pixelHeight
    )
  }

  private func imagePayload() -> PasteboardPayload? {
    guard let image = NSImage(pasteboard: pasteboard) else {
      return nil
    }

    guard let encodedImage = encodedPNG(from: image) else {
      return nil
    }

    return PasteboardPayload(
      kind: .image,
      content: "Image",
      imageData: encodedImage.data,
      imageContentType: encodedImage.contentType,
      imagePixelWidth: encodedImage.pixelWidth,
      imagePixelHeight: encodedImage.pixelHeight
    )
  }

  private func imagePreview(for filePaths: [String]) -> EncodedImage? {
    for filePath in filePaths {
      let url = URL(fileURLWithPath: filePath)

      guard isImageFile(url), let image = NSImage(contentsOf: url) else {
        continue
      }

      if let encodedImage = encodedPNG(from: image) {
        return encodedImage
      }
    }

    return nil
  }

  private func isImageFile(_ url: URL) -> Bool {
    guard
      let type = UTType(filenameExtension: url.pathExtension),
      type.conforms(to: .image)
    else {
      return false
    }

    return true
  }

  private func encodedPNG(from image: NSImage) -> EncodedImage? {
    guard
      let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let imageData = bitmap.representation(using: .png, properties: [:])
    else {
      return nil
    }

    return EncodedImage(
      data: imageData,
      contentType: "public.png",
      pixelWidth: bitmap.pixelsWide,
      pixelHeight: bitmap.pixelsHigh
    )
  }

  private func richTextPayload() -> PasteboardPayload? {
    let representations = richTextPasteboardTypes.compactMap { type -> ClipboardDataRepresentation? in
      guard let data = pasteboard.data(forType: type), !data.isEmpty else {
        return nil
      }

      return ClipboardDataRepresentation(type: type.rawValue, data: data)
    }

    guard !representations.isEmpty else {
      return nil
    }

    let content = pasteboard.string(forType: .string)
      ?? plainText(from: representations)
      ?? ""

    guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return nil
    }

    return PasteboardPayload(
      kind: .richText,
      content: content,
      richTextRepresentations: representations
    )
  }

  private func plainText(from representations: [ClipboardDataRepresentation]) -> String? {
    for representation in representations {
      guard let documentType = attributedStringDocumentType(for: representation.type) else {
        continue
      }

      let attributedString = try? NSAttributedString(
        data: representation.data,
        options: [.documentType: documentType],
        documentAttributes: nil
      )

      if
        let string = attributedString?.string,
        !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      {
        return string
      }
    }

    return nil
  }

  private func attributedStringDocumentType(for pasteboardType: String) -> NSAttributedString.DocumentType? {
    switch pasteboardType {
    case NSPasteboard.PasteboardType.rtf.rawValue:
      .rtf
    case NSPasteboard.PasteboardType.rtfd.rawValue:
      .rtfd
    case NSPasteboard.PasteboardType.html.rawValue:
      .html
    default:
      nil
    }
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
    case .text, .richText:
      preferences.saveText
    case .file:
      preferences.saveFiles
    case .image:
      preferences.saveImages
    }
  }
}

@MainActor
private final class ApplicationActivityTracker {
  private let workspace: NSWorkspace
  private var observer: NSObjectProtocol?
  private var lastApplication: NSRunningApplication?
  private var lastActivationDate: Date?

  init(workspace: NSWorkspace = .shared) {
    self.workspace = workspace
  }

  deinit {
    MainActor.assumeIsolated {
      stop()
    }
  }

  func start() {
    guard observer == nil else {
      return
    }

    remember(workspace.frontmostApplication, at: Date())

    observer = workspace.notificationCenter.addObserver(
      forName: NSWorkspace.didActivateApplicationNotification,
      object: workspace,
      queue: .main
    ) { [weak self] notification in
      guard
        let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
      else {
        return
      }

      Task { @MainActor in
        self?.remember(app, at: Date())
      }
    }
  }

  func stop() {
    guard let observer else {
      return
    }

    workspace.notificationCenter.removeObserver(observer)
    self.observer = nil
  }

  func source(at date: Date) -> ClipboardSource {
    if let app = workspace.frontmostApplication {
      remember(app, at: date)
      return ClipboardSource(
        appName: app.localizedName,
        bundleIdentifier: app.bundleIdentifier,
        processIdentifier: Int(app.processIdentifier),
        confidence: .frontmostApplication,
        capturedAt: date
      )
    }

    if
      let lastApplication,
      let lastActivationDate,
      date.timeIntervalSince(lastActivationDate) <= 10
    {
      return ClipboardSource(
        appName: lastApplication.localizedName,
        bundleIdentifier: lastApplication.bundleIdentifier,
        processIdentifier: Int(lastApplication.processIdentifier),
        confidence: .recentApplication,
        capturedAt: lastActivationDate
      )
    }

    return ClipboardSource(
      confidence: .unknown,
      capturedAt: date
    )
  }

  private func remember(_ app: NSRunningApplication?, at date: Date) {
    guard let app else {
      return
    }

    lastApplication = app
    lastActivationDate = date
  }
}

private struct ClipboardSource {
  var appName: String?
  var bundleIdentifier: String?
  var processIdentifier: Int?
  var confidence: ClipboardSourceConfidence = .unknown
  var capturedAt: Date?
}

private struct PasteboardPayload {
  var kind: ClipboardItemKind
  var content: String
  var fileURLs: [String] = []
  var richTextRepresentations: [ClipboardDataRepresentation] = []
  var imageData: Data?
  var imageContentType: String?
  var imagePixelWidth: Int?
  var imagePixelHeight: Int?

  var contentForIgnoring: String {
    switch kind {
    case .text, .richText, .image:
      content
    case .file:
      (fileURLs + [content]).joined(separator: "\n")
    }
  }
}

private struct EncodedImage {
  var data: Data
  var contentType: String
  var pixelWidth: Int
  var pixelHeight: Int
}

private let richTextPasteboardTypes: [NSPasteboard.PasteboardType] = [
  .rtf,
  .rtfd,
  .html
]
