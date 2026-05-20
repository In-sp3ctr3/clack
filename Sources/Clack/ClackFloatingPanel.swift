import AppKit
import ClackCore
import SwiftUI

@MainActor
final class ClackFloatingPanel: NSPanel, NSWindowDelegate {
  private static let screenPadding: CGFloat = 8
  private static let statusBarGap: CGFloat = 6
  private static var lastOrigin: NSPoint?

  private let compactContentSize: NSSize
  private let popupLocation: PopupLocation
  private let onClose: () -> Void
  private weak var statusButton: NSStatusBarButton?

  private(set) var isPresented = false
  private var isClosing = false
  private var didNotifyClose = false

  init<Content: View>(
    contentSize: NSSize,
    popupLocation: PopupLocation,
    statusButton: NSStatusBarButton?,
    onClose: @escaping () -> Void,
    rootView: Content
  ) {
    self.compactContentSize = contentSize
    self.popupLocation = popupLocation
    self.statusButton = statusButton
    self.onClose = onClose

    super.init(
      contentRect: NSRect(origin: .zero, size: contentSize),
      styleMask: [.nonactivatingPanel, .closable, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )

    delegate = self
    animationBehavior = .none
    isFloatingPanel = true
    level = .statusBar
    collectionBehavior = [.auxiliary, .stationary, .moveToActiveSpace, .fullScreenAuxiliary]
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    titlebarSeparatorStyle = .none
    isMovableByWindowBackground = false
    hidesOnDeactivate = false
    backgroundColor = .clear
    isOpaque = false
    hasShadow = true

    standardWindowButton(.closeButton)?.isHidden = true
    standardWindowButton(.miniaturizeButton)?.isHidden = true
    standardWindowButton(.zoomButton)?.isHidden = true

    contentView = NSHostingView(rootView: rootView.ignoresSafeArea())
    contentView?.wantsLayer = true
    contentView?.layer?.cornerRadius = 12
    contentView?.layer?.masksToBounds = true
  }

  override var canBecomeKey: Bool {
    true
  }

  override var canBecomeMain: Bool {
    false
  }

  func open() {
    isClosing = false
    didNotifyClose = false
    setFrame(frame(for: compactContentSize, anchoredTo: statusButton, location: popupLocation), display: false)
    orderFrontRegardless()
    makeKey()
    isPresented = true
  }

  override func resignKey() {
    super.resignKey()

    if isPresented {
      close()
    }
  }

  override func close() {
    guard !isClosing else {
      return
    }

    isClosing = true
    isPresented = false
    Self.lastOrigin = frame.origin
    super.close()
    notifyClose()
  }

  private func notifyClose() {
    guard !didNotifyClose else {
      return
    }

    didNotifyClose = true
    onClose()
  }

  private func frame(
    for contentSize: NSSize,
    anchoredTo button: NSStatusBarButton?,
    location: PopupLocation
  ) -> NSRect {
    let frameSize = frameRect(forContentRect: NSRect(origin: .zero, size: contentSize)).size
    let screenRect = buttonScreenRect(button)
    let visibleFrame = (button?.window?.screen ?? NSScreen.main)?.visibleFrame
      ?? NSScreen.screens.first?.visibleFrame
      ?? NSRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)

    var origin: NSPoint

    switch location {
    case .menuIcon:
      origin = NSPoint(
        x: screenRect.midX - frameSize.width / 2,
        y: screenRect.minY - frameSize.height - Self.statusBarGap
      )
    case .cursor:
      let cursor = NSEvent.mouseLocation
      origin = NSPoint(
        x: cursor.x - frameSize.width / 2,
        y: cursor.y - 12 - frameSize.height
      )
    case .windowCenter, .center:
      origin = NSPoint(
        x: visibleFrame.midX - frameSize.width / 2,
        y: visibleFrame.midY - frameSize.height / 2
      )
    case .lastPosition:
      origin = Self.lastOrigin ?? NSPoint(
        x: screenRect.midX - frameSize.width / 2,
        y: screenRect.minY - frameSize.height - Self.statusBarGap
      )
    }

    origin.x = min(
      max(origin.x, visibleFrame.minX + Self.screenPadding),
      visibleFrame.maxX - frameSize.width - Self.screenPadding
    )
    origin.y = min(
      max(origin.y, visibleFrame.minY + Self.screenPadding),
      visibleFrame.maxY - frameSize.height - Self.screenPadding
    )

    return NSRect(origin: origin, size: frameSize)
  }

  private func buttonScreenRect(_ button: NSStatusBarButton?) -> NSRect {
    guard
      let button,
      let window = button.window
    else {
      let screenFrame = NSScreen.main?.visibleFrame ?? .zero
      return NSRect(
        x: screenFrame.midX,
        y: screenFrame.maxY,
        width: 0,
        height: 0
      )
    }

    let buttonRect = button.convert(button.bounds, to: nil)
    return window.convertToScreen(buttonRect)
  }
}
