import ClackCore
import SwiftUI

struct PreferencesView: View {
  @ObservedObject var preferences: ClackPreferences
  @ObservedObject var store: ClipboardHistoryStore

  @StateObject private var launchAtLoginController = LaunchAtLoginController()
  @State private var selectedPane: PreferencesPane = .general
  @State private var selectedIgnorePane: IgnorePane = .applications

  var body: some View {
    VStack(spacing: 0) {
      header

      Divider()

      ScrollView {
        selectedPaneContent
          .padding(26)
          .frame(maxWidth: .infinity, alignment: .topLeading)
      }
    }
    .frame(minWidth: 840, minHeight: 620)
    .background(Color(nsColor: .windowBackgroundColor))
  }

  private var header: some View {
    VStack(spacing: 14) {
      Text(selectedPane.title)
        .font(.title2.weight(.semibold))
        .foregroundStyle(.primary)

      HStack(spacing: 18) {
        ForEach(PreferencesPane.allCases) { pane in
          PreferencePaneButton(
            pane: pane,
            isSelected: selectedPane == pane
          ) {
            selectedPane = pane
          }
        }
      }
    }
    .padding(.top, 12)
    .padding(.bottom, 14)
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
    VStack(alignment: .leading, spacing: 24) {
      VStack(alignment: .leading, spacing: 10) {
        Toggle("Launch at login", isOn: launchAtLoginBinding)
        Toggle("Check for updates automatically", isOn: $preferences.checkForUpdatesAutomatically)
          .disabled(true)

        Button("Check now") {}
          .disabled(true)

        Text("Open shortcut: Shift-Command-C")
          .font(.callout)
          .foregroundStyle(.secondary)
      }
      .toggleStyle(.checkbox)
      .padding(.leading, 110)
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

      VStack(alignment: .leading, spacing: 12) {
        ShortcutRow(title: "Open", shortcut: "⇧⌘C")
        ShortcutRow(title: "Pin", shortcut: "⌥P")
        ShortcutRow(title: "Delete", shortcut: "⌥⌫")
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
      }

      PreferenceDivider()

      HStack(alignment: .top, spacing: 12) {
        PreferenceLabel("Behavior")

        VStack(alignment: .leading, spacing: 10) {
          Toggle("Paste automatically", isOn: .constant(false))
            .disabled(true)
          Toggle("Paste without formatting", isOn: .constant(false))
            .disabled(true)

          Text("Selecting an item copies it back to the clipboard.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .toggleStyle(.checkbox)
      }

      PreferenceDivider()

      Button("Notifications and sounds") {}
        .buttonStyle(.plain)
        .foregroundStyle(.blue)
        .padding(.leading, 110)
        .disabled(true)
    }
    .preferencePaneWidth()
  }

  private var storagePane: some View {
    VStack(alignment: .leading, spacing: 28) {
      HStack(alignment: .top, spacing: 12) {
        PreferenceLabel("Save")

        VStack(alignment: .leading, spacing: 8) {
          Toggle("Files", isOn: $preferences.saveFiles)
            .disabled(true)
          Toggle("Images", isOn: $preferences.saveImages)
            .disabled(true)
          Toggle("Text", isOn: $preferences.saveText)

          Text("Choose which copied content Clack stores.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .toggleStyle(.checkbox)
      }

      PreferenceDivider()

      VStack(alignment: .leading, spacing: 16) {
        HStack {
          PreferenceLabel("Size")

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

          Text(storageEstimate)
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
        }
      }
    }
    .preferencePaneWidth()
  }

  private var appearancePane: some View {
    VStack(alignment: .leading, spacing: 24) {
      VStack(alignment: .leading, spacing: 12) {
        PreferencePickerRow("Popup at", selection: $preferences.popupLocation, values: PopupLocation.allCases)
        PreferencePickerRow("Pin to", selection: $preferences.pinLocation, values: PinLocation.allCases)
        NumberRow(title: "Image height", value: $preferences.imageHeight, range: 16...240, step: 4)
        NumberRow(title: "Preview delay", value: $preferences.previewDelayMilliseconds, range: 0...5_000, step: 100)
        PreferencePickerRow("Highlight matches", selection: $preferences.highlightStyle, values: HighlightStyle.allCases)
      }

      PreferenceDivider()

      VStack(alignment: .leading, spacing: 10) {
        Toggle("Show special symbols", isOn: $preferences.showSpecialSymbols)

        HStack {
          Toggle("Show menu icon", isOn: $preferences.showMenuIcon)

          Picker("", selection: $preferences.menuIconSymbol) {
            Text("Clipboard").tag("doc.on.clipboard")
            Text("Document").tag("doc.text")
            Text("Paperclip").tag("paperclip")
          }
          .labelsHidden()
          .frame(width: 150)
        }

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
        }

        Toggle("Show title before search field", isOn: $preferences.showTitleBeforeSearchField)
        Toggle("Show application icons", isOn: $preferences.showApplicationIcons)
        Toggle("Show footer", isOn: $preferences.showFooter)
      }
      .toggleStyle(.checkbox)
      .padding(.leading, 190)
    }
    .preferencePaneWidth()
  }

  private var pinsPane: some View {
    VStack(alignment: .leading, spacing: 18) {
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
              .frame(height: 38)
          }
        } else {
          ForEach(Array(pinnedItems.enumerated()), id: \.element.id) { index, item in
            PinnedItemRow(index: index, item: item)
          }
        }
      }

      Spacer(minLength: 18)

      Text("Pinned items stay in history when clearing unpinned items. Only plain text can be changed in this version.")
        .font(.callout)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, minHeight: 430, alignment: .topLeading)
  }

  private var ignorePane: some View {
    VStack(alignment: .leading, spacing: 18) {
      Picker("", selection: $selectedIgnorePane) {
        ForEach(IgnorePane.allCases) { pane in
          Text(pane.title).tag(pane)
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()
      .frame(width: 610)
      .frame(maxWidth: .infinity)

      Group {
        switch selectedIgnorePane {
        case .applications:
          ListEditor(
            values: preferences.ignoredApplications,
            placeholder: "Application name",
            add: preferences.addIgnoredApplication,
            remove: preferences.removeIgnoredApplication
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
            remove: preferences.removeIgnoredPasteboardType
          )

          Text("Example: \(pasteboardStringType)")
            .font(.callout)
            .foregroundStyle(.secondary)

        case .regularExpressions:
          ListEditor(
            values: preferences.ignoredRegularExpressions,
            placeholder: "Regular expression",
            add: preferences.addIgnoredRegularExpression,
            remove: preferences.removeIgnoredRegularExpression
          )

          Text("Expressions are matched against copied text before it is stored.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }
      .padding(22)
      .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
    }
    .frame(maxWidth: .infinity, minHeight: 430, alignment: .topLeading)
  }

  private var advancedPane: some View {
    VStack(alignment: .leading, spacing: 18) {
      Toggle("Turn off", isOn: $preferences.temporarilyIgnoreNewCopies)
        .toggleStyle(.checkbox)
        .font(.title3)

      Text("Temporarily ignore all new copies.")
        .font(.callout)
        .foregroundStyle(.secondary)

      VStack(alignment: .leading, spacing: 8) {
        Text("defaults write com.jadanjones.Clack temporarilyIgnoreNewCopies true")
        Text("# copy data")
        Text("defaults write com.jadanjones.Clack temporarilyIgnoreNewCopies false")
        Text("defaults write com.jadanjones.Clack ignoreOnlyNextCopy true")
        Text("# copy data")
      }
      .font(.system(.body, design: .monospaced))
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
          .font(.system(size: 31, weight: .regular))
        Text(pane.title)
          .font(.body)
      }
      .foregroundStyle(isSelected ? .blue : .secondary)
      .frame(width: 96, height: 84)
      .background(
        RoundedRectangle(cornerRadius: 10)
          .fill(isSelected ? Color(nsColor: .controlBackgroundColor) : .clear)
          .shadow(color: isSelected ? .black.opacity(0.08) : .clear, radius: 18, y: 8)
      )
    }
    .buttonStyle(.plain)
  }
}

private struct PreferenceDivider: View {
  var body: some View {
    Divider()
      .padding(.vertical, 4)
  }
}

private struct PreferenceLabel: View {
  let title: String

  init(_ title: String) {
    self.title = title
  }

  var body: some View {
    Text("\(title):")
      .frame(width: 150, alignment: .trailing)
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
      .frame(width: 260)
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
          .frame(width: 92, alignment: .leading)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
      }
    }
  }
}

private struct ShortcutRow: View {
  let title: String
  let shortcut: String

  var body: some View {
    HStack {
      PreferenceLabel(title)

      HStack {
        Text(shortcut)
          .font(.title3)
        Spacer()
        Image(systemName: "xmark.circle.fill")
          .foregroundStyle(.secondary)
      }
      .frame(width: 210)
      .padding(.horizontal, 14)
      .padding(.vertical, 8)
      .background(.quaternary, in: Capsule())
    }
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
      Text(item.content)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineLimit(1)
    }
    .padding(.horizontal, 16)
    .frame(height: 38)
    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
  }
}

private struct ListEditor: View {
  let values: [String]
  let placeholder: String
  let add: (String) -> Void
  let remove: (String) -> Void

  @State private var draft = ""

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      ScrollView {
        VStack(spacing: 8) {
          if values.isEmpty {
            RoundedRectangle(cornerRadius: 8)
              .fill(Color(nsColor: .textBackgroundColor))
              .frame(height: 220)
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
              }
              .padding(.horizontal, 10)
              .frame(height: 32)
              .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            }
          }
        }
      }
      .frame(height: 270)

      HStack(spacing: 8) {
        TextField(placeholder, text: $draft)
          .textFieldStyle(.roundedBorder)

        Button {
          add(draft)
          draft = ""
        } label: {
          Image(systemName: "plus")
        }
        .keyboardShortcut(.defaultAction)

        Button {
          if let last = values.last {
            remove(last)
          }
        } label: {
          Image(systemName: "minus")
        }
        .disabled(values.isEmpty)
      }
    }
  }
}

private extension View {
  func preferencePaneWidth() -> some View {
    frame(maxWidth: 760, alignment: .topLeading)
  }
}
