import SwiftUI

struct AvatarView: View {
    let baseUrl: String?
    let displayName: String
    let size: CGFloat
    var showPresence: Bool = false
    var isOnline: Bool = false

    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarBody
                .frame(width: size, height: size)
                .clipShape(Circle())
                .animation(.easeInOut(duration: 0.2), value: image != nil)

            if showPresence {
                PresenceDotView(isOnline: isOnline, dotSize: size * 0.28)
                    .offset(x: 1, y: 1)
            }
        }
        .task(id: baseUrl) {
            guard let url = baseUrl, !url.isEmpty else { return }
            image = await AvatarCacheService.shared.avatar(for: url)
        }
    }

    @ViewBuilder
    private var avatarBody: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Circle()
                .fill(initialsColor)
                .overlay(
                    Text(initials)
                        .font(.system(size: size * 0.36, weight: .semibold))
                        .foregroundStyle(.white)
                )
        }
    }

    private var initials: String {
        displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined()
            .uppercased()
    }

    private var initialsColor: Color {
        // Deterministic colour from display name — mirrors user_color_helper.dart
        let palette: [Color] = [.blue, .purple, .green, .orange, .pink, .teal, .indigo, .cyan]
        let index = abs(displayName.hashValue) % palette.count
        return palette[index]
    }
}
