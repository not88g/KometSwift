import SwiftUI

struct EmptyChatsView: View {
    var hasSearch: Bool = false

    var body: some View {
        VStack(spacing: KometSpacing.lg) {
            Image(systemName: hasSearch ? "magnifyingglass" : "bubble.left.and.bubble.right")
                .resizable().scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundStyle(.secondary)

            Text(hasSearch
                 ? String(localized: "No chats found")
                 : String(localized: "No chats yet"))
                .font(.kometHeadline)

            if !hasSearch {
                Text(String(localized: "Start a new conversation using the pencil button above"))
                    .font(.kometCaption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, KometSpacing.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
