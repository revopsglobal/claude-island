//
//  TerminalVisibilityDetector.swift
//  ClaudeIsland
//
//  Detects if terminal windows are visible on current space
//

import AppKit
import CoreGraphics

struct TerminalVisibilityDetector {
    /// Check if any terminal window is visible on the current space
    /// Uses frontmost app check instead of CGWindowListCopyWindowInfo to avoid TCC prompts
    static func isTerminalVisibleOnCurrentSpace() -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let name = frontApp.localizedName else {
            return false
        }
        return TerminalAppRegistry.isTerminal(name)
    }

    /// Check if the frontmost (active) application is a terminal
    static func isTerminalFrontmost() -> Bool {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              let bundleId = frontmostApp.bundleIdentifier else {
            return false
        }

        return TerminalAppRegistry.isTerminalBundle(bundleId)
    }

    /// Check if a Claude session is currently focused (user is looking at it)
    /// - Parameter sessionPid: The PID of the Claude process
    /// - Returns: true if the session's terminal is frontmost and (for tmux) the pane is active
    static func isSessionFocused(sessionPid: Int) async -> Bool {
        // If no terminal is frontmost, session is definitely not focused
        guard isTerminalFrontmost() else {
            return false
        }

        let tree = ProcessTreeBuilder.shared.buildTree()
        let isInTmux = ProcessTreeBuilder.shared.isInTmux(pid: sessionPid, tree: tree)

        if isInTmux {
            // For tmux sessions, check if the session's pane is active
            return await TmuxTargetFinder.shared.isSessionPaneActive(claudePid: sessionPid)
        } else {
            // For non-tmux sessions, check if the session's terminal app is frontmost
            guard let sessionTerminalPid = ProcessTreeBuilder.shared.findTerminalPid(forProcess: sessionPid, tree: tree),
                  let frontmostApp = NSWorkspace.shared.frontmostApplication else {
                return false
            }

            return sessionTerminalPid == Int(frontmostApp.processIdentifier)
        }
    }
}
