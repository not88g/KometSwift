import SwiftUI
import PhotosUI

struct MessageInputView: View {
    @Bindable var viewModel: ChatViewModel
    @State private var photoItem: PhotosPickerItem?
    @State private var showFilePicker = false
    @FocusState private var textFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            // Reply preview
            if let reply = viewModel.replyToMessage {
                ReplyPreviewView(message: reply) {
                    viewModel.replyToMessage = nil
                }
            }

            HStack(alignment: .bottom, spacing: KometSpacing.sm) {
                // Attachment button
                Menu {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(String(localized: "Photo"), systemImage: "photo")
                    }
                    Button {
                        showFilePicker = true
                    } label: {
                        Label(String(localized: "File"), systemImage: "doc")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.kometAccent)
                }

                // Text input
                TextField(String(localized: "Message"), text: $viewModel.inputText, axis: .vertical)
                    .lineLimit(1...5)
                    .focused($textFocused)
                    .padding(.horizontal, KometSpacing.md)
                    .padding(.vertical, KometSpacing.sm)
                    .background(
                        Color(uiColor: .secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )
                    .onChange(of: viewModel.inputText) { _, _ in
                        viewModel.userStartedTyping()
                    }

                // Encryption toggle
                Button {
                    viewModel.toggleEncryption()
                } label: {
                    Image(systemName: viewModel.encryptionEnabled ? "lock.fill" : "lock.open")
                        .font(.system(size: 20))
                        .foregroundStyle(viewModel.encryptionEnabled ? .green : .secondary)
                }

                // Send button
                Button {
                    Task { await viewModel.send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? .secondary : .kometAccent
                        )
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, KometSpacing.md)
            .padding(.vertical, KometSpacing.sm)
            .background(Color(uiColor: .systemBackground))
        }
        .onChange(of: photoItem) { _, item in
            Task { await handlePhotoSelection(item) }
        }
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self)
        else { return }
        // Upload and attach to next message
        if let uploaded = try? await APIService.shared.uploadFile(
            data: data, name: "photo.jpg", mimeType: "image/jpeg"
        ) {
            viewModel.selectedAttachments.append(URL(string: uploaded["url"] as? String ?? "")!)
        }
    }
}
