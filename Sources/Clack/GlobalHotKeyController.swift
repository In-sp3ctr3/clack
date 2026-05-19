import Carbon
import Foundation

final class GlobalHotKeyController {
  private let onOpen: @MainActor () -> Void

  private var eventHandler: EventHandlerRef?
  private var openHotKey: EventHotKeyRef?

  init(onOpen: @escaping @MainActor () -> Void) {
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

    registerOpenHotKey()
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

  private func registerOpenHotKey() {
    let hotKeyID = EventHotKeyID(
      signature: Self.signature,
      id: Self.openHotKeyID
    )

    let status = RegisterEventHotKey(
      UInt32(kVK_ANSI_C),
      UInt32(cmdKey | shiftKey),
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
