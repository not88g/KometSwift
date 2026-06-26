import SwiftUI
import AVKit

struct FullScreenVideoView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    private let player: AVPlayer

    init(url: URL) {
        self.url = url
        self.player = AVPlayer(url: url)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VideoPlayer(player: player)
                .ignoresSafeArea()
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .padding()
            }
        }
        .onAppear { player.play() }
        .onDisappear { player.pause() }
        .statusBarHidden()
    }
}
