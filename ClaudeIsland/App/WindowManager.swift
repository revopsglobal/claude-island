//
//  WindowManager.swift
//  ClaudeIsland
//
//  Manages the notch window lifecycle
//

import AppKit
import os.log

/// Logger for window management
private let logger = Logger(subsystem: "com.claudeisland", category: "Window")

class WindowManager {
    private(set) var windowController: NotchWindowController?

    /// Set up or recreate the notch window
    func setupNotchWindow() -> NotchWindowController? {
        // Use ScreenSelector for screen selection (MainActor-isolated)
        let screen: NSScreen? = MainActor.assumeIsolated {
            let screenSelector = ScreenSelector.shared
            screenSelector.refreshScreens()
            return screenSelector.selectedScreen
        }

        guard let screen else {
            logger.warning("No screen found")
            return nil
        }

        if let existingController = windowController {
            existingController.window?.orderOut(nil)
            existingController.window?.close()
            windowController = nil
        }

        windowController = NotchWindowController(screen: screen)
        windowController?.showWindow(nil)

        return windowController
    }
}
