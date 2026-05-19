import ClackCore
import Darwin
import Foundation

private struct CheckFailure: Error, CustomStringConvertible {
  let description: String
}

private struct Check {
  let name: String
  let run: @MainActor () throws -> Void
}

@main
struct ClackCoreChecks {
  @MainActor
  static func main() {
    let checks: [Check] = [
      Check(name: "recording a copy adds a new item", run: testRecordCopyAddsNewItem),
      Check(name: "duplicate copies update the existing item", run: testDuplicateCopyUpdatesExistingItem),
      Check(name: "history limit prunes old unpinned items", run: testHistoryLimitPrunesOldUnpinnedItems),
      Check(name: "pinned items survive limit and clear", run: testPinnedItemsSurviveLimitAndClear),
      Check(name: "search matches content and source app", run: testSearchMatchesContentAndSourceApp),
      Check(name: "persistence loads and saves items", run: testPersistenceLoadsAndSavesItems),
      Check(name: "whitespace-only content is ignored", run: testWhitespaceOnlyClipboardContentIsIgnored),
      Check(name: "preferences persist values and ignore lists", run: testPreferencesPersistValuesAndIgnoreLists)
    ]

    do {
      for check in checks {
        try check.run()
        print("ok - \(check.name)")
      }

      print("\nAll ClackCore checks passed.")
    } catch {
      fputs("Check failed: \(error)\n", stderr)
      exit(1)
    }
  }

  @MainActor
  private static func testRecordCopyAddsNewItem() throws {
    let store = ClipboardHistoryStore(maxStoredItems: 10, loadSavedItems: false)
    let copiedAt = Date(timeIntervalSince1970: 100)

    let item = store.recordCopy("hello world", sourceApp: "Safari", at: copiedAt)

    try expect(item?.content == "hello world", "expected copied content to be stored")
    try expect(store.items.count == 1, "expected one stored item")
    try expect(store.items.first?.sourceApp == "Safari", "expected source app to be stored")
    try expect(store.items.first?.firstCopiedAt == copiedAt, "expected first copy date to match")
    try expect(store.items.first?.lastCopiedAt == copiedAt, "expected last copy date to match")
    try expect(store.items.first?.copyCount == 1, "expected first copy count to be one")
  }

  @MainActor
  private static func testDuplicateCopyUpdatesExistingItem() throws {
    let store = ClipboardHistoryStore(maxStoredItems: 10, loadSavedItems: false)
    let firstDate = Date(timeIntervalSince1970: 100)
    let secondDate = Date(timeIntervalSince1970: 200)

    store.recordCopy("repeat me", sourceApp: "Notes", at: firstDate)
    store.recordCopy("repeat me", sourceApp: "Mail", at: secondDate)

    try expect(store.items.count == 1, "expected duplicate content to reuse the stored item")
    try expect(store.items.first?.copyCount == 2, "expected duplicate copy count to increment")
    try expect(store.items.first?.firstCopiedAt == firstDate, "expected first copy date to remain stable")
    try expect(store.items.first?.lastCopiedAt == secondDate, "expected last copy date to update")
    try expect(store.items.first?.sourceApp == "Mail", "expected latest source app to update")
  }

  @MainActor
  private static func testHistoryLimitPrunesOldUnpinnedItems() throws {
    let store = ClipboardHistoryStore(maxStoredItems: 3, loadSavedItems: false)

    store.recordCopy("one", at: Date(timeIntervalSince1970: 1))
    store.recordCopy("two", at: Date(timeIntervalSince1970: 2))
    store.recordCopy("three", at: Date(timeIntervalSince1970: 3))
    store.recordCopy("four", at: Date(timeIntervalSince1970: 4))

    try expect(store.items.map(\.content) == ["four", "three", "two"], "expected newest three items")
  }

  @MainActor
  private static func testPinnedItemsSurviveLimitAndClear() throws {
    let store = ClipboardHistoryStore(maxStoredItems: 2, loadSavedItems: false)

    guard let pinned = store.recordCopy("pinned", at: Date(timeIntervalSince1970: 1)) else {
      throw CheckFailure(description: "expected pinned item to be created")
    }

    store.togglePin(pinned.id)
    store.recordCopy("two", at: Date(timeIntervalSince1970: 2))
    store.recordCopy("three", at: Date(timeIntervalSince1970: 3))
    store.recordCopy("four", at: Date(timeIntervalSince1970: 4))
    store.clearUnpinned()

    try expect(store.items.map(\.content) == ["pinned"], "expected pinned item to survive clear")
    try expect(store.items.first?.isPinned == true, "expected remaining item to be pinned")
  }

  @MainActor
  private static func testSearchMatchesContentAndSourceApp() throws {
    let store = ClipboardHistoryStore(maxStoredItems: 10, loadSavedItems: false)

    store.recordCopy("invoice 1042", sourceApp: "Preview")
    store.recordCopy("meeting notes", sourceApp: "Notes")

    store.searchText = "preview"
    try expect(store.filteredItems.map(\.content) == ["invoice 1042"], "expected source-app search match")

    store.searchText = "meeting"
    try expect(store.filteredItems.map(\.content) == ["meeting notes"], "expected content search match")
  }

  @MainActor
  private static func testPersistenceLoadsAndSavesItems() throws {
    let savedItem = ClipboardItem(
      content: "saved",
      firstCopiedAt: Date(timeIntervalSince1970: 1),
      lastCopiedAt: Date(timeIntervalSince1970: 1)
    )
    let persistence = InMemoryHistoryPersistence(items: [savedItem])
    let store = ClipboardHistoryStore(maxStoredItems: 10, persistence: persistence)

    try expect(store.items.map(\.content) == ["saved"], "expected saved item to load")

    store.recordCopy("new", at: Date(timeIntervalSince1970: 2))

    try expect(persistence.savedItems.map(\.content) == ["new", "saved"], "expected new item to persist")
  }

  @MainActor
  private static func testWhitespaceOnlyClipboardContentIsIgnored() throws {
    let store = ClipboardHistoryStore(maxStoredItems: 10, loadSavedItems: false)

    let item = store.recordCopy("   \n\t   ")

    try expect(item == nil, "expected whitespace-only copy to be ignored")
    try expect(store.items.isEmpty, "expected no stored items")
  }

  @MainActor
  private static func testPreferencesPersistValuesAndIgnoreLists() throws {
    let suiteName = "ClackCoreChecks-\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suiteName) else {
      throw CheckFailure(description: "expected test defaults suite")
    }
    defer {
      defaults.removePersistentDomain(forName: suiteName)
    }

    let preferences = ClackPreferences(defaults: defaults)
    preferences.setHistoryLimit(75)
    preferences.saveText = false
    preferences.sortMode = .content
    preferences.searchMode = .exact
    preferences.showFooter = false
    preferences.addIgnoredApplication("Safari")
    preferences.addIgnoredApplication("Safari")
    preferences.addIgnoredRegularExpression("token_[a-z]+")
    preferences.temporarilyIgnoreNewCopies = true

    let reloadedPreferences = ClackPreferences(defaults: defaults)

    try expect(reloadedPreferences.historyLimit == 75, "expected history limit to persist")
    try expect(reloadedPreferences.saveText == false, "expected save text setting to persist")
    try expect(reloadedPreferences.sortMode == .content, "expected sort mode to persist")
    try expect(reloadedPreferences.searchMode == .exact, "expected search mode to persist")
    try expect(reloadedPreferences.showFooter == false, "expected footer setting to persist")
    try expect(reloadedPreferences.ignoredApplications == ["Safari"], "expected ignored app list to stay unique")
    try expect(reloadedPreferences.ignoredRegularExpressions == ["token_[a-z]+"], "expected ignored regex to persist")
    try expect(reloadedPreferences.temporarilyIgnoreNewCopies, "expected ignore toggle to persist")
  }

  private static func expect(
    _ condition: @autoclosure () -> Bool,
    _ message: String
  ) throws {
    guard condition() else {
      throw CheckFailure(description: message)
    }
  }
}
