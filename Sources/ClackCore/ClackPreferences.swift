import Combine
import Foundation

public enum SearchMode: String, CaseIterable, Hashable, Identifiable {
  case contains = "Contains"
  case exact = "Exact"

  public var id: String { rawValue }
}

public enum SortMode: String, CaseIterable, Hashable, Identifiable {
  case lastCopied = "Time of last copy"
  case firstCopied = "Time of first copy"
  case copyCount = "Copy count"
  case content = "Content"

  public var id: String { rawValue }
}

public enum PopupLocation: String, CaseIterable, Hashable, Identifiable {
  case cursor = "Cursor"
  case menuBar = "Menu bar"
  case center = "Screen center"

  public var id: String { rawValue }
}

public enum PinLocation: String, CaseIterable, Hashable, Identifiable {
  case top = "Top"
  case bottom = "Bottom"

  public var id: String { rawValue }
}

public enum HighlightStyle: String, CaseIterable, Hashable, Identifiable {
  case bold = "Bold"
  case underline = "Underline"
  case none = "None"

  public var id: String { rawValue }
}

public enum SearchFieldVisibility: String, CaseIterable, Hashable, Identifiable {
  case always = "Always"
  case whenHistoryExists = "When history exists"
  case never = "Never"

  public var id: String { rawValue }
}

@MainActor
public final class ClackPreferences: ObservableObject {
  private enum Keys {
    static let launchAtLogin = "launchAtLogin"
    static let checkForUpdatesAutomatically = "checkForUpdatesAutomatically"
    static let historyLimit = "historyLimit"
    static let saveFiles = "saveFiles"
    static let saveImages = "saveImages"
    static let saveText = "saveText"
    static let searchMode = "searchMode"
    static let sortMode = "sortMode"
    static let popupLocation = "popupLocation"
    static let pinLocation = "pinLocation"
    static let imageHeight = "imageHeight"
    static let previewDelayMilliseconds = "previewDelayMilliseconds"
    static let highlightStyle = "highlightStyle"
    static let showSpecialSymbols = "showSpecialSymbols"
    static let showMenuIcon = "showMenuIcon"
    static let showRecentCopyInMenuBar = "showRecentCopyInMenuBar"
    static let searchFieldVisibility = "searchFieldVisibility"
    static let showTitleBeforeSearchField = "showTitleBeforeSearchField"
    static let showApplicationIcons = "showApplicationIcons"
    static let showFooter = "showFooter"
    static let ignoredApplications = "ignoredApplications"
    static let ignoreAllApplicationsExceptListed = "ignoreAllApplicationsExceptListed"
    static let ignoredPasteboardTypes = "ignoredPasteboardTypes"
    static let ignoredRegularExpressions = "ignoredRegularExpressions"
    static let temporarilyIgnoreNewCopies = "temporarilyIgnoreNewCopies"
    static let ignoreOnlyNextCopy = "ignoreOnlyNextCopy"
    static let clearHistoryOnQuit = "clearHistoryOnQuit"
    static let clearSystemClipboardOnQuit = "clearSystemClipboardOnQuit"
  }

  @Published public private(set) var historyLimit: Int
  @Published public var launchAtLogin: Bool { didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) } }
  @Published public var checkForUpdatesAutomatically: Bool { didSet { defaults.set(checkForUpdatesAutomatically, forKey: Keys.checkForUpdatesAutomatically) } }
  @Published public var saveFiles: Bool { didSet { defaults.set(saveFiles, forKey: Keys.saveFiles) } }
  @Published public var saveImages: Bool { didSet { defaults.set(saveImages, forKey: Keys.saveImages) } }
  @Published public var saveText: Bool { didSet { defaults.set(saveText, forKey: Keys.saveText) } }
  @Published public var searchMode: SearchMode { didSet { defaults.set(searchMode.rawValue, forKey: Keys.searchMode) } }
  @Published public var sortMode: SortMode { didSet { defaults.set(sortMode.rawValue, forKey: Keys.sortMode) } }
  @Published public var popupLocation: PopupLocation { didSet { defaults.set(popupLocation.rawValue, forKey: Keys.popupLocation) } }
  @Published public var pinLocation: PinLocation { didSet { defaults.set(pinLocation.rawValue, forKey: Keys.pinLocation) } }
  @Published public var imageHeight: Int { didSet { defaults.set(imageHeight, forKey: Keys.imageHeight) } }
  @Published public var previewDelayMilliseconds: Int { didSet { defaults.set(previewDelayMilliseconds, forKey: Keys.previewDelayMilliseconds) } }
  @Published public var highlightStyle: HighlightStyle { didSet { defaults.set(highlightStyle.rawValue, forKey: Keys.highlightStyle) } }
  @Published public var showSpecialSymbols: Bool { didSet { defaults.set(showSpecialSymbols, forKey: Keys.showSpecialSymbols) } }
  @Published public var showMenuIcon: Bool { didSet { defaults.set(showMenuIcon, forKey: Keys.showMenuIcon) } }
  @Published public var showRecentCopyInMenuBar: Bool { didSet { defaults.set(showRecentCopyInMenuBar, forKey: Keys.showRecentCopyInMenuBar) } }
  @Published public var searchFieldVisibility: SearchFieldVisibility { didSet { defaults.set(searchFieldVisibility.rawValue, forKey: Keys.searchFieldVisibility) } }
  @Published public var showTitleBeforeSearchField: Bool { didSet { defaults.set(showTitleBeforeSearchField, forKey: Keys.showTitleBeforeSearchField) } }
  @Published public var showApplicationIcons: Bool { didSet { defaults.set(showApplicationIcons, forKey: Keys.showApplicationIcons) } }
  @Published public var showFooter: Bool { didSet { defaults.set(showFooter, forKey: Keys.showFooter) } }
  @Published public private(set) var ignoredApplications: [String] { didSet { defaults.set(ignoredApplications, forKey: Keys.ignoredApplications) } }
  @Published public var ignoreAllApplicationsExceptListed: Bool { didSet { defaults.set(ignoreAllApplicationsExceptListed, forKey: Keys.ignoreAllApplicationsExceptListed) } }
  @Published public private(set) var ignoredPasteboardTypes: [String] { didSet { defaults.set(ignoredPasteboardTypes, forKey: Keys.ignoredPasteboardTypes) } }
  @Published public private(set) var ignoredRegularExpressions: [String] { didSet { defaults.set(ignoredRegularExpressions, forKey: Keys.ignoredRegularExpressions) } }
  @Published public var temporarilyIgnoreNewCopies: Bool { didSet { defaults.set(temporarilyIgnoreNewCopies, forKey: Keys.temporarilyIgnoreNewCopies) } }
  @Published public var ignoreOnlyNextCopy: Bool { didSet { defaults.set(ignoreOnlyNextCopy, forKey: Keys.ignoreOnlyNextCopy) } }
  @Published public var clearHistoryOnQuit: Bool { didSet { defaults.set(clearHistoryOnQuit, forKey: Keys.clearHistoryOnQuit) } }
  @Published public var clearSystemClipboardOnQuit: Bool { didSet { defaults.set(clearSystemClipboardOnQuit, forKey: Keys.clearSystemClipboardOnQuit) } }

  private let defaults: UserDefaults

  public init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    self.historyLimit = Self.integer(defaults, key: Keys.historyLimit, defaultValue: ClipboardHistoryStore.defaultLimit)
    self.launchAtLogin = Self.bool(defaults, key: Keys.launchAtLogin, defaultValue: false)
    self.checkForUpdatesAutomatically = Self.bool(defaults, key: Keys.checkForUpdatesAutomatically, defaultValue: false)
    self.saveFiles = Self.bool(defaults, key: Keys.saveFiles, defaultValue: true)
    self.saveImages = Self.bool(defaults, key: Keys.saveImages, defaultValue: true)
    self.saveText = Self.bool(defaults, key: Keys.saveText, defaultValue: true)
    self.searchMode = Self.enumeration(defaults, key: Keys.searchMode, defaultValue: .contains)
    self.sortMode = Self.enumeration(defaults, key: Keys.sortMode, defaultValue: .lastCopied)
    self.popupLocation = Self.enumeration(defaults, key: Keys.popupLocation, defaultValue: .cursor)
    self.pinLocation = Self.enumeration(defaults, key: Keys.pinLocation, defaultValue: .top)
    self.imageHeight = Self.integer(defaults, key: Keys.imageHeight, defaultValue: 40)
    self.previewDelayMilliseconds = Self.integer(defaults, key: Keys.previewDelayMilliseconds, defaultValue: 1_500)
    self.highlightStyle = Self.enumeration(defaults, key: Keys.highlightStyle, defaultValue: .bold)
    self.showSpecialSymbols = Self.bool(defaults, key: Keys.showSpecialSymbols, defaultValue: true)
    self.showMenuIcon = Self.bool(defaults, key: Keys.showMenuIcon, defaultValue: true)
    self.showRecentCopyInMenuBar = Self.bool(defaults, key: Keys.showRecentCopyInMenuBar, defaultValue: false)
    self.searchFieldVisibility = Self.enumeration(defaults, key: Keys.searchFieldVisibility, defaultValue: .always)
    self.showTitleBeforeSearchField = Self.bool(defaults, key: Keys.showTitleBeforeSearchField, defaultValue: true)
    self.showApplicationIcons = Self.bool(defaults, key: Keys.showApplicationIcons, defaultValue: true)
    self.showFooter = Self.bool(defaults, key: Keys.showFooter, defaultValue: true)
    self.ignoredApplications = defaults.stringArray(forKey: Keys.ignoredApplications) ?? []
    self.ignoreAllApplicationsExceptListed = Self.bool(defaults, key: Keys.ignoreAllApplicationsExceptListed, defaultValue: false)
    self.ignoredPasteboardTypes = defaults.stringArray(forKey: Keys.ignoredPasteboardTypes) ?? []
    self.ignoredRegularExpressions = defaults.stringArray(forKey: Keys.ignoredRegularExpressions) ?? []
    self.temporarilyIgnoreNewCopies = Self.bool(defaults, key: Keys.temporarilyIgnoreNewCopies, defaultValue: false)
    self.ignoreOnlyNextCopy = Self.bool(defaults, key: Keys.ignoreOnlyNextCopy, defaultValue: false)
    self.clearHistoryOnQuit = Self.bool(defaults, key: Keys.clearHistoryOnQuit, defaultValue: false)
    self.clearSystemClipboardOnQuit = Self.bool(defaults, key: Keys.clearSystemClipboardOnQuit, defaultValue: false)

    self.historyLimit = ClipboardHistoryStore.clampedLimit(historyLimit)
  }

  public func setHistoryLimit(_ limit: Int) {
    let clampedLimit = ClipboardHistoryStore.clampedLimit(limit)

    guard historyLimit != clampedLimit else {
      return
    }

    historyLimit = clampedLimit
    defaults.set(clampedLimit, forKey: Keys.historyLimit)
  }

  public func addIgnoredApplication(_ value: String) {
    appendCleaned(value, to: \.ignoredApplications)
  }

  public func updateIgnoredApplication(id: String, value: String) {
    update(id: id, value: value, in: \.ignoredApplications)
  }

  public func removeIgnoredApplication(id: String) {
    remove(id: id, from: \.ignoredApplications)
  }

  public func addIgnoredPasteboardType(_ value: String) {
    appendCleaned(value, to: \.ignoredPasteboardTypes)
  }

  public func updateIgnoredPasteboardType(id: String, value: String) {
    update(id: id, value: value, in: \.ignoredPasteboardTypes)
  }

  public func removeIgnoredPasteboardType(id: String) {
    remove(id: id, from: \.ignoredPasteboardTypes)
  }

  public func addIgnoredRegularExpression(_ value: String) {
    appendCleaned(value, to: \.ignoredRegularExpressions)
  }

  public func updateIgnoredRegularExpression(id: String, value: String) {
    update(id: id, value: value, in: \.ignoredRegularExpressions)
  }

  public func removeIgnoredRegularExpression(id: String) {
    remove(id: id, from: \.ignoredRegularExpressions)
  }

  public func refreshRuntimeControls() {
    defaults.synchronize()

    temporarilyIgnoreNewCopies = Self.bool(
      defaults,
      key: Keys.temporarilyIgnoreNewCopies,
      defaultValue: temporarilyIgnoreNewCopies
    )
    ignoreOnlyNextCopy = Self.bool(
      defaults,
      key: Keys.ignoreOnlyNextCopy,
      defaultValue: ignoreOnlyNextCopy
    )
  }

  private func appendCleaned(
    _ value: String,
    to keyPath: ReferenceWritableKeyPath<ClackPreferences, [String]>
  ) {
    let cleanedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !cleanedValue.isEmpty else {
      return
    }

    var values = self[keyPath: keyPath]
    guard !values.contains(cleanedValue) else {
      return
    }

    values.append(cleanedValue)
    self[keyPath: keyPath] = values
  }

  private func update(
    id: String,
    value: String,
    in keyPath: ReferenceWritableKeyPath<ClackPreferences, [String]>
  ) {
    let cleanedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
    var values = self[keyPath: keyPath]

    guard let index = values.firstIndex(of: id) else {
      return
    }

    if cleanedValue.isEmpty {
      values.remove(at: index)
    } else {
      values[index] = cleanedValue
    }

    var uniqueValues: [String] = []
    for value in values where !uniqueValues.contains(value) {
      uniqueValues.append(value)
    }

    self[keyPath: keyPath] = uniqueValues
  }

  private func remove(
    id: String,
    from keyPath: ReferenceWritableKeyPath<ClackPreferences, [String]>
  ) {
    var values = self[keyPath: keyPath]
    values.removeAll { $0 == id }
    self[keyPath: keyPath] = values
  }

  private static func bool(
    _ defaults: UserDefaults,
    key: String,
    defaultValue: Bool
  ) -> Bool {
    guard defaults.object(forKey: key) != nil else {
      return defaultValue
    }

    return defaults.bool(forKey: key)
  }

  private static func integer(
    _ defaults: UserDefaults,
    key: String,
    defaultValue: Int
  ) -> Int {
    guard defaults.object(forKey: key) != nil else {
      return defaultValue
    }

    return defaults.integer(forKey: key)
  }

  private static func enumeration<T: RawRepresentable>(
    _ defaults: UserDefaults,
    key: String,
    defaultValue: T
  ) -> T where T.RawValue == String {
    guard
      let value = defaults.string(forKey: key),
      let result = T(rawValue: value)
    else {
      return defaultValue
    }

    return result
  }
}
