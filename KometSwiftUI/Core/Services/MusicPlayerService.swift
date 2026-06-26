// Mirrors services/music_player_service.dart.
// Uses AVFoundation for audio playback. Published as @Observable for SwiftUI.

import Foundation
import AVFoundation
import Observation

@Observable
final class MusicPlayerService {
    static let shared = MusicPlayerService()

    private(set) var currentTrack: AudioTrack?
    private(set) var isPlaying = false
    private(set) var progress: Double = 0
    private(set) var duration: Double = 0

    private var player: AVAudioPlayer?
    private var progressTimer: Timer?

    struct AudioTrack: Identifiable {
        let id: String
        let name: String
        let url: URL
        let durationSeconds: Double
    }

    func play(track: AudioTrack) {
        stop()
        currentTrack = track
        guard let player = try? AVAudioPlayer(contentsOf: track.url) else { return }
        self.player = player
        player.delegate = playerDelegate
        player.prepareToPlay()
        player.play()
        isPlaying = true
        duration = player.duration
        startProgressTimer()
    }

    func playPause() {
        guard let player else { return }
        if player.isPlaying { player.pause(); isPlaying = false }
        else { player.play(); isPlaying = true }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        progress = 0
        progressTimer?.invalidate()
        progressTimer = nil
        currentTrack = nil
    }

    func seek(to ratio: Double) {
        guard let player else { return }
        player.currentTime = ratio * player.duration
        progress = ratio
    }

    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            self.progress = player.currentTime / player.duration
        }
    }

    // Delegate bridge
    private lazy var playerDelegate = AudioPlayerDelegate { [weak self] in
        self?.isPlaying = false
        self?.progress = 0
        self?.progressTimer?.invalidate()
    }
}

private final class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    private let onFinish: () -> Void
    init(_ onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { onFinish() }
}
