import SwiftUI

public struct WhatsAppVoicePlayerView: View {
    @Bindable public var player: VoiceNotePlayer
    public let audioURL: URL?
    public let duration: Int
    public let waveformSamples: [Float]
    public var uploadProgress: Double? = nil
    public var onCancelUpload: (() -> Void)? = nil
    
    private static let defaultBars: [Float] = [
        0.28, 0.52, 0.78, 0.42, 0.90, 0.65, 0.35, 0.82, 0.58, 0.95,
        0.48, 0.70, 0.85, 0.38, 0.62, 0.88, 0.72, 0.44, 0.66, 0.50,
        0.76, 0.40, 0.32, 0.24
    ]
    
    public init(
        player: VoiceNotePlayer,
        audioURL: URL?,
        duration: Int,
        waveformSamples: [Float] = [],
        uploadProgress: Double? = nil,
        onCancelUpload: (() -> Void)? = nil
    ) {
        self.player = player
        self.audioURL = audioURL
        self.duration = max(1, duration)
        self.waveformSamples = waveformSamples
        self.uploadProgress = uploadProgress
        self.onCancelUpload = onCancelUpload
    }
    
    private var displayBars: [Float] {
        if waveformSamples.count >= 12 {
            // Resample to 28 bars for a crisp WhatsApp waveform
            let targetCount = 28
            return (0..<targetCount).map { i in
                let idx = Int(Double(i) / Double(targetCount) * Double(waveformSamples.count))
                return waveformSamples[min(idx, waveformSamples.count - 1)]
            }
        }
        return Self.defaultBars
    }
    
    public var body: some View {
        HStack(spacing: AppTheme.space12) {
            // Play / Pause OR WhatsApp Circular Upload Progress Ring
            if let uploadProgress {
                Button(action: { onCancelUpload?() }) {
                    ZStack {
                        Circle()
                            .stroke(AppTheme.separator, lineWidth: 2.5)
                            .frame(width: 38, height: 38)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(uploadProgress))
                            .stroke(AppTheme.primaryBlue, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .frame(width: 38, height: 38)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.08), value: uploadProgress)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.primaryBlue)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button(action: {
                    player.togglePlayback(url: audioURL, fallbackDuration: duration)
                }) {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(AppTheme.primaryBlue)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Interactive Scrubbable Waveform + Scrubber Dot + Time & Speed Row
            VStack(spacing: 4) {
                GeometryReader { geo in
                    let bars = displayBars
                    let spacing: CGFloat = 2.5
                    let barWidth = max(2, (geo.size.width - CGFloat(bars.count - 1) * spacing) / CGFloat(bars.count))
                    
                    ZStack(alignment: .leading) {
                        HStack(spacing: spacing) {
                            ForEach(0..<bars.count, id: \.self) { index in
                                let ratio = CGFloat(index) / CGFloat(max(1, bars.count - 1))
                                let isFilled = ratio <= player.progress
                                let barHeight = max(4, CGFloat(bars[index]) * 26)
                                
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(isFilled ? AppTheme.primaryBlue : AppTheme.secondaryText.opacity(0.32))
                                    .frame(width: barWidth, height: barHeight)
                            }
                        }
                        .frame(maxHeight: .infinity, alignment: .center)
                        
                        // Classic WhatsApp Scrubber Dot
                        Circle()
                            .fill(AppTheme.primaryBlue)
                            .frame(width: 10, height: 10)
                            .offset(x: max(0, min(geo.size.width - 10, player.progress * (geo.size.width - 10))))
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard uploadProgress == nil else { return }
                                let fraction = value.location.x / max(1, geo.size.width)
                                player.seek(to: fraction, fallbackDuration: duration)
                            }
                    )
                }
                .frame(height: 28)
                
                // Bottom Row: Time & 1x/1.5x/2x Speed Toggle
                HStack {
                    if let uploadProgress {
                        Text("Uploading \(Int(uploadProgress * 100))%...")
                            .font(.system(size: 11, weight: .medium).monospacedDigit())
                            .foregroundColor(AppTheme.primaryBlue)
                    } else {
                        Text(formatDuration(player.isPlaying || player.progress > 0 ? player.currentTime : duration))
                            .font(.system(size: 11, weight: .medium).monospacedDigit())
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    if uploadProgress == nil {
                        Button(action: {
                            player.cyclePlaybackRate()
                        }) {
                            Text(player.playbackRateLabel)
                                .font(.system(size: 11, weight: .bold).monospacedDigit())
                                .foregroundColor(player.playbackRate == 1.0 ? AppTheme.secondaryText : AppTheme.primaryBlue)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(player.playbackRate == 1.0 ? AppTheme.neutralSubtle : AppTheme.primaryBlue.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.space12)
        .padding(.vertical, 10)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

#Preview {
    VStack(spacing: 16) {
        WhatsAppVoicePlayerView(player: VoiceNotePlayer(), audioURL: nil, duration: 45)
        WhatsAppVoicePlayerView(player: VoiceNotePlayer(), audioURL: nil, duration: 45, uploadProgress: 0.65)
    }
    .padding()
    .background(AppTheme.background)
}
