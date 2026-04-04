//
//  EmotionState.swift
//  ClaudeIsland
//
//  Emotion state machine for the crab character.
//  Tracks sentiment from user prompts and drives visual expression.
//  Ported from Notchi (sk-ruban/notchi) with adaptations for Claude Island.
//

import Foundation
import os.log

private let logger = Logger(subsystem: "com.claudeisland", category: "EmotionState")

/// Emotions the turtle can express
enum CrabEmotion: String, CaseIterable, Sendable {
    case neutral, happy, sad, sob, curious, excited, confused
}

/// Observable emotion state that accumulates sentiment over time
@MainActor
@Observable
final class EmotionState {
    private(set) var currentEmotion: CrabEmotion = .neutral
    private(set) var scores: [CrabEmotion: Double] = [
        .happy: 0.0,
        .sad: 0.0,
        .curious: 0.0,
        .excited: 0.0,
        .confused: 0.0,
    ]

    // MARK: - Thresholds

    static let sadThreshold = 0.45
    static let happyThreshold = 0.6
    static let sobEscalationThreshold = 0.9
    static let curiousThreshold = 0.5
    static let excitedThreshold = 0.7
    static let confusedThreshold = 0.5
    static let intensityDampen = 0.5
    static let decayRate = 0.92
    static let interEmotionDecay = 0.9
    static let neutralCounterDecay = 0.85
    static let decayIntervalSeconds: TimeInterval = 60

    init() {}

    /// Record a new emotion analysis result
    func recordEmotion(_ rawEmotion: String, intensity: Double) {
        let emotion = CrabEmotion(rawValue: rawEmotion)

        if let emotion, emotion != .neutral {
            let dampened = intensity * Self.intensityDampen
            scores[emotion, default: 0.0] = min(scores[emotion, default: 0.0] + dampened, 1.0)
            for key in scores.keys where key != emotion {
                scores[key, default: 0.0] *= Self.interEmotionDecay
            }
        } else {
            for key in scores.keys {
                scores[key, default: 0.0] *= Self.neutralCounterDecay
            }
        }

        updateCurrentEmotion()
        logger.info("[Emotion] detected: \(rawEmotion, privacy: .public) (\(String(format: "%.2f", intensity), privacy: .public)) -> \(self.currentEmotion.rawValue, privacy: .public) scores=\(self.scores.map { "\($0.key.rawValue):\(String(format: "%.3f", $0.value))" }.joined(separator: ","), privacy: .public)")
    }

    /// Decay all scores (called on timer)
    func decayAll() {
        var anyChanged = false
        for key in scores.keys {
            let old = scores[key, default: 0.0]
            let decayed = old * Self.decayRate
            scores[key] = decayed < 0.01 ? 0.0 : decayed
            if scores[key] != old { anyChanged = true }
        }
        if anyChanged {
            updateCurrentEmotion()
        }
    }

    /// Reset to neutral
    func reset() {
        scores = [.happy: 0.0, .sad: 0.0, .curious: 0.0, .excited: 0.0, .confused: 0.0]
        currentEmotion = .neutral
    }

    private func updateCurrentEmotion() {
        let best = scores.max(by: { $0.value < $1.value })

        if let best {
            let threshold: Double
            switch best.key {
            case .sad: threshold = Self.sadThreshold
            case .curious: threshold = Self.curiousThreshold
            case .excited: threshold = Self.excitedThreshold
            case .confused: threshold = Self.confusedThreshold
            default: threshold = Self.happyThreshold
            }
            if best.value >= threshold {
                if best.key == .sad && best.value >= Self.sobEscalationThreshold {
                    currentEmotion = .sob
                } else {
                    currentEmotion = best.key
                }
            } else {
                currentEmotion = .neutral
            }
        } else {
            currentEmotion = .neutral
        }
    }
}
