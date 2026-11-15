import AVFoundation
import os

/// 让 WKWebView 里的 <audio> / WebAudio 在静音键打开时也能出声，
/// 并且切到后台后继续播（配合 Info.plist 的 UIBackgroundModes = audio）。
enum AudioSession {
    private static let logger = Logger(subsystem: "cn.foliaios.app", category: "audio")

    static func activate() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: [])
        } catch {
            logger.error("激活音频会话失败: \(error.localizedDescription, privacy: .public)")
        }
    }

    static func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}
