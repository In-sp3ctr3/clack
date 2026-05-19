import Foundation

public struct ClipboardItem: Codable, Hashable, Identifiable {
  public let id: UUID
  public var content: String
  public var sourceApp: String?
  public var firstCopiedAt: Date
  public var lastCopiedAt: Date
  public var copyCount: Int
  public var isPinned: Bool

  public init(
    id: UUID = UUID(),
    content: String,
    sourceApp: String? = nil,
    firstCopiedAt: Date,
    lastCopiedAt: Date,
    copyCount: Int = 1,
    isPinned: Bool = false
  ) {
    self.id = id
    self.content = content
    self.sourceApp = sourceApp
    self.firstCopiedAt = firstCopiedAt
    self.lastCopiedAt = lastCopiedAt
    self.copyCount = max(1, copyCount)
    self.isPinned = isPinned
  }

  public var preview: String {
    let collapsed = content
      .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
      .trimmingCharacters(in: .whitespacesAndNewlines)

    guard collapsed.count > 140 else {
      return collapsed
    }

    return String(collapsed.prefix(137)) + "..."
  }

  public var characterCount: Int {
    content.count
  }

  public var byteCount: Int {
    content.data(using: .utf8)?.count ?? 0
  }

  public func matches(_ query: String) -> Bool {
    let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !cleanedQuery.isEmpty else {
      return true
    }

    let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

    if content.range(of: cleanedQuery, options: options) != nil {
      return true
    }

    return sourceApp?.range(of: cleanedQuery, options: options) != nil
  }
}
