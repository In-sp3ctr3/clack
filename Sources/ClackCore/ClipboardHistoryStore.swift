import Combine
import Foundation

@MainActor
public final class ClipboardHistoryStore: ObservableObject {
  nonisolated public static let defaultLimit = 500
  nonisolated public static let minimumLimit = 1
  nonisolated public static let maximumLimit = 5_000

  @Published public private(set) var items: [ClipboardItem]
  @Published public var searchText = ""
  @Published public private(set) var lastPersistenceError: String?

  public private(set) var maxStoredItems: Int

  private let persistence: ClipboardHistoryPersisting?

  public init(
    maxStoredItems: Int = ClipboardHistoryStore.defaultLimit,
    persistence: ClipboardHistoryPersisting? = nil,
    loadSavedItems: Bool = true
  ) {
    self.maxStoredItems = Self.clampedLimit(maxStoredItems)
    self.persistence = persistence

    if loadSavedItems, let persistence {
      do {
        self.items = try persistence.load()
      } catch {
        self.items = []
        self.lastPersistenceError = error.localizedDescription
      }
    } else {
      self.items = []
    }

    sortItems()
    trimToLimit()
  }

  public var filteredItems: [ClipboardItem] {
    items.filter { $0.matches(searchText) }
  }

  nonisolated public static func clampedLimit(_ value: Int) -> Int {
    min(max(value, minimumLimit), maximumLimit)
  }

  @discardableResult
  public func recordCopy(
    _ content: String,
    sourceApp: String? = nil,
    at date: Date = Date()
  ) -> ClipboardItem? {
    guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return nil
    }

    let cleanedSource = normalizedSource(sourceApp)

    if let existingIndex = items.firstIndex(where: { $0.content == content }) {
      var existingItem = items.remove(at: existingIndex)
      existingItem.copyCount += 1
      existingItem.lastCopiedAt = date

      if let cleanedSource {
        existingItem.sourceApp = cleanedSource
      }

      items.append(existingItem)
      sortItems()
      trimToLimit()
      save()
      return existingItem
    }

    let item = ClipboardItem(
      content: content,
      sourceApp: cleanedSource,
      firstCopiedAt: date,
      lastCopiedAt: date
    )

    items.append(item)
    sortItems()
    trimToLimit()
    save()
    return item
  }

  public func updateLimit(_ limit: Int) {
    maxStoredItems = Self.clampedLimit(limit)
    trimToLimit()
    save()
  }

  public func togglePin(_ itemID: ClipboardItem.ID) {
    guard let index = items.firstIndex(where: { $0.id == itemID }) else {
      return
    }

    items[index].isPinned.toggle()
    sortItems()
    trimToLimit()
    save()
  }

  public func delete(_ itemID: ClipboardItem.ID) {
    items.removeAll { $0.id == itemID }
    save()
  }

  public func clearUnpinned() {
    items.removeAll { !$0.isPinned }
    save()
  }

  public func clearAll() {
    items.removeAll()
    save()
  }

  public func item(withID itemID: ClipboardItem.ID) -> ClipboardItem? {
    items.first { $0.id == itemID }
  }

  private func sortItems() {
    items.sort { lhs, rhs in
      if lhs.isPinned != rhs.isPinned {
        return lhs.isPinned
      }

      return lhs.lastCopiedAt > rhs.lastCopiedAt
    }
  }

  private func trimToLimit() {
    let pinnedItems = items.filter(\.isPinned)
    let unpinnedLimit = max(0, maxStoredItems - pinnedItems.count)
    let unpinnedItems = Array(items.filter { !$0.isPinned }.prefix(unpinnedLimit))

    items = pinnedItems + unpinnedItems
    sortItems()
  }

  private func save() {
    guard let persistence else {
      return
    }

    do {
      try persistence.save(items)
      lastPersistenceError = nil
    } catch {
      lastPersistenceError = error.localizedDescription
    }
  }

  private func normalizedSource(_ sourceApp: String?) -> String? {
    let trimmedSource = sourceApp?.trimmingCharacters(in: .whitespacesAndNewlines)

    guard let trimmedSource, !trimmedSource.isEmpty else {
      return nil
    }

    return trimmedSource
  }
}
