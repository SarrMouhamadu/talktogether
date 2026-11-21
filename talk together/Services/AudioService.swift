import Foundation
import AVFoundation
import SwiftUI

@MainActor
@Observable
public final class AudioService: NSObject, @unchecked Sendable {
    public static let shared = AudioService()
    
    // MARK: - Published Properties
    public var isMuted: Bool = true
    public var isSpeaking: Bool = false
    public var audioLevel: Float = 0.0 // 0.0 to 1.0 normalized
    public var permissionGranted: Bool = false
    public var isSessionActive: Bool = false
    
    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?
    
    public override init() {
        super.init()
        checkPermission()
    }
    
    // MARK: - Permission
    public func checkPermission() {
        if #available(iOS 17.0, *) {
            permissionGranted = AVAudioApplication.shared.recordPermission == .granted
        } else {
            permissionGranted = AVAudioSession.sharedInstance().recordPermission == .granted
        }
    }
    
    public func requestMicrophoneAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            let granted = await AVAudioApplication.requestRecordPermission()
            self.permissionGranted = granted
            return granted
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    Task { @MainActor in
                        self.permissionGranted = granted
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }
    
    // MARK: - Session Configuration
    public func startAudioSession() {
        guard !isSessionActive else { return }
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetoothHFP, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            isSessionActive = true
            
            // Start local level meter if unmuted
            if !isMuted {
                startMonitoringVoiceLevel()
            }
        } catch {
            print("Failed to activate audio session: \(error)")
        }
    }
    
    public func stopAudioSession() {
        stopMonitoringVoiceLevel()
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
            isSessionActive = false
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    // MARK: - Mute Controls
    public func toggleMute() {
        if isMuted {
            unmute()
        } else {
            mute()
        }
    }
    
    public func mute() {
        isMuted = true
        isSpeaking = false
        audioLevel = 0.0
        stopMonitoringVoiceLevel()
    }
    
    public func unmute() {
        Task {
            if !permissionGranted {
                let granted = await requestMicrophoneAccess()
                guard granted else { return }
            }
            self.isMuted = false
            self.startAudioSession()
            self.startMonitoringVoiceLevel()
        }
    }
    
    // MARK: - Voice Activity Detection (VAD)
    private func startMonitoringVoiceLevel() {
        stopMonitoringVoiceLevel()
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]
        
        let tempURL = URL(fileURLWithPath: "/dev/null")
        
        do {
            audioRecorder = try AVAudioRecorder(url: tempURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.updateMeters()
                }
            }
        } catch {
            print("Audio meter error: \(error)")
        }
    }
    
    private func stopMonitoringVoiceLevel() {
        levelTimer?.invalidate()
        levelTimer = nil
        audioRecorder?.stop()
        audioRecorder = nil
        isSpeaking = false
        audioLevel = 0.0
    }
    
    private func updateMeters() {
        guard let recorder = audioRecorder, recorder.isRecording, !isMuted else {
            isSpeaking = false
            audioLevel = 0.0
            return
        }
        
        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0) // range: -160 to 0 dB
        
        // Convert dB to 0.0 - 1.0 scale (considering -45dB as background noise threshold)
        let minDb: Float = -45.0
        if averagePower < minDb {
            audioLevel = 0.0
            isSpeaking = false
        } else {
            let normalized = max(0.0, min(1.0, (averagePower - minDb) / (-minDb)))
            audioLevel = normalized
            // Threshold for human speech activity
            isSpeaking = averagePower > -32.0
        }
    }
}
