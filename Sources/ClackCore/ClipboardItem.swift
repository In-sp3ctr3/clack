import Foundation

public enum ClipboardItemKind: String, Codable, CaseIterable, Hashable, Identifiable {
  case text = "Text"
  case richText = "Formatted Text"
  case file = "File"
  case image = "Image"

  public var id: String { rawValue }
}

public enum ClipboardSourceConfidence: String, Codable, CaseIterable, Hashable, Identifiable {
  case frontmostApplication = "Frontmost app"
  case recentApplication = "Recently active app"
  case unknown = "Unknown"

  public var id: String { rawValue }
}

public struct ClipboardDataRepresentation: Codable, Hashable {
  public var type: String
  public var data: Data

  public init(type: String, data: Data) {
    self.type = type.trimmingCharacters(in: .whitespacesAndNewlines)
    self.data = data
  }
}

public struct ClipboardItem: Codable, Hashable, Identifiable {
  public let id: UUID
  public var kind: ClipboardItemKind
  public var content: String
  public var sourceApp: String?
  public var sourceBundleIdentifier: String?
  public var sourceProcessIdentifier: Int?
  public var sourceConfidence: ClipboardSourceConfidence
  public var sourceCapturedAt: Date?
  public var firstCopiedAt: Date
  public var lastCopiedAt: Date
  public var copyCount: Int
  public var isPinned: Bool
  public var pasteboardTypes: [String]
  public var fileURLs: [String]
  public var richTextRepresentations: [ClipboardDataRepresentation]
  public var imageData: Data?
  public var imageContentType: String?
  public var imagePixelWidth: Int?
  public var imagePixelHeight: Int?

  public init(
    id: UUID = UUID(),
    kind: ClipboardItemKind = .text,
    content: String,
    sourceApp: String? = nil,
    sourceBundleIdentifier: String? = nil,
    sourceProcessIdentifier: Int? = nil,
    sourceConfidence: ClipboardSourceConfidence = .unknown,
    sourceCapturedAt: Date? = nil,
    firstCopiedAt: Date,
    lastCopiedAt: Date,
    copyCount: Int = 1,
    isPinned: Bool = false,
    pasteboardTypes: [String] = [],
    fileURLs: [String] = [],
    richTextRepresentations: [ClipboardDataRepresentation] = [],
    imageData: Data? = nil,
    imageContentType: String? = nil,
    imagePixelWidth: Int? = nil,
    imagePixelHeight: Int? = nil
  ) {
    self.id = id
    self.kind = kind
    self.content = content
    self.sourceApp = sourceApp
    self.sourceBundleIdentifier = sourceBundleIdentifier
    self.sourceProcessIdentifier = sourceProcessIdentifier
    self.sourceConfidence = sourceConfidence
    self.sourceCapturedAt = sourceCapturedAt
    self.firstCopiedAt = firstCopiedAt
    self.lastCopiedAt = lastCopiedAt
    self.copyCount = max(1, copyCount)
    self.isPinned = isPinned
    self.pasteboardTypes = Self.uniqueValues(pasteboardTypes)
    self.fileURLs = Self.uniqueValues(fileURLs)
    self.richTextRepresentations = Self.uniqueRepresentations(richTextRepresentations)
    self.imageData = imageData
    self.imageContentType = imageContentType
    self.imagePixelWidth = imagePixelWidth
    self.imagePixelHeight = imagePixelHeight
  }

  public var hasStorablePayload: Bool {
    switch kind {
    case .text:
      !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    case .richText:
      !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !richTextRepresentations.isEmpty
    case .file:
      !fileURLs.isEmpty
    case .image:
      imageData?.isEmpty == false
    }
  }

  public var preview: String {
    let source = switch kind {
    case .text, .richText:
      content
    case .file:
      filePreview
    case .image:
      imagePreview
    }

    let collapsed = source
      .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
      .trimmingCharacters(in: .whitespacesAndNewlines)

    guard collapsed.count > 140 else {
      return collapsed
    }

    return String(collapsed.prefix(137)) + "..."
  }

  public var detailText: String {
    switch kind {
    case .text, .richText:
      content
    case .file:
      fileURLs.joined(separator: "\n")
    case .image:
      imagePreview
    }
  }

  public var characterCount: Int {
    content.count
  }

  public var byteCount: Int {
    switch kind {
    case .text:
      content.data(using: .utf8)?.count ?? 0
    case .richText:
      richTextRepresentations.reduce(content.data(using: .utf8)?.count ?? 0) { result, representation in
        result + representation.data.count
      }
    case .file:
      fileURLs.joined(separator: "\n").data(using: .utf8)?.count ?? 0
    case .image:
      imageData?.count ?? 0
    }
  }

  public var sourceDescription: String {
    sourceApp ?? "Unknown source"
  }

  public var sourceConfidenceDescription: String {
    sourceConfidence.rawValue
  }

  public var richTextTypeDescription: String? {
    guard !richTextRepresentations.isEmpty else {
      return nil
    }

    return richTextRepresentations.map(\.type).joined(separator: ", ")
  }

  public var imageSizeDescription: String? {
    guard let imagePixelWidth, let imagePixelHeight else {
      return nil
    }

    return "\(imagePixelWidth)x\(imagePixelHeight)"
  }

  public func representsSameClipboardPayload(as other: ClipboardItem) -> Bool {
    guard kind == other.kind else {
      return false
    }

    switch kind {
    case .text:
      return content == other.content
    case .richText:
      return content == other.content && richTextRepresentations == other.richTextRepresentations
    case .file:
      return fileURLs == other.fileURLs
    case .image:
      return imageData == other.imageData
    }
  }

  public func matches(_ query: String, mode: SearchMode = .contains) -> Bool {
    let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !cleanedQuery.isEmpty else {
      return true
    }

    let options: String.CompareOptions = switch mode {
    case .contains:
      [.caseInsensitive, .diacriticInsensitive]
    case .exact:
      []
    }

    let searchableValues = [
      kind.rawValue,
      content,
      detailText,
      sourceApp,
      sourceBundleIdentifier,
      sourceConfidence.rawValue,
      pasteboardTypes.joined(separator: " ")
    ].compactMap(\.self)

    if searchableValues.contains(where: { $0.range(of: cleanedQuery, options: options) != nil }) {
      return true
    }

    return false
  }

  private var filePreview: String {
    guard !fileURLs.isEmpty else {
      return content
    }

    let fileNames = fileURLs.map { fileURL in
      URL(fileURLWithPath: fileURL).lastPathComponent
    }

    guard fileNames.count > 1 else {
      return fileNames.first ?? content
    }

    return "\(fileNames.count) files: \(fileNames.prefix(3).joined(separator: ", "))"
  }

  private var imagePreview: String {
    let base = content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Image" : content

    guard let imageSizeDescription else {
      return base
    }

    return "\(base) (\(imageSizeDescription))"
  }

  private static func uniqueValues(_ values: [String]) -> [String] {
    var result: [String] = []

    for value in values {
      let cleanedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !cleanedValue.isEmpty, !result.contains(cleanedValue) else {
        continue
      }

      result.append(cleanedValue)
    }

    return result
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case kind
    case content
    case sourceApp
    case sourceBundleIdentifier
    case sourceProcessIdentifier
    case sourceConfidence
    case sourceCapturedAt
    case firstCopiedAt
    case lastCopiedAt
    case copyCount
    case isPinned
    case pasteboardTypes
    case fileURLs
    case richTextRepresentations
    case imageData
    case imageContentType
    case imagePixelWidth
    case imagePixelHeight
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
    self.kind = try container.decodeIfPresent(ClipboardItemKind.self, forKey: .kind) ?? .text
    self.content = try container.decode(String.self, forKey: .content)
    self.sourceApp = try container.decodeIfPresent(String.self, forKey: .sourceApp)
    self.sourceBundleIdentifier = try container.decodeIfPresent(String.self, forKey: .sourceBundleIdentifier)
    self.sourceProcessIdentifier = try container.decodeIfPresent(Int.self, forKey: .sourceProcessIdentifier)
    self.sourceConfidence = try container.decodeIfPresent(
      ClipboardSourceConfidence.self,
      forKey: .sourceConfidence
    ) ?? (sourceApp == nil ? .unknown : .frontmostApplication)
    self.sourceCapturedAt = try container.decodeIfPresent(Date.self, forKey: .sourceCapturedAt)
    self.firstCopiedAt = try container.decode(Date.self, forKey: .firstCopiedAt)
    self.lastCopiedAt = try container.decode(Date.self, forKey: .lastCopiedAt)
    self.copyCount = max(1, try container.decodeIfPresent(Int.self, forKey: .copyCount) ?? 1)
    self.isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    self.pasteboardTypes = Self.uniqueValues(try container.decodeIfPresent([String].self, forKey: .pasteboardTypes) ?? [])
    self.fileURLs = Self.uniqueValues(try container.decodeIfPresent([String].self, forKey: .fileURLs) ?? [])
    self.richTextRepresentations = Self.uniqueRepresentations(
      try container.decodeIfPresent([ClipboardDataRepresentation].self, forKey: .richTextRepresentations) ?? []
    )
    self.imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
    self.imageContentType = try container.decodeIfPresent(String.self, forKey: .imageContentType)
    self.imagePixelWidth = try container.decodeIfPresent(Int.self, forKey: .imagePixelWidth)
    self.imagePixelHeight = try container.decodeIfPresent(Int.self, forKey: .imagePixelHeight)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(kind, forKey: .kind)
    try container.encode(content, forKey: .content)
    try container.encodeIfPresent(sourceApp, forKey: .sourceApp)
    try container.encodeIfPresent(sourceBundleIdentifier, forKey: .sourceBundleIdentifier)
    try container.encodeIfPresent(sourceProcessIdentifier, forKey: .sourceProcessIdentifier)
    try container.encode(sourceConfidence, forKey: .sourceConfidence)
    try container.encodeIfPresent(sourceCapturedAt, forKey: .sourceCapturedAt)
    try container.encode(firstCopiedAt, forKey: .firstCopiedAt)
    try container.encode(lastCopiedAt, forKey: .lastCopiedAt)
    try container.encode(copyCount, forKey: .copyCount)
    try container.encode(isPinned, forKey: .isPinned)
    try container.encode(pasteboardTypes, forKey: .pasteboardTypes)
    try container.encode(fileURLs, forKey: .fileURLs)
    try container.encode(richTextRepresentations, forKey: .richTextRepresentations)
    try container.encodeIfPresent(imageData, forKey: .imageData)
    try container.encodeIfPresent(imageContentType, forKey: .imageContentType)
    try container.encodeIfPresent(imagePixelWidth, forKey: .imagePixelWidth)
    try container.encodeIfPresent(imagePixelHeight, forKey: .imagePixelHeight)
  }

  private static func uniqueRepresentations(
    _ representations: [ClipboardDataRepresentation]
  ) -> [ClipboardDataRepresentation] {
    var result: [ClipboardDataRepresentation] = []

    for representation in representations {
      guard !representation.type.isEmpty, !representation.data.isEmpty else {
        continue
      }

      if let index = result.firstIndex(where: { $0.type == representation.type }) {
        result[index] = representation
      } else {
        result.append(representation)
      }
    }

    return result
  }
}
