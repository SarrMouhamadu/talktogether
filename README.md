# WaxUp (Talk Together)

WaxUp is an iOS audio-first language exchange and structured debate platform built with SwiftUI and AVFoundation. It enables English learners and speakers across Africa and the world to practice public speaking, debate controversial or daily life topics, share voice notes, and build daily speaking streaks.

## Features

- **Live Debate Rooms**: Structured audio debates with moderator, affirmative, and negative stances, hand-raising, and speaking turn countdown timers.
- **Continuous Queue System**: Automatic FIFO schedule advancing topics seamlessly as debates conclude.
- **Audio Feed & Voice Notes**: WhatsApp-style voice messaging, media posts, comments, likes, and bookmarks.
- **Executive Admin Dashboard**:
  - Live Room Pulse & continuous queue monitoring.
  - Comprehensive user analytics (active, suspended, admins, country, proficiency breakdown).
  - Detailed user inspection with account suspension, promotion, and moderation controls.
  - Real-time hardware & audio telemetry (memory, thermal state, CPU, AVFoundation status, permissions).
  - Moderation queue for user-submitted content reports.
- **Gamification & Vocabulary**: Daily streaks, saved idioms and expressions, and leaderboards.
- **Privacy & Security**: Non-exempt encryption compliance, complete in-app Privacy Policy, and account deletion.

## Requirements

- iOS 17.0+
- Xcode 15.0+ / Swift 5.9+
- Device with microphone support

## Architecture

- **UI**: 100% SwiftUI with clean design tokens (`AppTheme.swift`).
- **State Management**: `@Observable` architecture (`DebateManager`, `AuthManager`, `AudioService`).
- **Audio Pipeline**: AVFoundation (`AVAudioSession`, `AVAudioRecorder`, `AVAudioPlayer`) with low-latency playback and recording.
- **Persistence**: Structured local storage with `UserDefaults` and file-based audio caches.

## License

All rights reserved © 2026 Sylla English Academy / Mouhamadou Sarr.
