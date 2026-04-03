//
//  EmotionAnalyzer.swift
//  ClaudeIsland
//
//  Analyzes user prompts for sentiment using the local `claude` CLI.
//  Uses the user's existing Claude Code authentication (Max subscription).
//

import Foundation
import os.log

private let logger = Logger(subsystem: "com.claudeisland", category: "EmotionAnalyzer")

@MainActor
final class EmotionAnalyzer {
    static let shared = EmotionAnalyzer()

    nonisolated private static let validEmotions: Set<String> = ["happy", "sad", "neutral"]

    private init() {}

    func analyze(_ prompt: String) async -> (emotion: String, intensity: Double) {
        do {
            return try await callCLI(prompt: prompt)
        } catch {
            logger.error("Emotion analysis failed: \(error.localizedDescription)")
            return ("neutral", 0.0)
        }
    }

    // MARK: - CLI Call

    private func callCLI(prompt: String) async throws -> (emotion: String, intensity: Double) {
        let truncated = String(prompt.prefix(300))

        let cliPrompt = """
        Classify the emotional tone of this user message into exactly one emotion and intensity score.
        Emotions: happy, sad, neutral.
        Happy: explicit praise, gratitude, celebration, positive profanity.
        Sad: frustration, anger, insults, complaints, disappointment, negative profanity.
        Neutral: instructions, requests, questions, task descriptions. Most coding instructions are neutral.
        Intensity: 0.0 to 1.0. ALL CAPS increases intensity by 0.2-0.3.
        Reply with ONLY valid JSON: {"emotion": "...", "intensity": ...}

        Message: \(truncated)
        """

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let process = Process()
                let pipe = Pipe()

                // Find claude CLI
                let claudePath = Self.findClaudeCLI()
                guard let path = claudePath else {
                    continuation.resume(returning: ("neutral", 0.0))
                    return
                }

                process.executableURL = URL(fileURLWithPath: path)
                process.arguments = [
                    "-p",
                    "--model", "haiku",
                    "--no-session-persistence",
                    cliPrompt
                ]
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice

                // Inherit the full environment so claude CLI gets NODE_PATH, NVM dirs, etc.
                var env = Foundation.ProcessInfo.processInfo.environment
                // Ensure common CLI paths are present
                let extraPaths = "/usr/local/bin:/opt/homebrew/bin"
                if let existing = env["PATH"] {
                    env["PATH"] = extraPaths + ":" + existing
                } else {
                    env["PATH"] = extraPaths + ":/usr/bin:/bin"
                }
                process.environment = env

                do {
                    try process.run()
                    process.waitUntilExit()

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    guard let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                          !output.isEmpty else {
                        logger.info("Empty CLI output, defaulting to neutral")
                        continuation.resume(returning: ("neutral", 0.0))
                        return
                    }

                    // Extract JSON from output (might have extra text)
                    var cleaned = output
                    if let start = cleaned.firstIndex(of: "{"), let end = cleaned.lastIndex(of: "}") {
                        cleaned = String(cleaned[start ... end])
                    }

                    if let jsonData = cleaned.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let emotion = json["emotion"] as? String,
                       let intensity = json["intensity"] as? Double {
                        let validEmotion = Self.validEmotions.contains(emotion) ? emotion : "neutral"
                        let clampedIntensity = min(max(intensity, 0.0), 1.0)
                        logger.info("[Emotion CLI] \(validEmotion) (\(String(format: "%.2f", clampedIntensity)))")
                        continuation.resume(returning: (validEmotion, clampedIntensity))
                    } else {
                        logger.info("Could not parse CLI output: \(output.prefix(100))")
                        continuation.resume(returning: ("neutral", 0.0))
                    }
                } catch {
                    logger.error("CLI process error: \(error.localizedDescription)")
                    continuation.resume(returning: ("neutral", 0.0))
                }
            }
        }
    }

    // MARK: - Find claude CLI

    nonisolated private static func findClaudeCLI() -> String? {
        let candidates = [
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
            NSHomeDirectory() + "/.claude/local/claude",
            NSHomeDirectory() + "/.nvm/versions/node/v24.13.1/bin/claude",
        ]

        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        // Try `which claude`
        let which = Process()
        let pipe = Pipe()
        which.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        which.arguments = ["claude"]
        which.standardOutput = pipe
        which.standardError = FileHandle.nullDevice
        try? which.run()
        which.waitUntilExit()
        let result = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let result, !result.isEmpty, FileManager.default.isExecutableFile(atPath: result) {
            return result
        }

        return nil
    }
}
