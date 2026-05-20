import Carbon
import ClackCore
import Foundation

final class GlobalHotKeyController {
  private let onOpen: @MainActor () -> Void

  private var eventHandler: EventHandlerRef?
  private var openHotKey: EventHotKeyRef?
  private var shortcut: ClackKeyboardShortcut

  init(
    shortcut: ClackKeyboardShortcut,
    onOpen: @escaping @MainActor () -> Void
  ) {
    self.shortcut = shortcut
    self.onOpen = onOpen
  }

  deinit {
    stop()
  }

  func start() {
    guard eventHandler == nil else {
      return
    }

    var eventType = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard),
      eventKind: UInt32(kEventHotKeyPressed)
    )
    let userData = Unmanaged.passUnretained(self).toOpaque()

    InstallEventHandler(
      GetApplicationEventTarget(),
      globalHotKeyEventHandler,
      1,
      &eventType,
      userData,
      &eventHandler
    )

    registerOpenHotKey(shortcut)
  }

  func update(shortcut: ClackKeyboardShortcut) {
    guard self.shortcut != shortcut else {
      return
    }

    self.shortcut = shortcut

    if let openHotKey {
      UnregisterEventHotKey(openHotKey)
      self.openHotKey = nil
    }

    guard eventHandler != nil else {
      return
    }

    registerOpenHotKey(shortcut)
  }

  func stop() {
    if let openHotKey {
      UnregisterEventHotKey(openHotKey)
      self.openHotKey = nil
    }

    if let eventHandler {
      RemoveEventHandler(eventHandler)
      self.eventHandler = nil
    }
  }

  private func registerOpenHotKey(_ shortcut: ClackKeyboardShortcut) {
    let hotKeyID = EventHotKeyID(
      signature: Self.signature,
      id: Self.openHotKeyID
    )

    let status = RegisterEventHotKey(
      UInt32(shortcut.keyCode),
      carbonModifiers(from: shortcut.modifiers),
      hotKeyID,
      GetApplicationEventTarget(),
      0,
      &openHotKey
    )

    if status != noErr {
      openHotKey = nil
    }
  }

  fileprivate func handle(_ hotKeyID: EventHotKeyID) {
    guard
      hotKeyID.signature == Self.signature,
      hotKeyID.id == Self.openHotKeyID
    else {
      return
    }

    Task { @MainActor [onOpen] in
      onOpen()
    }
  }

  private static let signature = fourCharacterCode("CLCK")
  private static let openHotKeyID: UInt32 = 1
}

private func carbonModifiers(from modifiers: Int) -> UInt32 {
  var result = UInt32(0)

  if modifiers & ClackKeyboardShortcut.command != 0 {
    result |= UInt32(cmdKey)
  }

  if modifiers & ClackKeyboardShortcut.shift != 0 {
    result |= UInt32(shiftKey)
  }

  if modifiers & ClackKeyboardShortcut.option != 0 {
    result |= UInt32(optionKey)
  }

  if modifiers & ClackKeyboardShortcut.control != 0 {
    result |= UInt32(controlKey)
  }

  return result
}

private let globalHotKeyEventHandler: EventHandlerUPP = { _, event, userData in
  guard let event, let userData else {
    return noErr
  }

  var hotKeyID = EventHotKeyID()
  let status = GetEventParameter(
    event,
    EventParamName(kEventParamDirectObject),
    EventParamType(typeEventHotKeyID),
    nil,
    MemoryLayout<EventHotKeyID>.size,
    nil,
    &hotKeyID
  )

  guard status == noErr else {
    return status
  }

  let controller = Unmanaged<GlobalHotKeyController>
    .fromOpaque(userData)
    .takeUnretainedValue()
  controller.handle(hotKeyID)

  return noErr
}

private func fourCharacterCode(_ value: String) -> OSType {
  value.utf8.reduce(0) { result, character in
    (result << 8) + OSType(character)
  }
}
