import SwiftUI

struct ChatsView: View {
    @State private var viewModel = ChatsViewModel()
    @State private var selectedFolder: ChatFolder?
    @State private var searchText = ""
    @Environment(\.kometUseLiquidGlass) private var useLiquidGlass

    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            VStack(spacing: 0) {
                ConnectionStatusBannerView(state: viewModel.connectionState)
                    .animation(.spring(duration: 0.3), value: viewModel.connectionState)

                if !viewModel.folders.isEmpty {
                    FolderTabsView(folders: viewModel.folders, selected: $selectedFolder)
                }

                chatList
            }
            .navigationTitle(String(localized: "Chats"))
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: String(localized: "Search")
            )
            .toolbar { toolbar }
            .navigationDestination(for: NavigationDestination.self) {
                AppNavigationStack.view(for: $0)
            }
            .onReceive(NotificationCenter.default.publisher(for: .openChat)) { notif in
                if let chatId = notif.object as? Int {
                    viewModel.navigationPath.append(NavigationDestination.chat(chatId: chatId))
                }
            }
        }
        .task { await viewModel.load() }
    }

    private var chatList: some View {
        let filtered = viewModel.filteredChats(folder: selectedFolder, query: searchText)
        return List {
            ForEach(filtered) { chat in
                ChatRowView(chat: chat)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(
                        top: KometSpacing.xs,
                        leading: KometSpacing.lg,
                        bottom: KometSpacing.xs,
                        trailing: KometSpacing.lg
                    ))
                    .onTapGesture {
                        viewModel.navigationPath.append(NavigationDestination.chat(chatId: chat.id))
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .overlay {
            if filtered.isEmpty && !viewModel.isLoading {
                EmptyChatsView(hasSearch: !searchText.isEmpty)
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.chats.isEmpty {
                ProgressView()
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                viewModel.navigationPath.append(NavigationDestination.settings)
            } label: {
                Image(systemName: "gearshape")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.navigationPath.append(NavigationDestination.newChat)
            } label: {
                Image(systemName: "square.and.pencil")
            }
        }
    }
}
