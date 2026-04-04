//
//  ToolApprovalHandler.swift
//  ClaudeIsland
//
//  Handles Claude tool approval operations via tmux
//

import Foundation
import os.log

/// Handles tool approval and rejection for Claude instances
actor ToolApprovalHandler {
    static let shared = ToolApprovalHandler()

    /// Logger for tool approval (nonisolated static for cross-context access)
    nonisolated static let logger = Logger(subsystem: "com.claudeisland", category: "Approval")

    private init() {}

    /// Approve a tool once (sends '1' + Enter)
    func approveOnce(target: TmuxTarget) async -> Bool {
        await sendKeys(to: target, keys: "1", pressEnter: true)
    }

    /// Approve a tool always (sends '2' + Enter)
    func approveAlways(target: TmuxTarget) async -> Bool {
        await sendKeys(to: target, keys: "2", pressEnter: true)
    }

    /// Reject a tool with optional message
    func reject(target: TmuxTarget, message: String? = nil) async -> Bool {
        // First send 'n' + Enter to reject
        guard await sendKeys(to: target, keys: "n", pressEnter: true) else {
            return false
        }

        // If there's a message, send it after a brief delay
        if let message = message, !message.isEmpty {
            try? await Task.sleep(for: .milliseconds(100))
            return await sendKeys(to: target, keys: message, pressEnter: true)
        }

        return true
    }

    /// Send a message to a tmux target
    func sendMessage(_ message: String, to target: TmuxTarget) async -> Bool {
        await sendKeys(to: target, keys: message, pressEnter: true)
    }

    /// Select an option in an interactive picker by pressing Down arrow N times then Enter.
    /// optionIndex is 0-based (0 = first/default option, no Down keys needed).
    func selectPickerOption(index optionIndex: Int, target: TmuxTarget) async -> Bool {
        guard let tmuxPath = await TmuxPathFinder.shared.getTmuxPath() else { return false }

        let targetStr = target.targetString
        do {
            // Press Down arrow optionIndex times
            for _ in 0..<optionIndex {
                _ = try await ProcessExecutor.shared.run(tmuxPath, arguments: ["send-keys", "-t", targetStr, "Down"])
                try await Task.sleep(for: .milliseconds(50))
            }
            // Press Enter to confirm selection
            _ = try await ProcessExecutor.shared.run(tmuxPath, arguments: ["send-keys", "-t", targetStr, "Enter"])
            return true
        } catch {
            Self.logger.error("selectPickerOption error: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    /// Select "Type something" in the picker (option at given index), then type custom text.
    func selectPickerCustom(typeOptionIndex: Int, text: String, target: TmuxTarget) async -> Bool {
        // First select the "Type something" option
        guard await selectPickerOption(index: typeOptionIndex, target: target) else { return false }
        // Wait for text input to appear
        try? await Task.sleep(for: .milliseconds(300))
        // Type the text and press Enter
        return await sendKeys(to: target, keys: text, pressEnter: true)
    }

    // MARK: - Private Methods

    private func sendKeys(to target: TmuxTarget, keys: String, pressEnter: Bool) async -> Bool {
        guard let tmuxPath = await TmuxPathFinder.shared.getTmuxPath() else {
            return false
        }

        // tmux send-keys needs literal text and Enter as separate arguments
        // Use -l flag to send keys literally (prevents interpreting special chars)
        let targetStr = target.targetString
        let textArgs = ["send-keys", "-t", targetStr, "-l", keys]

        do {
            Self.logger.debug("Sending text to \(targetStr, privacy: .public)")
            _ = try await ProcessExecutor.shared.run(tmuxPath, arguments: textArgs)

            // Send Enter as a separate command if needed
            if pressEnter {
                Self.logger.debug("Sending Enter key")
                let enterArgs = ["send-keys", "-t", targetStr, "Enter"]
                _ = try await ProcessExecutor.shared.run(tmuxPath, arguments: enterArgs)
            }
            return true
        } catch {
            Self.logger.error("Error: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
