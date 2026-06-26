import SwiftUI

struct MusicLibraryView: View {
    @State private var tracks: [MusicPlayerService.AudioTrack] = []
    private let player = MusicPlayerService.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            List(tracks) { track in
                HStack(spacing: KometSpacing.md) {
                    Image(systemName: "music.note")
                        .font(.system(size: 28))
                        .foregroundStyle(.kometAccent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.name).font(.kometHeadline).lineLimit(1)
                        Text(formattedDuration(track.durationSeconds))
                            .font(.kometCaption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        if player.currentTrack?.id == track.id { player.playPause() }
                        else { player.play(track: track) }
                    } label: {
                        Image(systemName: player.currentTrack?.id == track.id && player.isPlaying
                              ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.kometAccent)
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)

            // Mini player bar
            if player.currentTrack != nil {
                miniPlayer
                    .padding(.bottom, KometSpacing.sm)
            }
        }
        .navigationTitle(String(localized: "Music"))
        .onAppear { loadTracks() }
    }

    private var miniPlayer: some View {
        HStack(spacing: KometSpacing.md) {
            VStack(alignment: .leading) {
                Text(player.currentTrack?.name ?? "").font(.kometHeadline).lineLimit(1)
                ProgressView(value: player.progress)
                    .progressViewStyle(.linear)
                    .tint(.kometAccent)
            }
            Spacer()
            Button { player.playPause() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.kometAccent)
            }
            Button { player.stop() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(KometSpacing.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: KometSpacing.cornerRadius, style: .continuous))
        .padding(.horizontal, KometSpacing.lg)
        .shadow(radius: 8)
    }

    private func loadTracks() {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let audioDir = docs.appendingPathComponent("Audio")
        let files = (try? FileManager.default.contentsOfDirectory(at: audioDir, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        tracks = files
            .filter { ["mp3","m4a","ogg","wav"].contains($0.pathExtension.lowercased()) }
            .map { url in
                MusicPlayerService.AudioTrack(
                    id: url.lastPathComponent,
                    name: url.deletingPathExtension().lastPathComponent,
                    url: url,
                    durationSeconds: 0
                )
            }
    }

    private func formattedDuration(_ secs: Double) -> String {
        let m = Int(secs) / 60; let s = Int(secs) % 60
        return String(format: "%d:%02d", m, s)
    }
}
