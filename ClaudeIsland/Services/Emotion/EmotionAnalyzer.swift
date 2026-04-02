//
//  EmotionAnalyzer.swift
//  ClaudeIsland
//
//  Analyzes user prompts for sentiment using Claude Haiku.
//  Reads API key from Keychain or ~/.claude/settings.json.
//  Ported from Notchi (sk-ruban/notchi) with adaptations.
//

import Foundation
import os.log

private let logger = Logger(subsystem: "com.claudeisland", category: "EmotionAnalyzer")

@MainActor
final class EmotionAnalyzer {
    static let shared = EmotionAnalyzer()

    private static let validEmotions: Set<String> = ["happy", "sad", "neutral"]

    private static let systemPrompt = """
        Classify the emotional tone of the user's message into exactly one emotion and an intensity score.
        Emotions: happy, sad, neutral.
        Happy: explicit praise ("great job", "thank you!"), gratitude, celebration, positive profanity ("LETS FUCKING GO").
        Sad: frustration, anger, insults, complaints, feeling stuck, disappointment, negative profanity.
        Neutral: instructions, requests, task descriptions, questions, enthusiasm about work, factual statements. \
        Exclamation marks or urgency about a task do NOT make it happy -- only genuine positive sentiment toward the AI or outcome does.
        Default to neutral when unsure. Most coding instructions are neutral regardless of tone.
        Intensity: 0.0 (barely noticeable) to 1.0 (very strong). ALL CAPS text indicates stronger emotion -- \
        increase intensity by 0.2-0.3 compared to the same message in lowercase.
        Reply with ONLY valid JSON: {"emotion": "...", "intensity": ...}
        """

    private init() {}

    func analyze(_ prompt: String) async -> (emotion: String, intensity: Double) {
        guard let config = resolveAPIConfig() else {
            logger.info("No API config available for emotion analysis, using neutral")
            return ("neutral", 0.0)
        }

        do {
            return try await callHaiku(prompt: prompt, config: config)
        } catch {
            logger.error("Emotion analysis failed: \(error.localizedDescription)")
            return ("neutral", 0.0)
        }
    }

    // MARK: - API Config Resolution

    private struct APIConfig {
        let url: URL
        let apiKey: String
        let model: String
    }

    private func resolveAPIConfig() -> APIConfig? {
        // Try ~/.claude/settings.json
        let settingsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")

        guard let data = try? Data(contentsOf: settingsURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let env = json["env"] as? [String: String]
        else {
            return nil
        }

        let authToken = env["ANTHROPIC_AUTH_TOKEN"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !authToken.isEmpty else { return nil }

        let baseURL = env["ANTHROPIC_BASE_URL"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "https://api.anthropic.com"
        let model = env["ANTHROPIC_DEFAULT_HAIKU_MODEL"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "claude-haiku-4-5-20251001"

        guard let apiURL = URL(string: "\(baseURL)/v1/messages") else { return nil }

        return APIConfig(url: apiURL, apiKey: authToken, model: model)
    }

    // MARK: - Haiku API Call

    private struct HaikuResponse: Decodable {
        let content: [ContentBlock]
        struct ContentBlock: Decodable {
            let text: String?
        }
    }

    private struct EmotionResponse: Decodable {
        let emotion: String
        let intensity: Double
    }

    private func callHaiku(prompt: String, config: APIConfig) async throws -> (emotion: String, intensity: Double) {
        var request = URLRequest(url: config.url)
        request.httpMethod = "POST"
        request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": config.model,
            "max_tokens": 50,
            "system": Self.systemPrompt,
            "messages": [
                ["role": "user", "content": String(prompt.prefix(500))],
            ],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let haikuResponse = try JSONDecoder().decode(HaikuResponse.self, from: data)
        guard let text = haikuResponse.content.first?.text else {
            throw URLError(.cannotParseResponse)
        }

        // Extract JSON from potential markdown code blocks
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let start = cleaned.firstIndex(of: "{"), let end = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[start ... end])
        }

        let emotionResponse = try JSONDecoder().decode(EmotionResponse.self, from: Data(cleaned.utf8))
        let emotion = Self.validEmotions.contains(emotionResponse.emotion) ? emotionResponse.emotion : "neutral"
        let intensity = min(max(emotionResponse.intensity, 0.0), 1.0)

        return (emotion, intensity)
    }
}
