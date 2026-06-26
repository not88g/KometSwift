import SwiftUI

struct FolderTabsView: View {
    let folders: [ChatFolder]
    @Binding var selected: ChatFolder?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: KometSpacing.sm) {
                // "All" tab
                tab(title: String(localized: "All"), folder: nil)

                ForEach(folders) { folder in
                    tab(title: folder.title, folder: folder)
                }
            }
            .padding(.horizontal, KometSpacing.lg)
            .padding(.vertical, KometSpacing.xs)
        }
    }

    private func tab(title: String, folder: ChatFolder?) -> some View {
        let isSelected = selected?.id == folder?.id

        return Button {
            withAnimation(.spring(duration: 0.25)) { selected = folder }
        } label: {
            Text(title)
                .font(.system(.subheadline, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, KometSpacing.md)
                .padding(.vertical, KometSpacing.sm)
                .background(
                    isSelected ? Color.kometAccent : Color(uiColor: .secondarySystemFill),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}
