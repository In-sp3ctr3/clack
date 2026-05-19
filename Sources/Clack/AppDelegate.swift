import AppKit
import ClackCore
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private let preferences: ClackPreferences
  private let store: ClipboardHistoryStore
  private let popover = NSPopover()

  private var monitor: PasteboardMonitor?
  private var globalHotKeys: GlobalHotKeyController?
  private var statusItem: NSStatusItem?
  private var preferencesWindowController: NSWindowController?
  private var cancellables: Set<AnyCancellable> = []

  override init() {
    let preferences = ClackPreferences()
    self.preferences = preferences
    self.store = ClipboardHistoryStore(
      maxStoredItems: preferences.historyLimit,
      persistence: JSONHistoryPersistence()
    )

    super.init()
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    configureStatusItem()
    configurePopover()
    configureGlobalHotKeys()
    observePreferences()

    let monitor = PasteboardMonitor(
      store: store,
      preferences: preferences
    )
    monitor.start()
    self.monitor = monitor
  }

  func applicationWillTerminate(_ notification: Notification) {
    if preferences.clearHistoryOnQuit {
      store.clearAll()
    }

    if preferences.clearSystemClipboardOnQuit {
      NSPasteboard.general.clearContents()
    }
  }

  private func configureStatusItem() {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    if let button = statusItem.button {
      button.target = self
      button.action = #selector(togglePopover(_:))
      button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    self.statusItem = statusItem
    updateStatusItem()
  }

  private func observePreferences() {
    preferences.objectWillChange
      .sink { [weak self] _ in
        Task { @MainActor in
          self?.updateStatusItem()
        }
      }
      .store(in: &cancellables)

    store.$items
      .sink { [weak self] _ in
        self?.updateStatusItem()
      }
      .store(in: &cancellables)
  }

  private func updateStatusItem() {
    guard let button = statusItem?.button else {
      return
    }

    if preferences.showMenuIcon {
      let image = NSImage(
        systemSymbolName: preferences.menuIconSymbol,
        accessibilityDescription: "Clack"
      ) ?? NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clack")
      button.image = image
    } else {
      button.image = nil
    }

    let recentCopy = preferences.showRecentCopyInMenuBar
      ? store.items.first?.preview.prefix(28).description
      : nil

    if let recentCopy, !recentCopy.isEmpty {
      button.title = preferences.showMenuIcon ? " \(recentCopy)" : "Clack \(recentCopy)"
    } else {
      button.title = preferences.showMenuIcon ? "" : "Clack"
    }
  }

  private func configurePopover() {
    let actions = ClipboardActions(
      restore: { [weak self] item in
        self?.restore(item)
      },
      togglePin: { [weak self] item in
        self?.store.togglePin(item.id)
      },
      delete: { [weak self] item in
        self?.store.delete(item.id)
      },
      clearUnpinned: { [weak self] in
        self?.store.clearUnpinned()
      },
      showPreferences: { [weak self] in
        self?.showPreferences()
      },
      showAbout: { [weak self] in
        self?.showAbout()
      },
      quit: {
        NSApplication.shared.terminate(nil)
      }
    )

    popover.behavior = .transient
    popover.animates = true
    popover.contentSize = NSSize(width: 460, height: 620)
    popover.contentViewController = NSHostingController(
      rootView: ClackPopoverView(
        store: store,
        preferences: preferences,
        actions: actions
      )
    )
  }

  private func configureGlobalHotKeys() {
    let globalHotKeys = GlobalHotKeyController { [weak self] in
      self?.togglePopover(nil)
    }
    globalHotKeys.start()
    self.globalHotKeys = globalHotKeys
  }

  private func restore(_ item: ClipboardItem) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(item.content, forType: .string)
    monitor?.ignoreChange(count: pasteboard.changeCount)
    popover.performClose(nil)
  }

  private func showPreferences() {
    if let preferencesWindowController {
      preferencesWindowController.showWindow(nil)
      preferencesWindowController.window?.makeKeyAndOrderFront(nil)
      NSApplication.shared.activate(ignoringOtherApps: true)
      return
    }

    let view = PreferencesView(
      preferences: preferences,
      store: store
    )

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 840, height: 620),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )
    window.title = "Clack Preferences"
    window.minSize = NSSize(width: 760, height: 560)
    window.center()
    window.contentViewController = NSHostingController(rootView: view)

    let controller = NSWindowController(window: window)
    preferencesWindowController = controller
    controller.showWindow(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
  }

  private func showAbout() {
    NSApplication.shared.activate(ignoringOtherApps: true)
    NSApplication.shared.orderFrontStandardAboutPanel(options: [
      .applicationName: "Clack",
      .applicationVersion: "0.1.0",
      .version: "0.1.0",
      .credits: NSAttributedString(string: "A native macOS clipboard memory tool.")
    ])
  }

  @objc private func togglePopover(_ sender: AnyObject?) {
    guard let button = statusItem?.button else {
      return
    }

    if popover.isShown {
      popover.performClose(sender)
    } else {
      NSApplication.shared.activate(ignoringOtherApps: true)
      popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
  }
}
