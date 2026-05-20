import ClackCore
import AppKit
import SwiftUI

struct ClackPopoverView: View {
  static let compactContentSize = NSSize(width: 330, height: 480)

  private static let expandedContentSize = NSSize(width: 626, height: 480)
  private static let menuWidth: CGFloat = 330
  private static let previewWidth: CGFloat = 288
  private static let previewHeight: CGFloat = 268
  private static let previewMargin: CGFloat = 8
  private static let popoverHeight: CGFloat = 480
  private static let headerHeight: CGFloat = 65
  private static let rowHeight: CGFloat = 28
  private static let rowStride: CGFloat = 29

  @ObservedObject var store: ClipboardHistoryStore
  @ObservedObject var preferences: ClackPreferences

  let actions: ClipboardActions
  let setContentSize: (NSSize) -> Void

  @FocusState private var searchFocused: Bool
  @State private var selectedItemID: ClipboardItem.ID?
  @State private var hoveredItemID: ClipboardItem.ID?
  @State private var detailCardIsHovered = false

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

  private var hoveredItem: ClipboardItem? {
    guard let hoveredItemID else {
      return nil
    }

    return visibleItems.first { $0.id == hoveredItemID }
  }

  private var currentContentSize: NSSize {
    hoveredItem == nil ? Self.compactContentSize : Self.expandedContentSize
  }

  private var hoveredRowCenterY: CGFloat? {
    guard
      let hoveredItemID,
      let index = visibleItems.firstIndex(where: { $0.id == hoveredItemID })
    else {
      return nil
    }

    return Self.headerHeight + (CGFloat(index) * Self.rowStride) + (Self.rowHeight / 2)
  }

  private var detailCardTopOffset: CGFloat {
    let centeredOffset = (hoveredRowCenterY ?? (Self.popoverHeight / 2)) - (Self.previewHeight / 2)
    let maximumOffset = Self.popoverHeight - Self.previewHeight - Self.previewMargin
    return min(max(centeredOffset, Self.previewMargin), maximumOffset)
  }

  private var detailCardPointerY: CGFloat {
    let pointerY = (hoveredRowCenterY ?? (Self.popoverHeight / 2)) - detailCardTopOffset
    return min(max(pointerY, 26), Self.previewHeight - 26)
  }

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      if let hoveredItem {
        ZStack(alignment: .topTrailing) {
          HoverDetailCard(
            item: hoveredItem,
            pointerY: detailCardPointerY
          )
          .frame(width: Self.previewWidth, height: Self.previewHeight)
          .padding(.top, detailCardTopOffset)
          .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .trailing)))
          .onHover { isHovering in
            detailCardIsHovered = isHovering

            if !isHovering {
              clearHoveredItemAfterDelay(hoveredItem.id)
            }
          }
        }
        .frame(width: Self.previewWidth, height: Self.popoverHeight)
      }

      mainMenu
    }
    .frame(
      width: currentContentSize.width,
      height: currentContentSize.height,
      alignment: .trailing
    )
    .background(Color.clear)
    .background(
      KeyboardNavigationMonitor(
        moveSelection: moveSelection,
        restoreSelection: restoreSelectedItem,
        togglePinSelection: togglePinnedSelection,
        deleteSelection: deleteSelectedItem
      )
      .frame(width: 0, height: 0)
      .accessibilityHidden(true)
    )
    .animation(.easeOut(duration: 0.12), value: hoveredItemID)
    .onAppear {
      searchFocused = true
      syncSelectionWithVisibleItems()
      setContentSize(currentContentSize)
    }
    .onChange(of: visibleItemIDs) { _ in
      syncSelectionWithVisibleItems()
    }
    .onChange(of: hoveredItemID) { _ in
      setContentSize(currentContentSize)
    }
  }

  private var mainMenu: some View {
    VStack(spacing: 0) {
      header

      Divider()

      itemList

      Divider()

      footer
    }
    .frame(width: Self.menuWidth, height: Self.popoverHeight)
    .background(.regularMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 0.5)
    )
  }

  private var header: some View {
    VStack(spacing: 7) {
      Text("Clack")
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .center)

      if showsSearchField {
        searchBar
      }
    }
    .padding(.horizontal, 10)
    .padding(.top, 8)
    .padding(.bottom, showsSearchField ? 9 : 8)
  }

  private var searchBar: some View {
    HStack(spacing: 6) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)

      TextField("Search", text: $store.searchText)
        .textFieldStyle(.plain)
        .font(.system(size: 13))
        .focused($searchFocused)
        .onSubmit(restoreSelectedItem)
        .accessibilityLabel("Search clipboard history")
        .accessibilityHint("Type to filter saved clipboard items. Press Return to restore the selected item.")

      if !store.searchText.isEmpty {
        Button {
          store.searchText = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 12))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityLabel("Clear search")
        .help("Clear search")
      }
    }
    .padding(.horizontal, 8)
    .frame(height: 26)
    .background(Color(nsColor: .controlBackgroundColor).opacity(0.72))
    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
  }

  @ViewBuilder
  private var itemList: some View {
    if visibleItems.isEmpty {
      VStack(spacing: 6) {
        Spacer()
        Text("No clipboard items")
          .font(.system(size: 13))
          .foregroundStyle(.secondary)
        Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
            shortcutRow(item: item, index: index)

            if item.id != visibleItems.last?.id {
              Divider()
                .padding(.leading, 10)
            }
          }
        }
      }
    }
  }

  @ViewBuilder
  private func shortcutRow(item: ClipboardItem, index: Int) -> some View {
    let shortcutNumber = index < 9 ? index + 1 : nil
    let row = CompactClipboardRow(
      item: item,
      shortcutNumber: shortcutNumber,
      isSelected: selectedItem?.id == item.id,
      restore: { actions.restore(item) },
      onHover: { isHovering in
        if isHovering {
          selectedItemID = item.id
          hoveredItemID = item.id
        } else if hoveredItemID == item.id {
          clearHoveredItemAfterDelay(item.id)
        }
      }
    )

    if let shortcutNumber {
      row.keyboardShortcut(KeyEquivalent(Character("\(shortcutNumber)")), modifiers: [.command])
    } else {
      row
    }
  }

  private var footer: some View {
    VStack(spacing: 0) {
      FooterMenuRow(
        title: "Clear",
        shortcut: "⇧⌘K",
        isDisabled: store.items.allSatisfy(\.isPinned),
        action: actions.clearUnpinned
      )
      .keyboardShortcut("k", modifiers: [.command, .shift])
      .accessibilityHint("Clears every unpinned clipboard item.")

      FooterMenuRow(
        title: "Preferences",
        shortcut: "⌘,",
        action: actions.showPreferences
      )
      .keyboardShortcut(",", modifiers: [.command])
      .accessibilityHint("Open Clack preferences.")

      FooterMenuRow(
        title: "About",
        shortcut: nil,
        action: actions.showAbout
      )
      .accessibilityHint("Open the About window.")

      FooterMenuRow(
        title: "Quit",
        shortcut: "⌘Q",
        action: actions.quit
      )
      .keyboardShortcut("q", modifiers: [.command])
      .accessibilityHint("Quit Clack.")
    }
    .padding(.vertical, 5)
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

  private func togglePinnedSelection() {
    guard let selectedItem else {
      return
    }

    actions.togglePin(selectedItem)
  }

  private func deleteSelectedItem() {
    guard let selectedItem else {
      return
    }

    actions.delete(selectedItem)

    if hoveredItemID == selectedItem.id {
      hoveredItemID = nil
    }
  }

  private func clearHoveredItemAfterDelay(_ itemID: ClipboardItem.ID) {
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(160))

      if hoveredItemID == itemID && !detailCardIsHovered {
        hoveredItemID = nil
      }
    }
  }

  private func syncSelectionWithVisibleItems() {
    guard !visibleItems.isEmpty else {
      selectedItemID = nil
      hoveredItemID = nil
      return
    }

    if let hoveredItemID, !visibleItems.contains(where: { $0.id == hoveredItemID }) {
      self.hoveredItemID = nil
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

private struct CompactClipboardRow: View {
  let item: ClipboardItem
  let shortcutNumber: Int?
  let isSelected: Bool
  let restore: () -> Void
  let onHover: (Bool) -> Void

  var body: some View {
    Button(action: restore) {
      HStack(spacing: 10) {
        Text(rowPreview)
          .font(.system(size: 13, weight: item.isPinned ? .semibold : .regular))
          .foregroundStyle(.primary)
          .lineLimit(1)
          .truncationMode(.tail)
          .frame(maxWidth: .infinity, alignment: .leading)

        if let shortcutNumber {
          Text("⌘\(shortcutNumber)")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .frame(width: 28, alignment: .trailing)
        }
      }
      .contentShape(Rectangle())
      .padding(.horizontal, 10)
      .frame(height: 28)
      .background(rowBackground)
    }
    .buttonStyle(.plain)
    .onHover(perform: onHover)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(item.preview)
    .accessibilityValue(accessibilityValue)
    .accessibilityHint("Press Return to restore this item to the clipboard.")
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  private var rowPreview: String {
    guard !item.preview.isEmpty else {
      return item.kind.rawValue
    }

    return item.preview
  }

  private var accessibilityValue: String {
    var details: [String] = []

    if item.isPinned {
      details.append("Pinned")
    }

    if let shortcutNumber {
      details.append("Command \(shortcutNumber)")
    }

    if isSelected {
      details.append("Selected")
    }

    return details.joined(separator: ", ")
  }

  @ViewBuilder
  private var rowBackground: some View {
    if isSelected {
      Rectangle()
        .fill(Color.accentColor.opacity(0.14))
    }
  }
}

private struct HoverDetailCard: View {
  let item: ClipboardItem
  let pointerY: CGFloat

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      payloadPreview
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: 104)

      Divider()
        .padding(.vertical, 10)

      VStack(alignment: .leading, spacing: 6) {
        DetailMetadataRow(title: "Application", value: item.sourceApp ?? "Unknown")
        DetailMetadataRow(title: "First time copied", value: detailDateFormatter.string(from: item.firstCopiedAt))
        DetailMetadataRow(title: "Last time copied", value: detailDateFormatter.string(from: item.lastCopiedAt))
        DetailMetadataRow(title: "Number of copies", value: "\(item.copyCount)")
      }

      Spacer(minLength: 12)

      VStack(alignment: .leading, spacing: 4) {
        Text("Press ⌘P to \(item.isPinned ? "unpin" : "pin")")
        Text("Press ⌘⌫ to delete")
      }
      .font(.system(size: 12))
      .foregroundStyle(.secondary)
    }
    .padding(.leading, 12)
    .padding(.trailing, 20)
    .padding(.vertical, 12)
    .background(
      PopoutBubbleShape(pointerY: pointerY)
        .fill(.regularMaterial)
    )
    .overlay(
      PopoutBubbleShape(pointerY: pointerY)
        .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5)
    )
    .clipShape(PopoutBubbleShape(pointerY: pointerY))
    .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 10)
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Clipboard item details")
  }

  @ViewBuilder
  private var payloadPreview: some View {
    switch item.kind {
    case .text, .richText:
      ScrollView {
        Text(item.content)
          .font(.system(size: 12, design: .monospaced))
          .foregroundStyle(.primary)
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(9)
      }
      .background(Color(nsColor: .textBackgroundColor).opacity(0.58))
      .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
      .accessibilityLabel("Full clipboard content")
    case .file:
      ScrollView {
        VStack(alignment: .leading, spacing: 5) {
          ForEach(item.fileURLs, id: \.self) { path in
            Text(URL(fileURLWithPath: path).lastPathComponent)
              .help(path)
          }
        }
        .font(.system(size: 12, design: .monospaced))
        .foregroundStyle(.primary)
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
      }
      .background(Color(nsColor: .textBackgroundColor).opacity(0.58))
      .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
      .accessibilityLabel("Copied files")
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
          .background(Color(nsColor: .textBackgroundColor).opacity(0.58))
          .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
          .accessibilityLabel("Copied image preview")
      } else {
        Text(item.detailText)
          .font(.system(size: 12))
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Color(nsColor: .textBackgroundColor).opacity(0.58))
          .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
      }
    }
  }
}

private struct PopoutBubbleShape: Shape {
  var pointerY: CGFloat

  var animatableData: CGFloat {
    get { pointerY }
    set { pointerY = newValue }
  }

  func path(in rect: CGRect) -> Path {
    let notchWidth: CGFloat = 8
    let notchHeight: CGFloat = 20
    let radius: CGFloat = 12
    let body = CGRect(
      x: rect.minX,
      y: rect.minY,
      width: rect.width - notchWidth,
      height: rect.height
    )
    let clampedPointerY = min(
      max(pointerY, body.minY + radius + (notchHeight / 2)),
      body.maxY - radius - (notchHeight / 2)
    )

    var path = Path()
    path.move(to: CGPoint(x: body.minX + radius, y: body.minY))
    path.addLine(to: CGPoint(x: body.maxX - radius, y: body.minY))
    path.addQuadCurve(
      to: CGPoint(x: body.maxX, y: body.minY + radius),
      control: CGPoint(x: body.maxX, y: body.minY)
    )
    path.addLine(to: CGPoint(x: body.maxX, y: clampedPointerY - (notchHeight / 2)))
    path.addQuadCurve(
      to: CGPoint(x: rect.maxX, y: clampedPointerY),
      control: CGPoint(x: body.maxX + notchWidth, y: clampedPointerY - 6)
    )
    path.addQuadCurve(
      to: CGPoint(x: body.maxX, y: clampedPointerY + (notchHeight / 2)),
      control: CGPoint(x: body.maxX + notchWidth, y: clampedPointerY + 6)
    )
    path.addLine(to: CGPoint(x: body.maxX, y: body.maxY - radius))
    path.addQuadCurve(
      to: CGPoint(x: body.maxX - radius, y: body.maxY),
      control: CGPoint(x: body.maxX, y: body.maxY)
    )
    path.addLine(to: CGPoint(x: body.minX + radius, y: body.maxY))
    path.addQuadCurve(
      to: CGPoint(x: body.minX, y: body.maxY - radius),
      control: CGPoint(x: body.minX, y: body.maxY)
    )
    path.addLine(to: CGPoint(x: body.minX, y: body.minY + radius))
    path.addQuadCurve(
      to: CGPoint(x: body.minX + radius, y: body.minY),
      control: CGPoint(x: body.minX, y: body.minY)
    )
    path.closeSubpath()
    return path
  }
}

private struct DetailMetadataRow: View {
  let title: String
  let value: String

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Text(title)
        .foregroundStyle(.secondary)
        .frame(width: 112, alignment: .leading)

      Text(value)
        .foregroundStyle(.primary)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .font(.system(size: 12))
  }
}

private struct FooterMenuRow: View {
  let title: String
  let shortcut: String?
  var isDisabled = false
  let action: () -> Void

  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Text(title)
          .font(.system(size: 13))
          .foregroundStyle(isDisabled ? .secondary : .primary)

        Spacer()

        if let shortcut {
          Text(shortcut)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
      }
      .contentShape(Rectangle())
      .padding(.horizontal, 10)
      .frame(height: 27)
      .background(rowBackground)
    }
    .buttonStyle(.plain)
    .disabled(isDisabled)
    .onHover { isHovering = $0 }
    .accessibilityLabel(title)
  }

  @ViewBuilder
  private var rowBackground: some View {
    if isHovering && !isDisabled {
      Rectangle()
        .fill(Color.accentColor.opacity(0.12))
    }
  }
}

private enum SelectionDirection {
  case up
  case down
}

private struct KeyboardNavigationMonitor: NSViewRepresentable {
  let moveSelection: (SelectionDirection) -> Void
  let restoreSelection: () -> Void
  let togglePinSelection: () -> Void
  let deleteSelection: () -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(
      moveSelection: moveSelection,
      restoreSelection: restoreSelection,
      togglePinSelection: togglePinSelection,
      deleteSelection: deleteSelection
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
    context.coordinator.togglePinSelection = togglePinSelection
    context.coordinator.deleteSelection = deleteSelection
  }

  static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
    coordinator.stop()
  }

  final class Coordinator {
    weak var view: NSView?
    var moveSelection: (SelectionDirection) -> Void
    var restoreSelection: () -> Void
    var togglePinSelection: () -> Void
    var deleteSelection: () -> Void
    private var monitor: Any?

    init(
      moveSelection: @escaping (SelectionDirection) -> Void,
      restoreSelection: @escaping () -> Void,
      togglePinSelection: @escaping () -> Void,
      deleteSelection: @escaping () -> Void
    ) {
      self.moveSelection = moveSelection
      self.restoreSelection = restoreSelection
      self.togglePinSelection = togglePinSelection
      self.deleteSelection = deleteSelection
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

      let modifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])

      if modifiers == [.command], event.keyCode == 35 {
        togglePinSelection()
        return nil
      }

      if modifiers == [.command], event.keyCode == 51 || event.keyCode == 117 {
        deleteSelection()
        return nil
      }

      guard modifiers.isEmpty else {
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

private let detailDateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateStyle = .medium
  formatter.timeStyle = .short
  return formatter
}()
