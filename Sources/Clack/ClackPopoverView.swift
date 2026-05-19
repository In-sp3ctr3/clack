import ClackCore
import SwiftUI

struct ClackPopoverView: View {
  @ObservedObject var store: ClipboardHistoryStore
  @ObservedObject var preferences: ClackPreferences

  let actions: ClipboardActions

  @FocusState private var searchFocused: Bool
  @State private var hoveredItemID: ClipboardItem.ID?

  private var visibleItems: [ClipboardItem] {
    let filteredItems = store.items.filter {
      $0.matches(store.searchText, mode: preferences.searchMode)
    }

    return sortedItems(filteredItems)
  }

  private var selectedItem: ClipboardItem? {
    if let hoveredItemID, let hoveredItem = store.item(withID: hoveredItemID) {
      return hoveredItem
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
        actions: actions
      )

      if preferences.showFooter {
        Divider()

        footer
      }
    }
    .frame(width: 460, height: 620)
    .background(Color(nsColor: .windowBackgroundColor))
    .onAppear {
      searchFocused = true
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

      TextField("Search", text: $store.searchText)
        .textFieldStyle(.plain)
        .focused($searchFocused)

      if !store.searchText.isEmpty {
        Button {
          store.searchText = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
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
        showIcon: preferences.showApplicationIcons,
        restore: { actions.restore(item) },
        togglePin: { actions.togglePin(item) },
        delete: { actions.delete(item) },
        onHover: { isHovering in
          hoveredItemID = isHovering ? item.id : nil
        }
      )
      .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: [.command])
    } else {
      ClipboardRow(
        item: item,
        shortcutNumber: nil,
        showIcon: preferences.showApplicationIcons,
        restore: { actions.restore(item) },
        togglePin: { actions.togglePin(item) },
        delete: { actions.delete(item) },
        onHover: { isHovering in
          hoveredItemID = isHovering ? item.id : nil
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

      Spacer()

      Button {
        actions.showPreferences()
      } label: {
        Image(systemName: "gearshape")
      }
      .keyboardShortcut(",", modifiers: [.command])
      .help("Preferences")

      Button {
        actions.showAbout()
      } label: {
        Image(systemName: "info.circle")
      }
      .help("About Clack")

      Button {
        actions.quit()
      } label: {
        Image(systemName: "power")
      }
      .keyboardShortcut("q", modifiers: [.command])
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
        return lhs.content.localizedCaseInsensitiveCompare(rhs.content) == .orderedAscending
      }
    }
  }
}

private struct ClipboardRow: View {
  let item: ClipboardItem
  let shortcutNumber: Int?
  let showIcon: Bool
  let restore: () -> Void
  let togglePin: () -> Void
  let delete: () -> Void
  let onHover: (Bool) -> Void

  var body: some View {
    Button(action: restore) {
      HStack(alignment: .top, spacing: 10) {
        if showIcon || item.isPinned {
          Image(systemName: item.isPinned ? "pin.fill" : "doc.text")
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
  }

  private var copyCountText: String {
    item.copyCount == 1 ? "1 copy" : "\(item.copyCount) copies"
  }
}

private struct DetailPane: View {
  let item: ClipboardItem?
  let actions: ClipboardActions

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if let item {
        HStack(spacing: 8) {
          Label(item.sourceApp ?? "Unknown", systemImage: "app.dashed")
          Spacer()
          Text("\(item.characterCount) chars")
        }
        .font(.caption)
        .foregroundStyle(.secondary)

        ScrollView {
          Text(item.content)
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
        }
        .frame(height: 96)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))

        HStack(spacing: 12) {
          MetadataLabel(title: "First", date: item.firstCopiedAt)
          MetadataLabel(title: "Last", date: item.lastCopiedAt)
          Text(item.copyCount == 1 ? "1 copy" : "\(item.copyCount) copies")
        }
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
  }
}

private struct MetadataLabel: View {
  let title: String
  let date: Date

  var body: some View {
    Text("\(title) \(shortDateFormatter.string(from: date))")
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
