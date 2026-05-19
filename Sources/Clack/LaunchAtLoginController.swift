import ClackCore
import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginController: ObservableObject {
  @Published private(set) var lastError: String?

  func sync(preferences: ClackPreferences) {
    preferences.launchAtLogin = SMAppService.mainApp.status == .enabled
  }

  func setEnabled(
    _ isEnabled: Bool,
    preferences: ClackPreferences
  ) {
    do {
      if isEnabled {
        try SMAppService.mainApp.register()
      } else {
        try SMAppService.mainApp.unregister()
      }

      preferences.launchAtLogin = isEnabled
      lastError = nil
    } catch {
      lastError = error.localizedDescription
      sync(preferences: preferences)
    }
  }
}
