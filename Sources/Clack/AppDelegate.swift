import AppKit
import ClackCore
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private let preferences: ClackPreferences
  private let store: ClipboardHistoryStore

  private var monitor: PasteboardMonitor?
  private var globalHotKeys: GlobalHotKeyController?
  private var statusItem: NSStatusItem?
  private var panel: ClackFloatingPanel?
  private let previewPopover = ClackPreviewPopoverController()
  private var suppressPanelOpenUntil: Date?
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
      button.toolTip = "Clack clipboard history"
      button.setAccessibilityLabel("Clack clipboard history")
      button.setAccessibilityHelp("Opens the Clack clipboard history popover.")
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
      button.image = menuBarImage()
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

  private func menuBarImage() -> NSImage? {
    let image = Bundle.main.url(
      forResource: "ClackMenuBarTemplate",
      withExtension: "png"
    ).flatMap(NSImage.init(contentsOf:)) ?? NSImage(
      systemSymbolName: "doc.on.clipboard",
      accessibilityDescription: "Clack"
    )

    image?.isTemplate = true
    image?.size = NSSize(width: 18, height: 18)
    image?.accessibilityDescription = "Clack"
    return image
  }

  private func makeClipboardActions() -> ClipboardActions {
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
        self?.closePanel()
        self?.showPreferences()
      },
      showAbout: { [weak self] in
        self?.closePanel()
        self?.showAbout()
      },
      quit: {
        NSApplication.shared.terminate(nil)
      }
    )

    return actions
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
    var didWrite = false

    switch item.kind {
    case .text:
      didWrite = pasteboard.setString(item.content, forType: .string)
    case .richText:
      didWrite = pasteboard.setString(item.content, forType: .string)

      for representation in item.richTextRepresentations {
        didWrite = pasteboard.setData(
          representation.data,
          forType: NSPasteboard.PasteboardType(representation.type)
        ) || didWrite
      }
    case .file:
      let urls = item.fileURLs.map { URL(fileURLWithPath: $0) as NSURL }
      if !urls.isEmpty {
        didWrite = pasteboard.writeObjects(urls)
      }
    case .image:
      if
        let imageData = item.imageData,
        let image = NSImage(data: imageData)
      {
        didWrite = pasteboard.writeObjects([image])
      } else if let imageData = item.imageData {
        didWrite = pasteboard.setData(
          imageData,
          forType: NSPasteboard.PasteboardType(item.imageContentType ?? "public.png")
        )
      }
    }

    if didWrite {
      monitor?.ignoreChange(count: pasteboard.changeCount)
      store.markRestored(item.id)
    }

    closePanel()
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

    if panel?.isPresented == true {
      closePanel()
    } else {
      if shouldSuppressPanelOpen() {
        return
      }

      openPanel(relativeTo: button)
    }
  }

  private func openPanel(relativeTo button: NSStatusBarButton) {
    let panel = ClackFloatingPanel(
      contentSize: ClackPopoverView.compactContentSize,
      statusButton: button,
      onClose: { [weak self] in
        self?.suppressPanelOpenUntil = Date().addingTimeInterval(0.25)
        self?.previewPopover.close()
        self?.panel = nil
      },
      rootView: ClackPopoverView(
        store: store,
        preferences: preferences,
        actions: makeClipboardActions(),
        showPreview: { [weak self] item, rowRect in
          self?.showPreview(item, anchoredTo: rowRect)
        },
        hidePreview: { [weak self] in
          self?.previewPopover.close()
        }
      )
    )

    self.panel = panel
    panel.open()
  }

  private func closePanel() {
    previewPopover.close()
    panel?.close()
    panel = nil
  }

  private func showPreview(_ item: ClipboardItem, anchoredTo rowRect: NSRect) {
    guard
      let panel,
      let contentView = panel.contentView
    else {
      return
    }

    previewPopover.show(item: item, relativeTo: rowRect, of: contentView)
  }

  private func shouldSuppressPanelOpen() -> Bool {
    guard let suppressPanelOpenUntil else {
      return false
    }

    if Date() < suppressPanelOpenUntil {
      return true
    }

    self.suppressPanelOpenUntil = nil
    return false
  }
}
