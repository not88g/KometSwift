import SwiftUI

struct AttachmentPreviewView: View {
    let attaches: [[String: AnyCodable]]
    let isOutgoing: Bool

    var body: some View {
        VStack(spacing: KometSpacing.xs) {
            ForEach(attaches.indices, id: \.self) { i in
                attachmentView(attaches[i])
            }
        }
    }

    @ViewBuilder
    private func attachmentView(_ attach: [String: AnyCodable]) -> some View {
        let type = attach["_type"]?.value as? String ?? attach["type"]?.value as? String ?? ""

        switch type {
        case "IMAGE":
            if let urlStr = attach["url"]?.value as? String ?? attach["baseUrl"]?.value as? String,
               let url = URL(string: urlStr) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(maxWidth: 240, maxHeight: 240)
                .clipShape(RoundedRectangle(cornerRadius: KometSpacing.sm, style: .continuous))
            }

        case "AUDIO":
            AudioAttachmentView(attach: attach)

        case "FILE":
            fileView(attach)

        default:
            fileView(attach)
        }
    }

    private func fileView(_ attach: [String: AnyCodable]) -> some View {
        let name = attach["name"]?.value as? String ?? String(localized: "File")
        return HStack(spacing: KometSpacing.sm) {
            Image(systemName: "doc.fill")
                .foregroundStyle(.kometAccent)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.kometCaption).lineLimit(1)
                if let size = attach["size"]?.value as? Int {
                    Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                        .font(.kometCaption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "arrow.down.circle").foregroundStyle(.kometAccent)
        }
        .padding(KometSpacing.sm)
        .background(Color(uiColor: .secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: KometSpacing.sm, style: .continuous))
    }
}

struct AudioAttachmentView: View {
    let attach: [String: AnyCodable]
    @State private var isPlaying = false

    var body: some View {
        HStack(spacing: KometSpacing.sm) {
            Button {
                isPlaying.toggle()
                // Trigger MusicPlayerService
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.kometAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Voice message"))
                    .font(.kometCaption)
                if let dur = attach["duration"]?.value as? Int {
                    Text("\(dur / 60):\(String(format: "%02d", dur % 60))")
                        .font(.kometCaption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(KometSpacing.sm)
        .background(Color(uiColor: .secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: KometSpacing.sm, style: .continuous))
    }
}
