import ClackCore
import AppKit
import SwiftUI

struct PreferencesView: View {
  static let preferredWindowSize = NSSize(width: 640, height: 430)

  @ObservedObject var preferences: ClackPreferences
  @ObservedObject var store: ClipboardHistoryStore

  @StateObject private var launchAtLoginController = LaunchAtLoginController()
  @State private var selectedPane: PreferencesPane = .general
  @State private var selectedIgnorePane: IgnorePane = .applications
  @State private var shortcutBeingRecorded: ShortcutKind?

  var body: some View {
    VStack(spacing: 0) {
      header

      Divider()

      ScrollView {
        selectedPaneContent
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
          .frame(maxWidth: .infinity, alignment: .topLeading)
      }
      .scrollIndicators(.automatic)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(width: Self.preferredWindowSize.width, height: Self.preferredWindowSize.height)
    .background(Color(nsColor: .windowBackgroundColor))
  }

  private var header: some View {
    HStack(spacing: 8) {
      ForEach(PreferencesPane.allCases) { pane in
        PreferencePaneButton(
          pane: pane,
          isSelected: selectedPane == pane
        ) {
          selectedPane = pane
        }
      }
    }
    .padding(.top, 6)
    .padding(.bottom, 6)
  }

  @ViewBuilder
  private var selectedPaneContent: some View {
    switch selectedPane {
    case .general:
      generalPane
    case .storage:
      storagePane
    case .appearance:
      appearancePane
    case .pins:
      pinsPane
    case .ignore:
      ignorePane
    case .advanced:
      advancedPane
    }
  }

  private var generalPane: some View {
    VStack(alignment: .leading, spacing: 8) {
      VStack(alignment: .leading, spacing: 4) {
        Toggle("Launch at login", isOn: launchAtLoginBinding)
        Toggle("Check for updates automatically", isOn: $preferences.checkForUpdatesAutomatically)

        HStack(spacing: 8) {
          Button("Check now") {
            openReleasesPage()
          }

          Button("Notifications and sounds") {
            openNotificationsSettings()
          }
          .buttonStyle(.link)
        }
      }
      .toggleStyle(.checkbox)
      .padding(.leading, 112)
      .onAppear {
        launchAtLoginController.sync(preferences: preferences)
      }

      if let lastError = launchAtLoginController.lastError {
        Text(lastError)
          .font(.callout)
          .foregroundStyle(.red)
          .padding(.leading, 110)
      }

      PreferenceDivider()

      VStack(alignment: .leading, spacing: 7) {
        ShortcutRow(
          title: "Open",
          shortcut: $preferences.openShortcut,
          kind: .open,
          recording: $shortcutBeingRecorded
        )
        ShortcutRow(
          title: "Pin",
          shortcut: $preferences.pinShortcut,
          kind: .pin,
          recording: $shortcutBeingRecorded
        )
        ShortcutRow(
          title: "Delete",
          shortcut: $preferences.deleteShortcut,
          kind: .delete,
          recording: $shortcutBeingRecorded
        )
      }

      PreferenceDivider()

      HStack {
        PreferenceLabel("Search")

        Picker("", selection: $preferences.searchMode) {
          ForEach(SearchMode.allCases) { mode in
            Text(mode.rawValue).tag(mode)
          }
        }
        .labelsHidden()
        .frame(width: 250)
        .accessibilityLabel("Search mode")
      }

      PreferenceDivider()

      HStack(alignment: .top, spacing: 12) {
        PreferenceLabel("Behavior")

        VStack(alignment: .leading, spacing: 5) {
          Toggle("Paste automatically", isOn: $preferences.pasteAutomatically)
          Toggle("Paste without formatting", isOn: $preferences.pasteWithoutFormatting)

          VStack(alignment: .leading, spacing: 2) {
            ForEach(behaviorHelpLines, id: \.self) { line in
              Text(line)
            }
          }
          .font(.system(size: 10))
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
        }
        .toggleStyle(.checkbox)
      }
    }
    .preferencePaneWidth()
  }

  private var storagePane: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .top, spacing: 12) {
        PreferenceLabel("Save")

        VStack(alignment: .leading, spacing: 6) {
          Toggle("Files", isOn: $preferences.saveFiles)
          Toggle("Images", isOn: $preferences.saveImages)
          Toggle("Text", isOn: $preferences.saveText)

          Text("Change what types of copied content should be stored.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .toggleStyle(.checkbox)
      }

      PreferenceDivider()

      VStack(alignment: .leading, spacing: 10) {
        HStack {
          PreferenceLabel("Limit")

          Stepper(
            value: Binding(
              get: { preferences.historyLimit },
              set: { value in
                preferences.setHistoryLimit(value)
                store.updateLimit(value)
              }
            ),
            in: ClipboardHistoryStore.minimumLimit...ClipboardHistoryStore.maximumLimit,
            step: 25
          ) {
            Text("\(preferences.historyLimit)")
              .frame(width: 88, alignment: .leading)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
          }
          .accessibilityLabel("History size")
          .accessibilityValue("\(preferences.historyLimit) items")

          Text("\(storageEstimate) stored")
            .foregroundStyle(.secondary)
        }

        HStack {
          PreferenceLabel("Sort by")

          Picker("", selection: $preferences.sortMode) {
            ForEach(SortMode.allCases) { mode in
              Text(mode.rawValue).tag(mode)
            }
          }
          .labelsHidden()
          .frame(width: 280)
          .accessibilityLabel("Sort by")
        }
      }
    }
    .preferencePaneWidth()
  }

  private var appearancePane: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 7) {
        PreferencePickerRow("Popup at", selection: $preferences.popupLocation, values: PopupLocation.allCases)
        PreferencePickerRow("Pin to", selection: $preferences.pinLocation, values: PinLocation.allCases)
        NumberRow(
          title: "Image height",
          value: Binding(
            get: { preferences.imageHeight },
            set: { preferences.imageHeight = max(24, min(160, $0)) }
          ),
          range: 24...160,
          step: 4
        )
        NumberRow(
          title: "Preview delay",
          value: Binding(
            get: { preferences.previewDelayMilliseconds },
            set: { preferences.previewDelayMilliseconds = max(0, min(5_000, $0)) }
          ),
          range: 0...5_000,
          step: 100
        )
        PreferencePickerRow("Highlight matches", selection: $preferences.highlightStyle, values: HighlightStyle.allCases)
      }

      PreferenceDivider()

      VStack(alignment: .leading, spacing: 6) {
        Toggle("Show menu icon", isOn: $preferences.showMenuIcon)
        Toggle("Show recent copy next to menu icon", isOn: $preferences.showRecentCopyInMenuBar)

        HStack {
          Toggle("Show search field", isOn: searchFieldToggle)

          Picker("", selection: $preferences.searchFieldVisibility) {
            ForEach(SearchFieldVisibility.allCases) { visibility in
              Text(visibility.rawValue).tag(visibility)
            }
          }
          .labelsHidden()
          .frame(width: 190)
          .accessibilityLabel("Search field visibility")
        }

        Toggle("Show special symbols", isOn: $preferences.showSpecialSymbols)
        Toggle("Show title before search field", isOn: $preferences.showTitleBeforeSearchField)
        Toggle("Show application icons", isOn: $preferences.showApplicationIcons)
        Toggle("Show footer", isOn: $preferences.showFooter)
      }
      .toggleStyle(.checkbox)
      .padding(.leading, 150)
    }
    .preferencePaneWidth()
  }

  private var pinsPane: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("Key")
          .frame(width: 90, alignment: .leading)
        Divider()
        Text("Title")
          .frame(width: 320, alignment: .leading)
        Divider()
        Text("Content")
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .font(.headline)
      .padding(.horizontal, 10)

      Divider()

      VStack(spacing: 14) {
        if pinnedItems.isEmpty {
          ForEach(0..<7, id: \.self) { _ in
            RoundedRectangle(cornerRadius: 10)
              .fill(Color(nsColor: .controlBackgroundColor))
              .frame(height: 26)
          }
        } else {
          ForEach(Array(pinnedItems.enumerated()), id: \.element.id) { index, item in
            PinnedItemRow(index: index, item: item)
          }
        }
      }

      Spacer(minLength: 8)

      Text("Pinned items stay in history when clearing unpinned items.")
        .font(.callout)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, minHeight: 300, alignment: .topLeading)
  }

  private var ignorePane: some View {
    VStack(alignment: .leading, spacing: 10) {
      Picker("", selection: $selectedIgnorePane) {
        ForEach(IgnorePane.allCases) { pane in
          Text(pane.title).tag(pane)
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()
      .frame(width: 520)
      .frame(maxWidth: .infinity)
      .accessibilityLabel("Ignore category")

      Group {
        switch selectedIgnorePane {
        case .applications:
          ListEditor(
            values: preferences.ignoredApplications,
            placeholder: "Application name",
            add: preferences.addIgnoredApplication,
            remove: preferences.removeIgnoredApplication,
            reset: preferences.resetIgnoredApplications
          )

          Toggle("Ignore all applications except listed", isOn: $preferences.ignoreAllApplicationsExceptListed)
            .toggleStyle(.checkbox)

          Text("Application matching uses the frontmost app name reported by macOS.")
            .font(.callout)
            .foregroundStyle(.secondary)

        case .pasteboardTypes:
          ListEditor(
            values: preferences.ignoredPasteboardTypes,
            placeholder: "Pasteboard type",
            add: preferences.addIgnoredPasteboardType,
            remove: preferences.removeIgnoredPasteboardType,
            reset: preferences.resetIgnoredPasteboardTypes
          )

          Text("Defaults include transient and password-manager pasteboard types.")
            .font(.callout)
            .foregroundStyle(.secondary)

        case .regularExpressions:
          ListEditor(
            values: preferences.ignoredRegularExpressions,
            placeholder: "Regular expression",
            add: preferences.addIgnoredRegularExpression,
            remove: preferences.removeIgnoredRegularExpression,
            reset: preferences.resetIgnoredRegularExpressions
          )

          Text("Expressions are matched against copied text before it is stored.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }
      .padding(12)
      .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
    }
    .frame(maxWidth: .infinity, minHeight: 300, alignment: .topLeading)
  }

  private var advancedPane: some View {
    VStack(alignment: .leading, spacing: 10) {
      Toggle("Turn off", isOn: $preferences.temporarilyIgnoreNewCopies)
        .toggleStyle(.checkbox)
        .font(.body)

      Text("Temporarily ignore all new copies.")
        .font(.callout)
        .foregroundStyle(.secondary)

      VStack(alignment: .leading, spacing: 4) {
        Text("defaults write com.jadanjones.Clack temporarilyIgnoreNewCopies true")
        Text("# copy data")
        Text("defaults write com.jadanjones.Clack temporarilyIgnoreNewCopies false")
        Text("defaults write com.jadanjones.Clack ignoreOnlyNextCopy true")
        Text("# copy data")
      }
      .font(.system(size: 12, design: .monospaced))
      .foregroundStyle(.secondary)

      PreferenceDivider()

      Toggle("Clear history on quit", isOn: $preferences.clearHistoryOnQuit)
      Toggle("Clear the system clipboard too", isOn: $preferences.clearSystemClipboardOnQuit)
    }
    .toggleStyle(.checkbox)
    .preferencePaneWidth()
  }

  private var searchFieldToggle: Binding<Bool> {
    Binding(
      get: { preferences.searchFieldVisibility != .never },
      set: { isOn in
        preferences.searchFieldVisibility = isOn ? .always : .never
      }
    )
  }

  private var launchAtLoginBinding: Binding<Bool> {
    Binding(
      get: { preferences.launchAtLogin },
      set: { isEnabled in
        launchAtLoginController.setEnabled(isEnabled, preferences: preferences)
      }
    )
  }

  private var pinnedItems: [ClipboardItem] {
    store.items.filter(\.isPinned)
  }

  private var storageEstimate: String {
    let bytes = store.items.reduce(0) { result, item in
      result + item.byteCount
    }

    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: Int64(bytes))
  }

  private var pasteboardStringType: String {
    "public.utf8-plain-text"
  }

  private var behaviorHelpLines: [String] {
    switch (preferences.pasteAutomatically, preferences.pasteWithoutFormatting) {
    case (false, false):
      [
        "Select with ⌘ pressed to copy item.",
        "Select with ⌥ pressed to copy and paste item.",
        "Select with ⇧⌘ pressed to copy, clear formatting, and paste item."
      ]
    case (true, false):
      [
        "Select with ⌥ pressed to copy item.",
        "Select with ⌘ pressed to copy and paste item.",
        "Select with ⇧⌘ pressed to copy, clear formatting, and paste item."
      ]
    case (false, true):
      [
        "Select with ⌘ pressed to copy item.",
        "Select with ⇧⌥ pressed to copy and paste item.",
        "Select with ⌥ pressed to copy, clear formatting, and paste item."
      ]
    case (true, true):
      [
        "Select with ⌥ pressed to copy item.",
        "Select with ⇧⌘ pressed to copy and paste item.",
        "Select with ⌘ pressed to copy, clear formatting, and paste item."
      ]
    }
  }

  private func openReleasesPage() {
    guard let url = URL(string: "https://github.com/In-sp3ctr3/clack/releases") else {
      return
    }

    NSWorkspace.shared.open(url)
  }

  private func openNotificationsSettings() {
    let urls = [
      "x-apple.systempreferences:com.apple.Notifications-Settings.extension",
      "x-apple.systempreferences:com.apple.preference.notifications"
    ]

    for value in urls {
      guard let url = URL(string: value), NSWorkspace.shared.open(url) else {
        continue
      }

      return
    }
  }
}

private enum PreferencesPane: String, CaseIterable, Identifiable {
  case general
  case storage
  case appearance
  case pins
  case ignore
  case advanced

  var id: String { rawValue }

  var title: String {
    switch self {
    case .general: "General"
    case .storage: "Storage"
    case .appearance: "Appearance"
    case .pins: "Pins"
    case .ignore: "Ignore"
    case .advanced: "Advanced"
    }
  }

  var symbol: String {
    switch self {
    case .general: "gearshape"
    case .storage: "externaldrive"
    case .appearance: "paintpalette"
    case .pins: "pin.circle"
    case .ignore: "nosign"
    case .advanced: "gearshape.2"
    }
  }
}

private enum IgnorePane: String, CaseIterable, Identifiable {
  case applications
  case pasteboardTypes
  case regularExpressions

  var id: String { rawValue }

  var title: String {
    switch self {
    case .applications: "Applications"
    case .pasteboardTypes: "Pasteboard types"
    case .regularExpressions: "Regular expressions"
    }
  }
}

private struct PreferencePaneButton: View {
  let pane: PreferencesPane
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Image(systemName: pane.symbol)
          .font(.system(size: 20, weight: .regular))
        Text(pane.title)
          .font(.system(size: 12))
      }
      .foregroundStyle(isSelected ? .blue : .secondary)
      .frame(width: 82, height: 50)
      .background(
        RoundedRectangle(cornerRadius: 10)
          .fill(isSelected ? Color(nsColor: .controlBackgroundColor) : .clear)
          .shadow(color: isSelected ? .black.opacity(0.08) : .clear, radius: 18, y: 8)
      )
    }
    .buttonStyle(.plain)
    .accessibilityLabel(pane.title)
    .accessibilityValue(isSelected ? "Selected" : "Not selected")
    .accessibilityHint("Show \(pane.title) preferences.")
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

private struct PreferenceDivider: View {
  var body: some View {
    Divider()
      .padding(.vertical, 1)
  }
}

private struct PreferenceLabel: View {
  let title: String

  init(_ title: String) {
    self.title = title
  }

  var body: some View {
    Text("\(title):")
      .frame(width: 112, alignment: .trailing)
  }
}

private struct PreferencePickerRow<Value: RawRepresentable & CaseIterable & Hashable & Identifiable>: View where
  Value.RawValue == String,
  Value.AllCases: RandomAccessCollection,
  Value.AllCases.Element == Value
{
  let title: String
  @Binding var selection: Value
  let values: Value.AllCases

  init(_ title: String, selection: Binding<Value>, values: Value.AllCases) {
    self.title = title
    self._selection = selection
    self.values = values
  }

  var body: some View {
    HStack {
      PreferenceLabel(title)

      Picker("", selection: $selection) {
        ForEach(values) { value in
          Text(value.rawValue).tag(value)
        }
      }
      .labelsHidden()
      .frame(width: 220)
      .accessibilityLabel(title)
    }
  }
}

private struct NumberRow: View {
  let title: String
  @Binding var value: Int
  let range: ClosedRange<Int>
  let step: Int

  var body: some View {
    HStack {
      PreferenceLabel(title)

      Stepper(value: $value, in: range, step: step) {
        Text("\(value)")
          .frame(width: 72, alignment: .leading)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
      }
    }
  }
}

private enum ShortcutKind: String, Identifiable {
  case open
  case pin
  case delete

  var id: String { rawValue }
}

private struct ShortcutRow: View {
  let title: String
  @Binding var shortcut: ClackKeyboardShortcut
  let kind: ShortcutKind
  @Binding var recording: ShortcutKind?

  var body: some View {
    HStack {
      PreferenceLabel(title)

      Button(recording == kind ? "Type shortcut" : shortcut.display) {
        recording = kind
      }
      .frame(width: 150)
      .controlSize(.small)
      .background(
        ShortcutCaptureMonitor(
          isRecording: recording == kind,
          capture: { event in
            shortcut = event.clackKeyboardShortcut
            recording = nil
          },
          cancel: {
            recording = nil
          }
        )
        .frame(width: 0, height: 0)
      )

      Button {
        shortcut = defaultShortcut
      } label: {
        Image(systemName: "arrow.counterclockwise")
      }
      .buttonStyle(.borderless)
      .accessibilityLabel("Reset \(title) shortcut")
    }
    .frame(height: 28)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(title) shortcut")
    .accessibilityValue(shortcut.display)
  }

  private var defaultShortcut: ClackKeyboardShortcut {
    switch kind {
    case .open:
      .openDefault
    case .pin:
      .pinDefault
    case .delete:
      .deleteDefault
    }
  }
}

private struct ShortcutCaptureMonitor: NSViewRepresentable {
  let isRecording: Bool
  let capture: (NSEvent) -> Void
  let cancel: () -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(capture: capture, cancel: cancel)
  }

  func makeNSView(context: Context) -> NSView {
    NSView()
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    context.coordinator.capture = capture
    context.coordinator.cancel = cancel
    isRecording ? context.coordinator.start() : context.coordinator.stop()
  }

  static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
    coordinator.stop()
  }

  final class Coordinator {
    var capture: (NSEvent) -> Void
    var cancel: () -> Void
    private var monitor: Any?

    init(capture: @escaping (NSEvent) -> Void, cancel: @escaping () -> Void) {
      self.capture = capture
      self.cancel = cancel
    }

    func start() {
      guard monitor == nil else {
        return
      }

      monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
        guard let self else {
          return event
        }

        if event.keyCode == 53 {
          cancel()
          return nil
        }

        guard event.modifierFlags.abstractShortcutModifiers != 0 else {
          return event
        }

        capture(event)
        return nil
      }
    }

    func stop() {
      guard let monitor else {
        return
      }

      NSEvent.removeMonitor(monitor)
      self.monitor = nil
    }
  }
}

private extension NSEvent {
  var clackKeyboardShortcut: ClackKeyboardShortcut {
    ClackKeyboardShortcut(
      keyCode: Int(keyCode),
      character: shortcutCharacter,
      modifiers: modifierFlags.abstractShortcutModifiers
    )
  }

  private var shortcutCharacter: String {
    if keyCode == 51 || keyCode == 117 {
      return "⌫"
    }

    if keyCode == 36 || keyCode == 76 {
      return "↩"
    }

    return (charactersIgnoringModifiers ?? "").uppercased()
  }
}

private extension NSEvent.ModifierFlags {
  var abstractShortcutModifiers: Int {
    var result = 0

    if contains(.command) {
      result |= ClackKeyboardShortcut.command
    }

    if contains(.shift) {
      result |= ClackKeyboardShortcut.shift
    }

    if contains(.option) {
      result |= ClackKeyboardShortcut.option
    }

    if contains(.control) {
      result |= ClackKeyboardShortcut.control
    }

    return result
  }
}

private struct PinnedItemRow: View {
  let index: Int
  let item: ClipboardItem

  var body: some View {
    HStack(spacing: 12) {
      Text("⌘\(min(index + 1, 9))")
        .frame(width: 76, alignment: .leading)
      Text(item.preview)
        .frame(width: 320, alignment: .leading)
        .lineLimit(1)
      Text(item.detailText)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineLimit(1)
    }
    .padding(.horizontal, 16)
    .frame(height: 28)
    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(item.preview)
    .accessibilityValue("Pinned item, Command \(min(index + 1, 9))")
  }
}

private struct ListEditor: View {
  let values: [String]
  let placeholder: String
  let add: (String) -> Void
  let remove: (String) -> Void
  let reset: () -> Void

  @State private var draft = ""

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      ScrollView {
        VStack(spacing: 6) {
          if values.isEmpty {
            RoundedRectangle(cornerRadius: 8)
              .fill(Color(nsColor: .textBackgroundColor))
              .frame(height: 132)
              .accessibilityHidden(true)
          } else {
            ForEach(values, id: \.self) { value in
              HStack {
                Text(value)
                  .lineLimit(1)
                Spacer()
                Button {
                  remove(value)
                } label: {
                  Image(systemName: "minus")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Remove \(value)")
              }
              .padding(.horizontal, 10)
              .frame(height: 26)
              .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            }
          }
        }
      }
      .frame(height: 158)

      HStack(spacing: 8) {
        TextField(placeholder, text: $draft)
          .textFieldStyle(.roundedBorder)
          .accessibilityLabel("New \(placeholder.lowercased())")

        Button {
          add(draft)
          draft = ""
        } label: {
          Image(systemName: "plus")
        }
        .keyboardShortcut(.defaultAction)
        .accessibilityLabel("Add \(placeholder.lowercased())")

        Button {
          if let last = values.last {
            remove(last)
          }
        } label: {
          Image(systemName: "minus")
        }
        .disabled(values.isEmpty)
        .accessibilityLabel("Remove last \(placeholder.lowercased())")

        Button("Reset") {
          reset()
        }
        .accessibilityLabel("Reset \(placeholder.lowercased()) list")
      }
    }
  }
}

private extension View {
  func preferencePaneWidth() -> some View {
    frame(maxWidth: 590, alignment: .topLeading)
  }
}
