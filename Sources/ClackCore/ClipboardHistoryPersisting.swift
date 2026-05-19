import Foundation

public protocol ClipboardHistoryPersisting {
  func load() throws -> [ClipboardItem]
  func save(_ items: [ClipboardItem]) throws
}

public final class InMemoryHistoryPersistence: ClipboardHistoryPersisting {
  private var loadedItems: [ClipboardItem]

  public private(set) var savedItems: [ClipboardItem]

  public init(items: [ClipboardItem] = []) {
    self.loadedItems = items
    self.savedItems = items
  }

  public func load() throws -> [ClipboardItem] {
    loadedItems
  }

  public func save(_ items: [ClipboardItem]) throws {
    savedItems = items
    loadedItems = items
  }
}

public struct JSONHistoryPersistence: ClipboardHistoryPersisting {
  public let fileURL: URL
  private let fileManager: FileManager

  public init(
    fileURL: URL = JSONHistoryPersistence.defaultFileURL(),
    fileManager: FileManager = .default
  ) {
    self.fileURL = fileURL
    self.fileManager = fileManager
  }

  public static func defaultFileURL(fileManager: FileManager = .default) -> URL {
    let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
      .first ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")

    return baseURL
      .appendingPathComponent("Clack", isDirectory: true)
      .appendingPathComponent("history.json")
  }

  public func load() throws -> [ClipboardItem] {
    guard fileManager.fileExists(atPath: fileURL.path) else {
      return []
    }

    let data = try Data(contentsOf: fileURL)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode([ClipboardItem].self, from: data)
  }

  public func save(_ items: [ClipboardItem]) throws {
    let directoryURL = fileURL.deletingLastPathComponent()
    try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    let data = try encoder.encode(items)
    try data.write(to: fileURL, options: [.atomic])
  }
}
