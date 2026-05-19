import ClackCore

struct ClipboardActions {
  let restore: (ClipboardItem) -> Void
  let togglePin: (ClipboardItem) -> Void
  let delete: (ClipboardItem) -> Void
  let clearUnpinned: () -> Void
  let showPreferences: () -> Void
  let showAbout: () -> Void
  let quit: () -> Void
}
