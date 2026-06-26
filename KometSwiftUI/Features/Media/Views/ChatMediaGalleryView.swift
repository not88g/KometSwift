import SwiftUI

struct ChatMediaGalleryView: View {
    let chatId: Int

    @State private var mediaItems: [[String: Any]] = []
    @State private var selectedURL: URL?
    @State private var isLoading = false

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 2)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(mediaItems.indices, id: \.self) { i in
                    let item = mediaItems[i]
                    let urlStr = item["url"] as? String ?? item["baseUrl"] as? String ?? ""
                    if let url = URL(string: urlStr) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 110, height: 110)
                        .clipped()
                        .onTapGesture { selectedURL = url }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Media"))
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if isLoading { ProgressView() }
        }
        .fullScreenCover(item: $selectedURL) { url in
            FullScreenImageView(url: url)
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        mediaItems = (try? await APIService.shared.fetchChatMedia(chatId: chatId)) ?? []
        isLoading = false
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

struct FullScreenImageView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            AsyncImage(url: url) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                ProgressView().tint(.white)
            }
        }
        .onTapGesture { dismiss() }
    }
}
