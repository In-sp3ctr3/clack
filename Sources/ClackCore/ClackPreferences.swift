import Combine
import Foundation

@MainActor
public final class ClackPreferences: ObservableObject {
  private enum Keys {
    static let historyLimit = "historyLimit"
  }

  @Published public private(set) var historyLimit: Int

  private let defaults: UserDefaults

  public init(defaults: UserDefaults = .standard) {
    self.defaults = defaults

    let savedLimit = defaults.integer(forKey: Keys.historyLimit)
    if savedLimit == 0 {
      self.historyLimit = ClipboardHistoryStore.defaultLimit
    } else {
      self.historyLimit = ClipboardHistoryStore.clampedLimit(savedLimit)
    }
  }

  public func setHistoryLimit(_ limit: Int) {
    let clampedLimit = ClipboardHistoryStore.clampedLimit(limit)

    guard historyLimit != clampedLimit else {
      return
    }

    historyLimit = clampedLimit
    defaults.set(clampedLimit, forKey: Keys.historyLimit)
  }
}
