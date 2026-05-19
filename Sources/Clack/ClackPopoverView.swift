import ClackCore
import AppKit
import SwiftUI

struct ClackPopoverView: View {
  @ObservedObject var store: ClipboardHistoryStore
  @ObservedObject var preferences: ClackPreferences

  let actions: ClipboardActions

  @FocusState private var searchFocused: Bool
  @State private var selectedItemID: ClipboardItem.ID?

  private var visibleItems: [ClipboardItem] {
    let filteredItems = store.items.filter {
      $0.matches(store.searchText, mode: preferences.searchMode)
    }

    return sortedItems(filteredItems)
  }

  private var visibleItemIDs: [ClipboardItem.ID] {
    visibleItems.map(\.id)
  }

  private var selectedItem: ClipboardItem? {
    if let selectedItemID, let selectedItem = visibleItems.first(where: { $0.id == selectedItemID }) {
      return selectedItem
    }

    return visibleItems.first
  }

  var body: some View {
    VStack(spacing: 0) {
      if showsSearchField {
        searchBar

        Divider()
      }

      itemList

      Divider()

      DetailPane(
        item: selectedItem,
        preferences: preferences,
        actions: actions
      )

      if preferences.showFooter {
        Divider()

        footer
      }
    }
    .frame(width: 460, height: 620)
    .background(Color(nsColor: .windowBackgroundColor))
    .background(
      KeyboardNavigationMonitor(
        moveSelection: moveSelection,
        restoreSelection: restoreSelectedItem
      )
      .frame(width: 0, height: 0)
      .accessibilityHidden(true)
    )
    .onAppear {
      searchFocused = true
      syncSelectionWithVisibleItems()
    }
    .onChange(of: visibleItemIDs) { _ in
      syncSelectionWithVisibleItems()
    }
  }

  private var searchBar: some View {
    HStack(spacing: 8) {
      if preferences.showTitleBeforeSearchField {
        Text("Clack")
          .font(.headline)
      }

      Image(systemName: "magnifyingglass")
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)

      TextField("Search", text: $store.searchText)
        .textFieldStyle(.plain)
        .focused($searchFocused)
        .onSubmit(restoreSelectedItem)
        .accessibilityLabel("Search clipboard history")
        .accessibilityHint("Type to filter saved clipboard items. Press Return to restore the selected item.")

      if !store.searchText.isEmpty {
        Button {
          store.searchText = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityLabel("Clear search")
        .help("Clear search")
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
  }

  @ViewBuilder
  private var itemList: some View {
    if visibleItems.isEmpty {
      VStack {
        Spacer()
        Text("No clipboard items")
          .foregroundStyle(.secondary)
        Spacer()
      }
      .frame(maxWidth: .infinity)
    } else {
      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
            shortcutRow(item: item, index: index)

            if item.id != visibleItems.last?.id {
              Divider()
                .padding(.leading, 42)
            }
          }
        }
      }
    }
  }

  @ViewBuilder
  private func shortcutRow(item: ClipboardItem, index: Int) -> some View {
    if index < 9 {
      ClipboardRow(
        item: item,
        shortcutNumber: index + 1,
        isSelected: selectedItem?.id == item.id,
        showIcon: preferences.showApplicationIcons,
        imageHeight: preferences.imageHeight,
        restore: { actions.restore(item) },
        togglePin: { actions.togglePin(item) },
        delete: { actions.delete(item) },
        onHover: { isHovering in
          if isHovering {
            selectedItemID = item.id
          }
        }
      )
      .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: [.command])
    } else {
      ClipboardRow(
        item: item,
        shortcutNumber: nil,
        isSelected: selectedItem?.id == item.id,
        showIcon: preferences.showApplicationIcons,
        imageHeight: preferences.imageHeight,
        restore: { actions.restore(item) },
        togglePin: { actions.togglePin(item) },
        delete: { actions.delete(item) },
        onHover: { isHovering in
          if isHovering {
            selectedItemID = item.id
          }
        }
      )
    }
  }

  private var footer: some View {
    HStack(spacing: 10) {
      Button {
        actions.clearUnpinned()
      } label: {
        Label("Clear", systemImage: "trash")
      }
      .keyboardShortcut("k", modifiers: [.command, .shift])
      .disabled(store.items.allSatisfy(\.isPinned))
      .accessibilityHint("Clears every unpinned clipboard item.")

      Spacer()

      Button {
        actions.showPreferences()
      } label: {
        Image(systemName: "gearshape")
      }
      .keyboardShortcut(",", modifiers: [.command])
      .accessibilityLabel("Preferences")
      .accessibilityHint("Open Clack preferences.")
      .help("Preferences")

      Button {
        actions.showAbout()
      } label: {
        Image(systemName: "info.circle")
      }
      .accessibilityLabel("About Clack")
      .accessibilityHint("Open the About window.")
      .help("About Clack")

      Button {
        actions.quit()
      } label: {
        Image(systemName: "power")
      }
      .keyboardShortcut("q", modifiers: [.command])
      .accessibilityLabel("Quit Clack")
      .accessibilityHint("Quit the Clack app.")
      .help("Quit Clack")
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
  }

  private var showsSearchField: Bool {
    switch preferences.searchFieldVisibility {
    case .always:
      true
    case .whenHistoryExists:
      !store.items.isEmpty || !store.searchText.isEmpty
    case .never:
      false
    }
  }

  private func sortedItems(_ items: [ClipboardItem]) -> [ClipboardItem] {
    items.sorted { lhs, rhs in
      if lhs.isPinned != rhs.isPinned {
        return preferences.pinLocation == .top ? lhs.isPinned : !lhs.isPinned
      }

      switch preferences.sortMode {
      case .lastCopied:
        return lhs.lastCopiedAt > rhs.lastCopiedAt
      case .firstCopied:
        return lhs.firstCopiedAt > rhs.firstCopiedAt
      case .copyCount:
        return lhs.copyCount > rhs.copyCount
      case .content:
        return lhs.preview.localizedCaseInsensitiveCompare(rhs.preview) == .orderedAscending
      }
    }
  }

  private func moveSelection(_ direction: SelectionDirection) {
    guard !visibleItems.isEmpty else {
      selectedItemID = nil
      return
    }

    let currentIndex = selectedItemID.flatMap { selectedID in
      visibleItems.firstIndex { $0.id == selectedID }
    }

    let nextIndex: Int
    switch direction {
    case .up:
      nextIndex = max((currentIndex ?? visibleItems.count) - 1, 0)
    case .down:
      nextIndex = min((currentIndex ?? -1) + 1, visibleItems.count - 1)
    }

    selectedItemID = visibleItems[nextIndex].id
  }

  private func restoreSelectedItem() {
    guard let selectedItem else {
      return
    }

    actions.restore(selectedItem)
  }

  private func syncSelectionWithVisibleItems() {
    guard !visibleItems.isEmpty else {
      selectedItemID = nil
      return
    }

    guard
      let selectedItemID,
      visibleItems.contains(where: { $0.id == selectedItemID })
    else {
      selectedItemID = visibleItems.first?.id
      return
    }
  }
}

private struct ClipboardRow: View {
  let item: ClipboardItem
  let shortcutNumber: Int?
  let isSelected: Bool
  let showIcon: Bool
  let imageHeight: Int
  let restore: () -> Void
  let togglePin: () -> Void
  let delete: () -> Void
  let onHover: (Bool) -> Void

  var body: some View {
    Button(action: restore) {
      HStack(alignment: .top, spacing: 10) {
        if let thumbnailImage {
          Image(nsImage: thumbnailImage)
            .resizable()
            .scaledToFill()
            .frame(width: thumbnailSideLength, height: thumbnailSideLength)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .accessibilityHidden(true)
        } else if showIcon || item.isPinned {
          Image(systemName: item.isPinned ? "pin.fill" : item.kind.systemImageName)
            .frame(width: 18)
            .foregroundStyle(item.isPinned ? .blue : .secondary)
        }

        VStack(alignment: .leading, spacing: 5) {
          Text(item.preview)
            .font(.body)
            .foregroundStyle(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)

          HStack(spacing: 8) {
            Text(item.kind.rawValue)
            Text(item.sourceApp ?? "Unknown")
            Text(relativeDateFormatter.localizedString(for: item.lastCopiedAt, relativeTo: Date()))
            Text(copyCountText)
          }
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
        }

        Spacer(minLength: 8)

        if let shortcutNumber {
          Text("⌘\(shortcutNumber)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .contentShape(Rectangle())
      .padding(.horizontal, 12)
      .padding(.vertical, 9)
      .background(rowBackground)
    }
    .buttonStyle(.plain)
    .onHover(perform: onHover)
    .contextMenu {
      Button(item.isPinned ? "Unpin" : "Pin") {
        togglePin()
      }

      Button("Delete", role: .destructive) {
        delete()
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(item.preview)
    .accessibilityValue(accessibilityValue)
    .accessibilityHint("Press Return to restore this item to the clipboard.")
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  private var copyCountText: String {
    item.copyCount == 1 ? "1 copy" : "\(item.copyCount) copies"
  }

  private var thumbnailImage: NSImage? {
    guard
      item.kind == .image,
      let imageData = item.imageData
    else {
      return nil
    }

    return NSImage(data: imageData)
  }

  private var thumbnailSideLength: CGFloat {
    CGFloat(max(24, min(120, imageHeight)))
  }

  private var accessibilityValue: String {
    var details = [
      item.kind.rawValue,
      item.sourceApp ?? "Unknown source",
      relativeDateFormatter.localizedString(for: item.lastCopiedAt, relativeTo: Date()),
      copyCountText
    ]

    if item.isPinned {
      details.append("Pinned")
    }

    if isSelected {
      details.append("Selected")
    }

    if let shortcutNumber {
      details.append("Command \(shortcutNumber)")
    }

    return details.joined(separator: ", ")
  }

  @ViewBuilder
  private var rowBackground: some View {
    if isSelected {
      RoundedRectangle(cornerRadius: 6)
        .fill(Color.accentColor.opacity(0.14))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
    }
  }
}

private struct DetailPane: View {
  let item: ClipboardItem?
  let preferences: ClackPreferences
  let actions: ClipboardActions

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if let item {
        HStack(spacing: 8) {
          Label(item.sourceApp ?? "Unknown", systemImage: "app.dashed")
          Spacer()
          Text(payloadCountText(item))
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)

        payloadPreview(item)
        .frame(height: 96)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))

        HStack(spacing: 12) {
          MetadataLabel(title: "First", date: item.firstCopiedAt)
          MetadataLabel(title: "Last", date: item.lastCopiedAt)
          Text(item.copyCount == 1 ? "1 copy" : "\(item.copyCount) copies")
          Text(item.kind.rawValue)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)

        metadataLine(item)
          .font(.caption)
          .foregroundStyle(.secondary)

        HStack {
          Button {
            actions.togglePin(item)
          } label: {
            Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin")
          }
          .keyboardShortcut("p", modifiers: [.command])

          Button(role: .destructive) {
            actions.delete(item)
          } label: {
            Label("Delete", systemImage: "delete.left")
          }
          .keyboardShortcut(.delete, modifiers: [.command])

          Spacer()
        }
      } else {
        Text("No selection")
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .padding(12)
    .frame(height: 220)
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Selected clipboard item details")
  }

  @ViewBuilder
  private func payloadPreview(_ item: ClipboardItem) -> some View {
    switch item.kind {
    case .text:
      ScrollView {
        Text(item.content)
          .font(.system(.body, design: .monospaced))
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(10)
          .accessibilityLabel("Full clipboard content")
      }
    case .file:
      ScrollView {
        VStack(alignment: .leading, spacing: 6) {
          ForEach(item.fileURLs, id: \.self) { path in
            Label(URL(fileURLWithPath: path).lastPathComponent, systemImage: "doc")
              .help(path)
          }
        }
        .font(.system(.body, design: .monospaced))
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .accessibilityLabel("Copied files")
      }
    case .image:
      if
        let imageData = item.imageData,
        let image = NSImage(data: imageData)
      {
        Image(nsImage: image)
          .resizable()
          .scaledToFit()
          .padding(8)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .accessibilityLabel("Copied image preview")
      } else {
        Text(item.detailText)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
  }

  @ViewBuilder
  private func metadataLine(_ item: ClipboardItem) -> some View {
    let metadata = compactMetadata(for: item)

    if !metadata.isEmpty {
      Text(metadata.joined(separator: "  |  "))
        .lineLimit(2)
        .textSelection(.enabled)
    }
  }

  private func compactMetadata(for item: ClipboardItem) -> [String] {
    var metadata: [String] = []

    if let sourceBundleIdentifier = item.sourceBundleIdentifier {
      metadata.append(sourceBundleIdentifier)
    }

    if let sourceProcessIdentifier = item.sourceProcessIdentifier {
      metadata.append("PID \(sourceProcessIdentifier)")
    }

    if let imageSizeDescription = item.imageSizeDescription {
      metadata.append(imageSizeDescription)
    }

    if !item.pasteboardTypes.isEmpty {
      metadata.append(item.pasteboardTypes.prefix(3).joined(separator: ", "))
    }

    return metadata
  }

  private func payloadCountText(_ item: ClipboardItem) -> String {
    switch item.kind {
    case .text:
      "\(item.characterCount) chars"
    case .file:
      item.fileURLs.count == 1 ? "1 file" : "\(item.fileURLs.count) files"
    case .image:
      byteCountFormatter.string(fromByteCount: Int64(item.byteCount))
    }
  }
}

private struct MetadataLabel: View {
  let title: String
  let date: Date

  var body: some View {
    Text("\(title) \(shortDateFormatter.string(from: date))")
  }
}

private enum SelectionDirection {
  case up
  case down
}

private struct KeyboardNavigationMonitor: NSViewRepresentable {
  let moveSelection: (SelectionDirection) -> Void
  let restoreSelection: () -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(
      moveSelection: moveSelection,
      restoreSelection: restoreSelection
    )
  }

  func makeNSView(context: Context) -> NSView {
    let view = NSView()
    context.coordinator.view = view
    context.coordinator.start()
    return view
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    context.coordinator.moveSelection = moveSelection
    context.coordinator.restoreSelection = restoreSelection
  }

  static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
    coordinator.stop()
  }

  final class Coordinator {
    weak var view: NSView?
    var moveSelection: (SelectionDirection) -> Void
    var restoreSelection: () -> Void
    private var monitor: Any?

    init(
      moveSelection: @escaping (SelectionDirection) -> Void,
      restoreSelection: @escaping () -> Void
    ) {
      self.moveSelection = moveSelection
      self.restoreSelection = restoreSelection
    }

    func start() {
      guard monitor == nil else {
        return
      }

      monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
        self?.handle(event) ?? event
      }
    }

    func stop() {
      guard let monitor else {
        return
      }

      NSEvent.removeMonitor(monitor)
      self.monitor = nil
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
      guard view?.window?.isKeyWindow == true else {
        return event
      }

      let blockedModifiers: NSEvent.ModifierFlags = [.command, .option, .control]
      guard event.modifierFlags.intersection(blockedModifiers).isEmpty else {
        return event
      }

      switch event.keyCode {
      case 36, 76:
        restoreSelection()
        return nil
      case 125:
        moveSelection(.down)
        return nil
      case 126:
        moveSelection(.up)
        return nil
      default:
        return event
      }
    }
  }
}

private let relativeDateFormatter: RelativeDateTimeFormatter = {
  let formatter = RelativeDateTimeFormatter()
  formatter.unitsStyle = .abbreviated
  return formatter
}()

private let shortDateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateStyle = .short
  formatter.timeStyle = .short
  return formatter
}()

private let byteCountFormatter: ByteCountFormatter = {
  let formatter = ByteCountFormatter()
  formatter.countStyle = .file
  return formatter
}()
