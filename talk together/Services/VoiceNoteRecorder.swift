import Foundation
import AVFoundation

@MainActor
@Observable
public final class VoiceNotePlayer: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    public var isPlaying: Bool = false
    public var progress: CGFloat = 0.0
    public var currentTime: Int = 0
    public var playbackRate: Float = 1.0 // 1.0, 1.5, 2.0 (WhatsApp-style)
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var fallbackDuration: Int = 1
    private var activeURL: URL?
    
    public override init() {
        super.init()
    }
    
    public var playbackRateLabel: String {
        switch playbackRate {
        case 1.5: return "1.5x"
        case 2.0: return "2x"
        default: return "1x"
        }
    }
    
    public func cyclePlaybackRate() {
        if playbackRate == 1.0 {
            playbackRate = 1.5
        } else if playbackRate == 1.5 {
            playbackRate = 2.0
        } else {
            playbackRate = 1.0
        }
        if let player = audioPlayer {
            player.rate = playbackRate
        }
    }
    
    public func togglePlayback(url: URL?, fallbackDuration: Int) {
        if isPlaying {
            pause()
        } else {
            play(url: url, fallbackDuration: fallbackDuration)
        }
    }
    
    public func play(url: URL?, fallbackDuration: Int) {
        self.fallbackDuration = max(1, fallbackDuration)
        self.activeURL = url
        
        // Resume existing player if paused on same URL
        if let player = audioPlayer, !player.isPlaying {
            player.enableRate = true
            player.rate = playbackRate
            player.play()
            isPlaying = true
            startProgressTimer()
            return
        }
        
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try? session.setActive(true)
        
        if let url = url, FileManager.default.fileExists(atPath: url.path) {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.delegate = self
                player.enableRate = true
                player.rate = playbackRate
                player.prepareToPlay()
                if progress > 0 && progress < 1.0 {
                    player.currentTime = player.duration * Double(progress)
                }
                player.play()
                self.audioPlayer = player
                self.isPlaying = true
                startProgressTimer()
                return
            } catch {
                print("VoiceNotePlayer error: \(error)")
            }
        }
        
        // Fallback visual playback for preloaded sample posts
        self.isPlaying = true
        if progress >= 1.0 { progress = 0.0 }
        startFallbackTimer()
    }
    
    public func pause() {
        timer?.invalidate()
        timer = nil
        audioPlayer?.pause()
        isPlaying = false
    }
    
    public func stop() {
        timer?.invalidate()
        timer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        progress = 0.0
        currentTime = 0
    }
    
    public func seek(to newProgress: CGFloat, fallbackDuration: Int) {
        let clamped = min(max(0.0, newProgress), 1.0)
        self.progress = clamped
        if let player = audioPlayer, player.duration > 0 {
            player.currentTime = player.duration * Double(clamped)
            self.currentTime = Int(player.currentTime)
        } else {
            self.currentTime = Int(Double(max(1, fallbackDuration)) * Double(clamped))
        }
    }
    
    private func startProgressTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                guard let player = self.audioPlayer, player.isPlaying, player.duration > 0 else { return }
                self.progress = CGFloat(player.currentTime / player.duration)
                self.currentTime = Int(player.currentTime)
            }
        }
    }
    
    private func startFallbackTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                let step = (0.05 * Double(self.playbackRate)) / Double(self.fallbackDuration)
                if self.progress + step >= 1.0 {
                    self.stop()
                } else {
                    self.progress += step
                    self.currentTime = Int(Double(self.fallbackDuration) * Double(self.progress))
                }
            }
        }
    }
    
    nonisolated public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.stop()
        }
    }
}

@MainActor
@Observable
public final class VoiceNoteRecorder: NSObject, @unchecked Sendable {
    public var isRecording: Bool = false
    public var isPaused: Bool = false
    public var recordedSeconds: Int = 0
    public var recordedURL: URL? = nil
    public var waveformSamples: [Float] = []
    public var permissionDenied: Bool = false
    
    private var recorder: AVAudioRecorder?
    private var durationTimer: Timer?
    private var meterTimer: Timer?
    
    public override init() {
        super.init()
    }
    
    public func startRecording() {
        Task {
            let granted = await requestPermission()
            guard granted else {
                self.permissionDenied = true
                return
            }
            self.permissionDenied = false
            self.beginRecording()
        }
    }
    
    public func pauseRecording() {
        guard isRecording, !isPaused else { return }
        recorder?.pause()
        durationTimer?.invalidate()
        meterTimer?.invalidate()
        isPaused = true
    }
    
    public func resumeRecording() {
        guard isRecording, isPaused, let recorder = recorder else { return }
        recorder.record()
        isPaused = false
        startTimers()
    }
    
    public func stopRecording() {
        durationTimer?.invalidate()
        durationTimer = nil
        meterTimer?.invalidate()
        meterTimer = nil
        recorder?.stop()
        recorder = nil
        isRecording = false
        isPaused = false
    }
    
    public func deleteRecording() {
        stopRecording()
        if let url = recordedURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordedURL = nil
        recordedSeconds = 0
        waveformSamples = []
    }
    
    private func beginRecording() {
        deleteRecording()
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)
            
            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("speak-together-voice-\(UUID().uuidString).m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            let newRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            newRecorder.isMeteringEnabled = true
            newRecorder.prepareToRecord()
            newRecorder.record()
            
            self.recorder = newRecorder
            self.recordedURL = fileURL
            self.recordedSeconds = 0
            self.waveformSamples = []
            self.isRecording = true
            self.isPaused = false
            
            startTimers()
        } catch {
            print("VoiceNoteRecorder failed to start: \(error)")
        }
    }
    
    private func startTimers() {
        durationTimer?.invalidate()
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.recordedSeconds += 1
            }
        }
        
        meterTimer?.invalidate()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.sampleAudioLevel()
            }
        }
    }
    
    private func sampleAudioLevel() {
        guard let recorder = recorder, recorder.isRecording else { return }
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0) // -160...0 dB
        let minDb: Float = -50.0
        let normalized: Float
        if power < minDb {
            normalized = 0.12
        } else {
            normalized = max(0.12, min(1.0, (power - minDb) / (-minDb)))
        }
        waveformSamples.append(normalized)
        if waveformSamples.count > 48 {
            waveformSamples.removeFirst()
        }
    }
    
    private func requestPermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
}
