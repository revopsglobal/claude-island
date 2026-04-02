//
//  CostTracker.swift
//  ClaudeIsland
//
//  Tracks API costs by parsing JSONL conversation files.
//  Reads token usage records and applies pricing to calculate spend.
//

import Foundation
import os.log

private let logger = Logger(subsystem: "com.claudeisland", category: "CostTracker")

/// Token usage from a single API call
struct TokenUsage: Sendable {
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let model: String
}

/// Cost summary for display
struct CostSummary: Equatable, Sendable {
    let sessionCost: Double
    let totalInputTokens: Int
    let totalOutputTokens: Int

    var formattedCost: String {
        if sessionCost < 0.01 {
            return String(format: "$%.4f", sessionCost)
        } else if sessionCost < 1.0 {
            return String(format: "$%.2f", sessionCost)
        } else {
            return String(format: "$%.2f", sessionCost)
        }
    }

    static let zero = CostSummary(sessionCost: 0, totalInputTokens: 0, totalOutputTokens: 0)
}

/// Tracks costs across all sessions
actor CostTracker {
    static let shared = CostTracker()

    /// Per-session cost data
    private var sessionCosts: [String: CostSummary] = [:]

    /// Last parsed offset per session file
    private var lastOffsets: [String: UInt64] = [:]

    private init() {}

    // MARK: - Pricing (per 1M tokens)

    /// Model pricing table (input, output, cache_creation, cache_read)
    private static let pricing: [String: (input: Double, output: Double, cacheCreate: Double, cacheRead: Double)] = [
        // Opus
        "claude-opus-4-20250514": (15.0, 75.0, 18.75, 1.50),
        "claude-opus-4-6-20250616": (15.0, 75.0, 18.75, 1.50),
        // Sonnet
        "claude-sonnet-4-20250514": (3.0, 15.0, 3.75, 0.30),
        "claude-sonnet-4-6-20250616": (3.0, 15.0, 3.75, 0.30),
        // Haiku
        "claude-haiku-4-5-20251001": (0.80, 4.0, 1.0, 0.08),
    ]

    /// Fallback pricing for unknown models
    private static let fallbackPricing = (input: 3.0, output: 15.0, cacheCreate: 3.75, cacheRead: 0.30)

    // MARK: - Public API

    /// Get cost summary for a specific session
    func costForSession(_ sessionId: String) -> CostSummary {
        sessionCosts[sessionId] ?? .zero
    }

    /// Get total cost across all active sessions
    func totalCost() -> CostSummary {
        let total = sessionCosts.values.reduce((0.0, 0, 0)) { acc, cost in
            (acc.0 + cost.sessionCost, acc.1 + cost.totalInputTokens, acc.2 + cost.totalOutputTokens)
        }
        return CostSummary(sessionCost: total.0, totalInputTokens: total.1, totalOutputTokens: total.2)
    }

    /// Update costs for a session by parsing its JSONL file
    func updateCosts(sessionId: String, cwd: String) {
        let projectDir = cwd.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ".", with: "-")
        let sessionFile = NSHomeDirectory() + "/.claude/projects/" + projectDir + "/" + sessionId + ".jsonl"

        guard FileManager.default.fileExists(atPath: sessionFile) else { return }

        guard let fileHandle = FileHandle(forReadingAtPath: sessionFile) else { return }
        defer { try? fileHandle.close() }

        let lastOffset = lastOffsets[sessionId] ?? 0
        fileHandle.seek(toFileOffset: lastOffset)

        let newData = fileHandle.readDataToEndOfFile()
        guard !newData.isEmpty else { return }

        let newOffset = lastOffset + UInt64(newData.count)
        lastOffsets[sessionId] = newOffset

        // Parse new lines for token usage
        guard let text = String(data: newData, encoding: .utf8) else { return }
        let lines = text.components(separatedBy: "\n")

        var additionalCost = 0.0
        var additionalInput = 0
        var additionalOutput = 0

        for line in lines {
            guard !line.isEmpty,
                  let lineData = line.data(using: String.Encoding.utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any]
            else { continue }

            // Look for assistant messages with usage data
            guard let role = json["role"] as? String, role == "assistant",
                  let usage = json["usage"] as? [String: Any]
            else { continue }

            let inputTokens = usage["input_tokens"] as? Int ?? 0
            let outputTokens = usage["output_tokens"] as? Int ?? 0

            // Cache tokens are nested under cache_creation_input_tokens / cache_read_input_tokens
            let cacheCreation = usage["cache_creation_input_tokens"] as? Int ?? 0
            let cacheRead = usage["cache_read_input_tokens"] as? Int ?? 0

            let model = json["model"] as? String ?? ""
            let prices = Self.pricing[model] ?? Self.fallbackPricing

            let inputCost = Double(inputTokens) / 1_000_000.0 * prices.input
            let outputCost = Double(outputTokens) / 1_000_000.0 * prices.output
            let cacheCost = Double(cacheCreation) / 1_000_000.0 * prices.cacheCreate
            let cacheReadCost = Double(cacheRead) / 1_000_000.0 * prices.cacheRead
            let cost = inputCost + outputCost + cacheCost + cacheReadCost

            additionalCost += cost
            additionalInput += inputTokens
            additionalOutput += outputTokens
        }

        if additionalCost > 0 {
            let existing = sessionCosts[sessionId] ?? .zero
            sessionCosts[sessionId] = CostSummary(
                sessionCost: existing.sessionCost + additionalCost,
                totalInputTokens: existing.totalInputTokens + additionalInput,
                totalOutputTokens: existing.totalOutputTokens + additionalOutput
            )
            logger.debug("Session \(sessionId.prefix(8)): +$\(String(format: "%.4f", additionalCost)) = $\(String(format: "%.4f", (self.sessionCosts[sessionId] ?? .zero).sessionCost))")
        }
    }

    /// Remove a session's cost data
    func removeSession(_ sessionId: String) {
        sessionCosts.removeValue(forKey: sessionId)
        lastOffsets.removeValue(forKey: sessionId)
    }
}
