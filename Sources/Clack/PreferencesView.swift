import ClackCore
import SwiftUI

struct PreferencesView: View {
  @ObservedObject var preferences: ClackPreferences
  @ObservedObject var store: ClipboardHistoryStore

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("Preferences")
        .font(.title2.weight(.semibold))

      VStack(alignment: .leading, spacing: 8) {
        Stepper(
          value: Binding(
            get: { preferences.historyLimit },
            set: { newValue in
              preferences.setHistoryLimit(newValue)
              store.updateLimit(newValue)
            }
          ),
          in: ClipboardHistoryStore.minimumLimit...ClipboardHistoryStore.maximumLimit,
          step: 25
        ) {
          HStack {
            Text("History limit")
            Spacer()
            Text("\(preferences.historyLimit)")
              .foregroundStyle(.secondary)
          }
        }

        Text("\(store.items.count) stored")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Divider()

      HStack {
        Button {
          store.clearUnpinned()
        } label: {
          Label("Clear", systemImage: "trash")
        }
        .disabled(store.items.allSatisfy(\.isPinned))

        Button(role: .destructive) {
          store.clearAll()
        } label: {
          Label("Clear All", systemImage: "trash.slash")
        }
        .disabled(store.items.isEmpty)

        Spacer()
      }

      Spacer()
    }
    .padding(22)
    .frame(minWidth: 420, minHeight: 260)
  }
}
