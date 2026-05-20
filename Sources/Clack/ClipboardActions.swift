import ClackCore

struct ClipboardRestoreOptions {
  var pasteAfterRestore = false
  var plainTextOnly = false
}

struct ClipboardActions {
  let restore: (ClipboardItem, ClipboardRestoreOptions) -> Void
  let togglePin: (ClipboardItem) -> Void
  let delete: (ClipboardItem) -> Void
  let clearUnpinned: () -> Void
  let showPreferences: () -> Void
  let showAbout: () -> Void
  let quit: () -> Void
}
