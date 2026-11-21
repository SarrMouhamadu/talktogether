import SwiftUI
import PhotosUI

public struct CreateFeedPostView: View {
    @Environment(\.dismiss) private var dismiss
    
    public let currentUser: User
    public let availableTopics: [Topic]
    public let editingPost: FeedPost?
    public var onPublish: (FeedPost) -> Void
    
    @State private var quoteText: String
    @State private var captionText: String
    @State private var selectedTopicTitle: String?
    @State private var selectedStance: DebateStance?
    
    // Photo picker (Images ONLY — No Videos)
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data?
    
    // Existing audio when editing
    @State private var existingAudioURL: URL?
    @State private var existingAudioDuration: Int?
    @State private var existingWaveform: [Float]
    
    // Real WhatsApp-style Voice Recording & Pre-Share Playback
    @State private var voiceRecorder = VoiceNoteRecorder()
    @State private var voicePlayer = VoiceNotePlayer()
    
    public init(
        currentUser: User,
        availableTopics: [Topic] = Topic.sampleTopics,
        editingPost: FeedPost? = nil,
        onPublish: @escaping (FeedPost) -> Void
    ) {
        self.currentUser = currentUser
        self.availableTopics = availableTopics
        self.editingPost = editingPost
        self.onPublish = onPublish
        
        _quoteText = State(initialValue: editingPost?.quoteText ?? "")
        _captionText = State(initialValue: editingPost?.caption ?? "")
        _selectedTopicTitle = State(initialValue: editingPost?.topicTitle)
        _selectedStance = State(initialValue: editingPost?.stance)
        _selectedImageData = State(initialValue: editingPost?.imageData)
        _existingAudioURL = State(initialValue: editingPost?.audioURL)
        _existingAudioDuration = State(initialValue: editingPost?.audioDurationSeconds)
        _existingWaveform = State(initialValue: editingPost?.waveformSamples ?? [])
    }
    
    private var isEditing: Bool { editingPost != nil }
    
    private var activeAudioURL: URL? {
        voiceRecorder.recordedURL ?? existingAudioURL
    }
    
    private var activeAudioDuration: Int? {
        if voiceRecorder.recordedURL != nil {
            return max(1, voiceRecorder.recordedSeconds)
        }
        return existingAudioDuration
    }
    
    private var activeWaveform: [Float] {
        if !voiceRecorder.waveformSamples.isEmpty {
            return voiceRecorder.waveformSamples
        }
        return existingWaveform
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.space20) {
                    // Author Header
                    HStack(spacing: AppTheme.space12) {
                        Circle()
                            .fill(AppTheme.primaryBlue.opacity(0.10))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(currentUser.initials)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryBlue)
                            )
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(currentUser.username)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.primaryText)
                            Text("Voice, photo, or text")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        
                        Spacer()
                    }
                    
                    // WhatsApp-style Photo Preview with File Size & Quick Remove
                    if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 250)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                                .overlay(alignment: .bottomLeading) {
                                    Text("Photo · \(formattedFileSize(imageData.count))")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.black.opacity(0.55))
                                        .clipShape(Capsule())
                                        .padding(AppTheme.space12)
                                }
                            
                            Button(action: {
                                withAnimation {
                                    selectedImageData = nil
                                    selectedPhotoItem = nil
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 30, height: 30)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(AppTheme.space12)
                        }
                    }
                    
                    // WhatsApp-Style Voice Recording & Pre-Share Playback Section
                    whatsAppVoiceSection
                    
                    // WhatsApp-Style Quick Photo Upload Row (Images Only — No Video)
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                        HStack(spacing: AppTheme.space12) {
                            Image(systemName: "photo")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppTheme.primaryBlue)
                                .frame(width: 36, height: 36)
                                .background(AppTheme.primaryBlue.opacity(0.10))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(selectedImageData == nil ? "Upload a photo" : "Replace photo")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.primaryText)
                                Text("Images only · Instant upload")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        .padding(.horizontal, AppTheme.space16)
                        .padding(.vertical, AppTheme.space12)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                                .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                await MainActor.run {
                                    selectedImageData = data
                                }
                            }
                        }
                    }
                    
                    // Optional Quote & Caption Composer
                    VStack(spacing: 0) {
                        TextField("Share your argument or quote (optional)...", text: $quoteText, axis: .vertical)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.primaryText)
                            .lineLimit(2...5)
                            .padding(AppTheme.space16)
                        
                        Rectangle()
                            .fill(AppTheme.separator)
                            .frame(height: 1)
                            .padding(.leading, AppTheme.space16)
                        
                        TextField("Add a caption (optional)...", text: $captionText, axis: .vertical)
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.primaryText)
                            .lineLimit(2...4)
                            .padding(AppTheme.space16)
                    }
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                            .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                    )
                    
                    // Optional Topic & Stance Group
                    VStack(spacing: 0) {
                        Menu {
                            Button("None") { selectedTopicTitle = nil }
                            Divider()
                            ForEach(availableTopics) { topic in
                                Button(topic.title) {
                                    selectedTopicTitle = topic.title
                                }
                            }
                        } label: {
                            HStack {
                                Text("Debate Topic")
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.primaryText)
                                Spacer()
                                HStack(spacing: AppTheme.space6) {
                                    Text(selectedTopicTitle ?? "Optional")
                                        .font(.system(size: 14))
                                        .foregroundColor(selectedTopicTitle == nil ? AppTheme.secondaryText : AppTheme.primaryBlue)
                                        .lineLimit(1)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                            }
                            .padding(.horizontal, AppTheme.space16)
                            .frame(height: 50)
                        }
                        
                        Rectangle()
                            .fill(AppTheme.separator)
                            .frame(height: 1)
                            .padding(.leading, AppTheme.space16)
                        
                        Menu {
                            Button("None") { selectedStance = nil }
                            Divider()
                            ForEach(DebateStance.allCases) { stance in
                                Button(stance.rawValue) {
                                    selectedStance = stance
                                }
                            }
                        } label: {
                            HStack {
                                Text("Stance")
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.primaryText)
                                Spacer()
                                HStack(spacing: AppTheme.space6) {
                                    Text(selectedStance?.rawValue ?? "Optional")
                                        .font(.system(size: 14))
                                        .foregroundColor(selectedStance == nil ? AppTheme.secondaryText : AppTheme.primaryBlue)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                            }
                            .padding(.horizontal, AppTheme.space16)
                            .frame(height: 50)
                        }
                    }
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                            .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                    )
                }
                .padding(.horizontal, AppTheme.space20)
                .padding(.top, AppTheme.space16)
                .padding(.bottom, AppTheme.space32)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Post" : "New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        voicePlayer.stop()
                        if !isEditing {
                            voiceRecorder.deleteRecording()
                        } else if voiceRecorder.isRecording {
                            voiceRecorder.stopRecording()
                        }
                        dismiss()
                    }
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.secondaryText)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Share") {
                        publishPost()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(canPublish ? AppTheme.primaryBlue : AppTheme.secondaryText.opacity(0.4))
                    .disabled(!canPublish)
                }
            }
            .onDisappear {
                voicePlayer.stop()
                if voiceRecorder.isRecording {
                    voiceRecorder.stopRecording()
                }
            }
        }
    }
    
    // MARK: - WhatsApp-Style Voice Recording & Preview Card
    private var whatsAppVoiceSection: some View {
        VStack(spacing: AppTheme.space12) {
            if voiceRecorder.isRecording {
                // STATE 1: Actively Recording OR Paused (WhatsApp Controls: Trash | Pause/Resume | Done)
                VStack(spacing: AppTheme.space16) {
                    HStack(spacing: AppTheme.space12) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(voiceRecorder.isPaused ? AppTheme.secondaryText : AppTheme.liveRed)
                                .frame(width: 8, height: 8)
                            Text(formatDuration(voiceRecorder.recordedSeconds))
                                .font(.system(size: 15, weight: .semibold).monospacedDigit())
                                .foregroundColor(AppTheme.primaryText)
                        }
                        
                        // Live Reactive Scrolling Waveform
                        HStack(spacing: 2.5) {
                            let samples = voiceRecorder.waveformSamples.suffix(30)
                            ForEach(Array(samples.enumerated()), id: \.offset) { _, level in
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(voiceRecorder.isPaused ? AppTheme.secondaryText.opacity(0.4) : AppTheme.liveRed)
                                    .frame(width: 3, height: max(4, CGFloat(level) * 28))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .frame(height: 30)
                    }
                    
                    // WhatsApp 3-Button Recording Bar: Discard | Pause/Resume | Finish
                    HStack {
                        Button(action: {
                            voicePlayer.stop()
                            voiceRecorder.deleteRecording()
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppTheme.secondaryText)
                                .frame(width: 42, height: 42)
                                .background(AppTheme.background)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        Button(action: {
                            if voiceRecorder.isPaused {
                                voiceRecorder.resumeRecording()
                            } else {
                                voiceRecorder.pauseRecording()
                            }
                        }) {
                            Image(systemName: voiceRecorder.isPaused ? "mic.fill" : "pause.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.liveRed)
                                .frame(width: 46, height: 46)
                                .background(AppTheme.liveRedSubtle)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        Button(action: {
                            voiceRecorder.stopRecording()
                        }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 42, height: 42)
                                .background(AppTheme.primaryBlue)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(AppTheme.space16)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                        .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                )
            } else if let duration = activeAudioDuration {
                // STATE 2: Recorded Preview — Scrubbable WhatsApp Player + Delete
                VStack(spacing: AppTheme.space8) {
                    WhatsAppVoicePlayerView(
                        player: voicePlayer,
                        audioURL: activeAudioURL,
                        duration: duration,
                        waveformSamples: activeWaveform
                    )
                    
                    HStack {
                        Text("Preview your voice note before sharing")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.secondaryText)
                        Spacer()
                        Button(role: .destructive, action: {
                            voicePlayer.stop()
                            voiceRecorder.deleteRecording()
                            existingAudioURL = nil
                            existingAudioDuration = nil
                            existingWaveform = []
                        }) {
                            Label("Delete", systemImage: "trash")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.liveRed)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, AppTheme.space4)
                }
            } else {
                // STATE 3: Idle — Tap to Start WhatsApp Voice Recording
                Button(action: {
                    voicePlayer.stop()
                    voiceRecorder.startRecording()
                }) {
                    HStack(spacing: AppTheme.space12) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(AppTheme.primaryBlue)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Record a voice note")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.primaryText)
                            Text("Pause, resume & preview before sharing")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "waveform")
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding(.horizontal, AppTheme.space16)
                    .padding(.vertical, AppTheme.space12)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                            .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if voiceRecorder.permissionDenied {
                Text("Microphone access is required in Settings to record voice notes.")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.liveRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - Validation (Voice-only, Photo-only, or Text-only are all valid!)
    private var canPublish: Bool {
        guard !voiceRecorder.isRecording else { return false }
        let hasText = !quoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                      !captionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasVoice = activeAudioDuration != nil
        let hasPhoto = selectedImageData != nil
        return hasText || hasVoice || hasPhoto
    }
    
    private func publishPost() {
        voicePlayer.stop()
        let trimmedQuote = quoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCaption = captionText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if var updated = editingPost {
            updated.topicTitle = selectedTopicTitle
            updated.stance = selectedStance
            updated.quoteText = trimmedQuote.isEmpty ? nil : trimmedQuote
            updated.caption = trimmedCaption.isEmpty ? nil : trimmedCaption
            updated.imageData = selectedImageData
            updated.audioURL = activeAudioURL
            updated.audioDurationSeconds = activeAudioDuration
            updated.waveformSamples = activeWaveform
            onPublish(updated)
        } else {
            let newPost = FeedPost(
                author: currentUser,
                topicTitle: selectedTopicTitle,
                stance: selectedStance,
                quoteText: trimmedQuote.isEmpty ? nil : trimmedQuote,
                caption: trimmedCaption.isEmpty ? nil : trimmedCaption,
                imageData: selectedImageData,
                audioURL: activeAudioURL,
                audioDurationSeconds: activeAudioDuration,
                waveformSamples: activeWaveform,
                likesCount: 0,
                isLiked: false,
                isBookmarked: false,
                comments: [],
                createdAtText: "Just now"
            )
            onPublish(newPost)
        }
        dismiss()
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
    
    private func formattedFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

#Preview {
    CreateFeedPostView(currentUser: User.sampleModerator) { _ in }
}
