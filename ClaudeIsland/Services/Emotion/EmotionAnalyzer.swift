//
//  EmotionAnalyzer.swift
//  ClaudeIsland
//
//  Analyzes user prompts for sentiment using the Anthropic Messages API directly.
//  Uses an API key from ~/.claude-island-config.json to avoid spawning the CLI
//  (which triggers macOS TCC permission dialogs as a subprocess).
//

import Foundation
import os.log

private let logger = Logger(subsystem: "com.claudeisland", category: "EmotionAnalyzer")

@MainActor
final class EmotionAnalyzer {
    static let shared = EmotionAnalyzer()

    nonisolated private static let validEmotions: Set<String> = ["happy", "sad", "neutral", "curious", "excited", "confused"]
    private var apiKey: String?

    private init() {
        apiKey = Self.loadAPIKey()
    }

    func analyze(_ prompt: String) async -> (emotion: String, intensity: Double) {
        guard let key = apiKey, !key.isEmpty else {
            logger.info("No Anthropic API key configured, defaulting to neutral")
            return ("neutral", 0.0)
        }

        do {
            return try await callAPI(prompt: prompt, apiKey: key)
        } catch {
            logger.error("Emotion analysis failed: \(error.localizedDescription)")
            return ("neutral", 0.0)
        }
    }

    // MARK: - Direct API Call

    private func callAPI(prompt: String, apiKey: String) async throws -> (emotion: String, intensity: Double) {
        let truncated = String(prompt.prefix(300))

        let systemPrompt = """
        Classify the emotional tone of this user message into exactly one emotion and intensity score.
        Emotions: happy, sad, neutral, curious, excited, confused.
        Happy: praise, gratitude, celebration, positive profanity.
        Sad: frustration, anger, insults, complaints, disappointment, negative profanity.
        Curious: exploration, "what if", "how does", investigating, learning, researching.
        Excited: breakthroughs, "YES!", amazement, "this is amazing", "holy shit it works", celebration of progress.
        Confused: "why is this broken", "I don't understand", debugging frustration, "what the hell", error reports.
        Neutral: plain instructions, requests, task descriptions. Most coding instructions are neutral.
        Intensity: 0.0 to 1.0. ALL CAPS increases intensity by 0.2-0.3.
        Reply with ONLY valid JSON: {"emotion": "...", "intensity": ...}
        """

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 10

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 64,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": "Message: \(truncated)"]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            logger.error("API returned status \(statusCode)")
            return ("neutral", 0.0)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            logger.info("Could not parse API response")
            return ("neutral", 0.0)
        }

        // Extract JSON from response text
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let start = cleaned.firstIndex(of: "{"), let end = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[start ... end])
        }

        if let jsonData = cleaned.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let emotion = parsed["emotion"] as? String,
           let intensity = parsed["intensity"] as? Double {
            let validEmotion = Self.validEmotions.contains(emotion) ? emotion : "neutral"
            let clampedIntensity = min(max(intensity, 0.0), 1.0)
            logger.info("[Emotion API] \(validEmotion, privacy: .public) (\(String(format: "%.2f", clampedIntensity), privacy: .public))")
            return (validEmotion, clampedIntensity)
        }

        logger.info("Could not parse emotion from: \(text.prefix(100))")
        return ("neutral", 0.0)
    }

    // MARK: - API Key Loading

    /// Loads API key from ~/.claude-island-config.json or environment
    nonisolated private static func loadAPIKey() -> String? {
        // 1. Check environment
        if let envKey = Foundation.ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"],
           !envKey.isEmpty {
            logger.info("Using ANTHROPIC_API_KEY from environment")
            return envKey
        }

        // 2. Check ~/.claude-island-config.json
        let configPath = NSHomeDirectory() + "/.claude-island-config.json"
        if let data = FileManager.default.contents(atPath: configPath),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let key = json["anthropic_api_key"] as? String,
           !key.isEmpty {
            logger.info("Using API key from ~/.claude-island-config.json")
            return key
        }

        logger.warning("No Anthropic API key found. Create ~/.claude-island-config.json with {\"anthropic_api_key\": \"sk-ant-...\"}")
        return nil
    }
}
