//
//  EmotionManager.swift
//  ClaudeIsland
//
//  Coordinates emotion analysis and decay for all sessions.
//  Provides per-session emotion state for the UI layer.
//

import Combine
import Foundation
import os.log

private let logger = Logger(subsystem: "com.claudeisland", category: "EmotionManager")

@MainActor
final class EmotionManager: ObservableObject {
    static let shared = EmotionManager()

    /// Per-session emotion states -- @Published so SwiftUI views re-render on change
    @Published private(set) var sessionEmotions: [String: CrabEmotion] = [:]

    /// Internal emotion state objects per session
    private var states: [String: EmotionState] = [:]

    /// Decay timer
    private var decayTimer: Timer?

    private init() {
        startDecayTimer()
    }

    // MARK: - Public API

    /// Get the current emotion for a session
    func emotion(for sessionId: String) -> CrabEmotion {
        sessionEmotions[sessionId] ?? .neutral
    }

    /// Analyze a user prompt and update emotion for that session
    func analyzePrompt(_ prompt: String, sessionId: String) {
        // Don't analyze empty prompts or slash commands
        guard !prompt.isEmpty, !prompt.hasPrefix("/") else { return }

        Task { @MainActor in
            let result = await EmotionAnalyzer.shared.analyze(prompt)
            let state = getOrCreateState(for: sessionId)
            state.recordEmotion(result.emotion, intensity: result.intensity)
            sessionEmotions[sessionId] = state.currentEmotion
        }
    }

    /// Remove emotion state for a session
    func removeSession(_ sessionId: String) {
        states.removeValue(forKey: sessionId)
        sessionEmotions.removeValue(forKey: sessionId)
    }

    // MARK: - Private

    private func getOrCreateState(for sessionId: String) -> EmotionState {
        if let existing = states[sessionId] {
            return existing
        }
        let state = EmotionState()
        states[sessionId] = state
        return state
    }

    private func startDecayTimer() {
        decayTimer = Timer.scheduledTimer(withTimeInterval: EmotionState.decayIntervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.decayAllStates()
            }
        }
    }

    private func decayAllStates() {
        for (sessionId, state) in states {
            state.decayAll()
            sessionEmotions[sessionId] = state.currentEmotion
        }
    }
}
