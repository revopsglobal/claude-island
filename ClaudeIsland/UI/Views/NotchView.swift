//
//  NotchView.swift
//  ClaudeIsland
//
//  The main dynamic island SwiftUI view with accurate notch shape
//

import AppKit
import CoreGraphics
import SwiftUI

// Corner radius constants
private let cornerRadiusInsets = (
    opened: (top: CGFloat(19), bottom: CGFloat(24)),
    closed: (top: CGFloat(6), bottom: CGFloat(14))
)

struct NotchView: View {
    @ObservedObject var viewModel: NotchViewModel
    @StateObject private var sessionMonitor = ClaudeSessionMonitor()
    @StateObject private var activityCoordinator = NotchActivityCoordinator.shared
    @ObservedObject private var updateManager = UpdateManager.shared
    @ObservedObject private var emotionManager = EmotionManager.shared
    @State private var previousPendingIds: Set<String> = []
    @State private var previousWaitingForInputIds: Set<String> = []
    @State private var waitingForInputTimestamps: [String: Date] = [:]  // sessionId -> when it entered waitingForInput
    @State private var approvalTimestamps: [String: Date] = [:]  // sessionId -> when it entered waitingForApproval
    @State private var debouncedApprovalVisible: Bool = false  // only true after debounce threshold
    @State private var approvalDebounceTask: Task<Void, Never>? = nil
    @State private var isVisible: Bool = false
    @State private var isHovering: Bool = false
    @State private var isBouncing: Bool = false

    @Namespace private var activityNamespace

    /// Current emotion of the most active session (for the crab)
    private var primaryEmotion: CrabEmotion {
        // Use the first processing/approval session, or the first instance
        let activeSession = sessionMonitor.instances.first(where: {
            $0.phase == .processing || $0.phase.isWaitingForApproval
        }) ?? sessionMonitor.instances.first
        guard let session = activeSession else { return .neutral }
        let emo = emotionManager.sessionEmotions[session.sessionId] ?? .neutral
        return emo
    }

    /// Whether any Claude session is currently processing or compacting
    private var isAnyProcessing: Bool {
        sessionMonitor.instances.contains { $0.phase == .processing || $0.phase == .compacting }
    }

    /// Whether any Claude session has a pending permission request (raw, no debounce)
    private var hasRawPendingPermission: Bool {
        sessionMonitor.instances.contains { $0.phase.isWaitingForApproval }
    }

    /// Whether any Claude session has a pending permission request (debounced to filter auto-approvals)
    private var hasPendingPermission: Bool {
        debouncedApprovalVisible
    }

    /// Debounce threshold: only show approval UI after permission has been pending this long.
    /// Filters out auto-approved tools that flash PermissionRequest then immediately resolve.
    private static let approvalDebounceSeconds: TimeInterval = 2.5

    /// Whether any Claude session is waiting for user input (done/ready state) within the display window
    private var hasWaitingForInput: Bool {
        let now = Date()
        let displayDuration: TimeInterval = 30  // Show checkmark for 30 seconds

        return sessionMonitor.instances.contains { session in
            guard session.phase == .waitingForInput else { return false }
            // Only show if within the 30-second display window
            if let enteredAt = waitingForInputTimestamps[session.stableId] {
                return now.timeIntervalSince(enteredAt) < displayDuration
            }
            return false
        }
    }

    /// Top edge overlay color -- matches sky in both open and closed states when sessions active
    private var notchTopEdgeColor: Color {
        guard showClosedActivity else { return .black }
        switch primaryEmotion {
        case .happy: return Color(red: 0.95, green: 0.80, blue: 0.35)
        case .sad: return Color(red: 0.15, green: 0.18, blue: 0.30)
        case .sob: return Color(red: 0.06, green: 0.06, blue: 0.12)
        case .curious: return Color(red: 0.40, green: 0.65, blue: 0.90)
        case .excited: return Color(red: 1.00, green: 0.70, blue: 0.30)
        case .confused: return Color(red: 0.45, green: 0.35, blue: 0.60)
        case .neutral:
            return TimeOfDay.isNight() ? Color(red: 0.05, green: 0.05, blue: 0.15) : Color(red: 0.55, green: 0.78, blue: 0.95)
        }
    }

    /// Background color for the notch area -- matches scene sky only when closed bar is showing
    /// When opened, the chat panel must stay black so content is readable
    private var notchBackgroundColor: Color {
        guard viewModel.status != .opened, showClosedActivity else { return .black }
        switch primaryEmotion {
        case .happy: return Color(red: 0.95, green: 0.80, blue: 0.35)
        case .sad: return Color(red: 0.15, green: 0.18, blue: 0.30)
        case .sob: return Color(red: 0.06, green: 0.06, blue: 0.12)
        case .curious: return Color(red: 0.40, green: 0.65, blue: 0.90)
        case .excited: return Color(red: 1.00, green: 0.70, blue: 0.30)
        case .confused: return Color(red: 0.45, green: 0.35, blue: 0.60)
        case .neutral:
            return TimeOfDay.isNight() ? Color(red: 0.05, green: 0.05, blue: 0.15) : Color(red: 0.55, green: 0.78, blue: 0.95)
        }
    }

    // MARK: - Sizing

    private var closedNotchSize: CGSize {
        CGSize(
            width: viewModel.deviceNotchRect.width,
            height: viewModel.deviceNotchRect.height
        )
    }

    /// Extra width for expanding activities (like Dynamic Island)
    /// Symmetric expansion on both sides for the turtle's grass island
    /// Always expanded when there are sessions so the turtle has a home
    private var expansionWidth: CGFloat {
        let perSide: CGFloat = 85

        // Always show the scene when there are active sessions
        if !sessionMonitor.instances.isEmpty {
            return perSide * 2
        }

        return 0
    }

    private var notchSize: CGSize {
        switch viewModel.status {
        case .closed, .popping:
            return closedNotchSize
        case .opened:
            return viewModel.openedSize
        }
    }

    /// Width of the closed content (notch + any expansion)
    private var closedContentWidth: CGFloat {
        closedNotchSize.width + expansionWidth
    }

    // MARK: - Corner Radii

    private var topCornerRadius: CGFloat {
        viewModel.status == .opened
            ? cornerRadiusInsets.opened.top
            : cornerRadiusInsets.closed.top
    }

    private var bottomCornerRadius: CGFloat {
        viewModel.status == .opened
            ? cornerRadiusInsets.opened.bottom
            : cornerRadiusInsets.closed.bottom
    }

    private var currentNotchShape: NotchShape {
        NotchShape(
            topCornerRadius: topCornerRadius,
            bottomCornerRadius: bottomCornerRadius
        )
    }

    // Animation springs
    private let openAnimation = Animation.spring(response: 0.42, dampingFraction: 0.8, blendDuration: 0)
    private let closeAnimation = Animation.spring(response: 0.45, dampingFraction: 1.0, blendDuration: 0)

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Outer container does NOT receive hits - only the notch content does
            VStack(spacing: 0) {
                notchLayout
                    .frame(
                        maxWidth: viewModel.status == .opened ? notchSize.width : nil,
                        alignment: .top
                    )
                    .padding(
                        .horizontal,
                        viewModel.status == .opened
                            ? cornerRadiusInsets.opened.top
                            : cornerRadiusInsets.closed.bottom
                    )
                    .padding([.horizontal, .bottom], viewModel.status == .opened ? 12 : 0)
                    .background(notchBackgroundColor)
                    .clipShape(currentNotchShape)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(notchTopEdgeColor)
                            .frame(height: 1)
                            .padding(.horizontal, topCornerRadius)
                    }
                    .shadow(
                        color: (viewModel.status == .opened || isHovering) ? .black.opacity(0.7) : .clear,
                        radius: 6
                    )
                    .frame(
                        maxWidth: viewModel.status == .opened ? notchSize.width : nil,
                        maxHeight: viewModel.status == .opened ? notchSize.height : nil,
                        alignment: .top
                    )
                    .animation(viewModel.status == .opened ? openAnimation : closeAnimation, value: viewModel.status)
                    .animation(openAnimation, value: notchSize) // Animate container size changes between content types
                    .animation(.smooth, value: activityCoordinator.expandingActivity)
                    .animation(.smooth, value: hasPendingPermission)
                    .animation(.smooth, value: hasWaitingForInput)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isBouncing)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                            isHovering = hovering
                        }
                    }
                    .onTapGesture {
                        if viewModel.status != .opened {
                            viewModel.notchOpen(reason: .click)
                        }
                    }
            }
        }
        .opacity(isVisible ? 1 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .preferredColorScheme(.dark)
        .onAppear {
            sessionMonitor.startMonitoring()
            // On non-notched devices, keep visible so users have a target to interact with
            if !viewModel.hasPhysicalNotch {
                isVisible = true
            }
        }
        .onChange(of: viewModel.status) { oldStatus, newStatus in
            handleStatusChange(from: oldStatus, to: newStatus)
        }
        .onChange(of: sessionMonitor.pendingInstances) { _, sessions in
            handlePendingSessionsChange(sessions)
        }
        .onChange(of: sessionMonitor.instances) { _, instances in
            handleProcessingChange()
            handleWaitingForInputChange(instances)
            handleApprovalDebounce(instances)
            // Wire luminbeat detection to turtle scene
            TurtleSceneState.shared.hasLuminbeatSession = instances.contains {
                $0.projectName.lowercased().contains("luminbeat") ||
                $0.cwd.lowercased().contains("luminbeat")
            }
        }
    }

    // MARK: - Notch Layout

    private var isProcessing: Bool {
        activityCoordinator.expandingActivity.show && activityCoordinator.expandingActivity.type == .claude
    }

    /// Whether Sheldon should do his attention bounce (only for permission requests that need a decision)
    private var needsAttention: Bool {
        hasPendingPermission
    }

    /// Whether to show the turtle scene in closed state
    /// Always show when there are active sessions (turtle sleeps when idle)
    private var showClosedActivity: Bool {
        !sessionMonitor.instances.isEmpty
    }

    @ViewBuilder
    private var notchLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row - always present, contains crab and spinner that persist across states
            headerRow
                .frame(height: max(24, closedNotchSize.height))

            // Main content only when opened
            if viewModel.status == .opened {
                contentView
                    .frame(width: notchSize.width - 24) // Fixed width to prevent reflow
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.8, anchor: .top)
                                .combined(with: .opacity)
                                .animation(.smooth(duration: 0.35)),
                            removal: .opacity.animation(.easeOut(duration: 0.15))
                        )
                    )
            }
        }
    }

    // MARK: - Header Row (persists across states)

    /// Full width of the closed expanded area (both sides + notch)
    private var closedExpandedWidth: CGFloat {
        closedNotchSize.width + expansionWidth
    }

    @ViewBuilder
    private var headerRow: some View {
        if viewModel.status == .opened && showClosedActivity {
            // Opened state: turtle scene extends into padding so grass fills bezier corners
            // Extra 4pt overshoot ensures no sub-pixel black gaps at bezier edges
            let openedPad = cornerRadiusInsets.opened.top + 12 + 4
            ZStack {
                TurtleSceneView(
                    emotion: primaryEmotion,
                    isProcessing: isProcessing,
                    needsAttention: needsAttention,
                    width: notchSize.width + openedPad * 2,
                    height: closedNotchSize.height
                )
                .padding(.horizontal, -openedPad)
                .matchedGeometryEffect(id: "turtle", in: activityNamespace, isSource: true)

                // Menu button overlay on top right
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewModel.toggleMenu()
                        }
                    } label: {
                        Image(systemName: viewModel.contentType == .menu ? "xmark" : "line.3.horizontal")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.trailing, 8)
            }
            .frame(height: closedNotchSize.height)
        } else if viewModel.status == .opened {
            // Opened without sessions: normal header
            HStack(spacing: 0) {
                openedHeaderContent
            }
            .frame(height: closedNotchSize.height)
        } else if showClosedActivity {
            // Closed with activity: turtle scene extends into padding so grass fills bezier corners
            let closedPad = cornerRadiusInsets.closed.bottom + 4
            ZStack {
                TurtleSceneView(
                    emotion: primaryEmotion,
                    isProcessing: isProcessing,
                    needsAttention: needsAttention,
                    width: closedExpandedWidth + closedPad * 2,
                    height: closedNotchSize.height
                )
                .padding(.horizontal, -closedPad)
                .matchedGeometryEffect(id: "turtle", in: activityNamespace, isSource: true)

                // Overlay: permission indicator (left) or checkmark (right)
                // Processing is indicated by the flower in the scene (turtle eats it)
                HStack {
                    if hasPendingPermission {
                        PermissionIndicatorIcon(size: 14, color: Color(red: 0.85, green: 0.47, blue: 0.34))
                            .matchedGeometryEffect(id: "status-indicator", in: activityNamespace, isSource: true)
                            .padding(.leading, 6)
                    }

                    Spacer()

                    if hasPendingPermission {
                        ProcessingSpinner()
                            .matchedGeometryEffect(id: "spinner", in: activityNamespace, isSource: true)
                            .padding(.trailing, 6)
                    } else if hasWaitingForInput {
                        ReadyForInputIndicatorIcon(size: 14, color: TerminalColors.green)
                            .matchedGeometryEffect(id: "spinner", in: activityNamespace, isSource: true)
                            .padding(.trailing, 6)
                    }
                }
            }
            .frame(width: closedExpandedWidth, height: closedNotchSize.height)
        } else {
            // Closed without activity: empty
            HStack(spacing: 0) {
                Rectangle()
                    .fill(.clear)
                    .frame(width: closedNotchSize.width - 20)
            }
            .frame(height: closedNotchSize.height)
        }
    }

    private var sideWidth: CGFloat {
        max(0, closedNotchSize.height - 12) + 10
    }

    // MARK: - Opened Header Content

    @ViewBuilder
    private var openedHeaderContent: some View {
        HStack(spacing: 12) {
            // Show static turtle only if not showing activity in headerRow
            if !showClosedActivity {
                ClaudeTurtleIcon(size: 14, emotion: primaryEmotion)
                    .matchedGeometryEffect(id: "turtle", in: activityNamespace, isSource: !showClosedActivity)
                    .padding(.leading, 8)
            }

            Spacer()

            // Menu toggle
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.toggleMenu()
                    if viewModel.contentType == .menu {
                        updateManager.markUpdateSeen()
                    }
                }
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: viewModel.contentType == .menu ? "xmark" : "line.3.horizontal")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())

                    // Green dot for unseen update
                    if updateManager.hasUnseenUpdate && viewModel.contentType != .menu {
                        Circle()
                            .fill(TerminalColors.green)
                            .frame(width: 6, height: 6)
                            .offset(x: -2, y: 2)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Content View (Opened State)

    @ViewBuilder
    private var contentView: some View {
        Group {
            switch viewModel.contentType {
            case .instances:
                ClaudeInstancesView(
                    sessionMonitor: sessionMonitor,
                    viewModel: viewModel
                )
            case .menu:
                NotchMenuView(viewModel: viewModel)
            case .chat(let session):
                ChatView(
                    sessionId: session.sessionId,
                    initialSession: session,
                    sessionMonitor: sessionMonitor,
                    viewModel: viewModel
                )
                // Force a fresh ChatView when switching sessions — otherwise
                // @State (history, session, scroll position) leaks from the
                // previous session and the view shows the wrong conversation.
                // Keyed on sessionId only (not the whole SessionState) so
                // per-event updates still reuse the view.
                .id(session.sessionId)
            }
        }
        .frame(width: notchSize.width - 24) // Fixed width to prevent text reflow
    }

    // MARK: - Event Handlers

    private func handleProcessingChange() {
        if isAnyProcessing || hasPendingPermission {
            activityCoordinator.showActivity(type: .claude)
        } else {
            activityCoordinator.hideActivity()
        }

        // Always visible when sessions exist (turtle lives here)
        if !sessionMonitor.instances.isEmpty {
            isVisible = true
        } else if viewModel.status == .closed && viewModel.hasPhysicalNotch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.sessionMonitor.instances.isEmpty && self.viewModel.status == .closed {
                    self.isVisible = false
                }
            }
        }
    }

    private func handleStatusChange(from oldStatus: NotchStatus, to newStatus: NotchStatus) {
        switch newStatus {
        case .opened, .popping:
            isVisible = true
            // Clear waiting-for-input timestamps only when manually opened (user acknowledged)
            if viewModel.openReason == .click || viewModel.openReason == .hover {
                waitingForInputTimestamps.removeAll()
            }
        case .closed:
            guard viewModel.hasPhysicalNotch else { return }
            // Only hide when truly no sessions left
            if sessionMonitor.instances.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    if self.viewModel.status == .closed && self.sessionMonitor.instances.isEmpty {
                        self.isVisible = false
                    }
                }
            }
        }
    }

    private func handlePendingSessionsChange(_ sessions: [SessionState]) {
        let currentIds = Set(sessions.map { $0.stableId })
        let newPendingIds = currentIds.subtracting(previousPendingIds)

        if !newPendingIds.isEmpty &&
           viewModel.status == .closed &&
           !TerminalVisibilityDetector.isTerminalVisibleOnCurrentSpace() {
            viewModel.notchOpen(reason: .notification)
        }

        previousPendingIds = currentIds
    }

    private func handleWaitingForInputChange(_ instances: [SessionState]) {
        // Get sessions that are now waiting for input
        let waitingForInputSessions = instances.filter { $0.phase == .waitingForInput }
        let currentIds = Set(waitingForInputSessions.map { $0.stableId })
        let newWaitingIds = currentIds.subtracting(previousWaitingForInputIds)

        // Track timestamps for newly waiting sessions
        let now = Date()
        for session in waitingForInputSessions where newWaitingIds.contains(session.stableId) {
            waitingForInputTimestamps[session.stableId] = now
        }

        // Clean up timestamps for sessions no longer waiting
        let staleIds = Set(waitingForInputTimestamps.keys).subtracting(currentIds)
        for staleId in staleIds {
            waitingForInputTimestamps.removeValue(forKey: staleId)
        }

        // Bounce the notch when a session newly enters waitingForInput state
        if !newWaitingIds.isEmpty {
            // Get the sessions that just entered waitingForInput
            let newlyWaitingSessions = waitingForInputSessions.filter { newWaitingIds.contains($0.stableId) }

            // Play notification sound if the session is not actively focused
            if let soundName = AppSettings.notificationSound.soundName {
                // Check if we should play sound (async check for tmux pane focus)
                Task {
                    let shouldPlaySound = await shouldPlayNotificationSound(for: newlyWaitingSessions)
                    if shouldPlaySound {
                        await MainActor.run {
                            NSSound(named: soundName)?.play()
                        }
                    }
                }
            }

            // Trigger bounce animation to get user's attention
            DispatchQueue.main.async {
                isBouncing = true
                // Bounce back after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isBouncing = false
                }
            }

            // Schedule hiding the checkmark after 30 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [self] in
                // Trigger a UI update to re-evaluate hasWaitingForInput
                handleProcessingChange()
            }
        }

        previousWaitingForInputIds = currentIds
    }

    /// Debounce approval UI to filter out auto-approved tools.
    /// Only shows the approval bar after a permission has been pending for the debounce threshold.
    private func handleApprovalDebounce(_ instances: [SessionState]) {
        let pendingSessions = instances.filter { $0.phase.isWaitingForApproval }

        if pendingSessions.isEmpty {
            // No pending permissions: immediately hide and cancel any timer
            approvalDebounceTask?.cancel()
            approvalDebounceTask = nil
            approvalTimestamps.removeAll()
            if debouncedApprovalVisible {
                withAnimation(.easeOut(duration: 0.2)) {
                    debouncedApprovalVisible = false
                }
            }
            return
        }

        // Track when each session first entered approval state
        let now = Date()
        for session in pendingSessions {
            if approvalTimestamps[session.stableId] == nil {
                approvalTimestamps[session.stableId] = now
            }
        }

        // Clean up stale entries
        let currentIds = Set(pendingSessions.map { $0.stableId })
        for key in approvalTimestamps.keys where !currentIds.contains(key) {
            approvalTimestamps.removeValue(forKey: key)
        }

        // Check if any session has been pending long enough
        let oldestPending = approvalTimestamps.values.min() ?? now
        let elapsed = now.timeIntervalSince(oldestPending)

        if elapsed >= Self.approvalDebounceSeconds {
            // Already past threshold, show immediately
            if !debouncedApprovalVisible {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    debouncedApprovalVisible = true
                }
                autoOpenForInteractiveTool(pendingSessions)
            }
        } else if approvalDebounceTask == nil {
            // Schedule showing after remaining time
            let remaining = Self.approvalDebounceSeconds - elapsed
            approvalDebounceTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(remaining))
                guard !Task.isCancelled else { return }
                // Re-check that permission is still pending
                let stillPending = sessionMonitor.instances.filter { $0.phase.isWaitingForApproval }
                if !stillPending.isEmpty {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        debouncedApprovalVisible = true
                    }
                    autoOpenForInteractiveTool(stillPending)
                }
                approvalDebounceTask = nil
            }
        }
    }

    /// Auto-open the notch and navigate to the chat view for interactive tools (e.g. AskUserQuestion).
    /// Without this, the user only sees a small permission icon in the closed bar and has to manually
    /// click to open the notch, then find the right session to see the interactive prompt.
    private func autoOpenForInteractiveTool(_ pendingSessions: [SessionState]) {
        guard viewModel.status == .closed else { return }
        guard let interactiveSession = pendingSessions.first(where: { $0.pendingToolName == "AskUserQuestion" }) else { return }

        viewModel.notchOpen(reason: .notification)
        // Small delay to let the open animation start before navigating to chat
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            viewModel.showChat(for: interactiveSession)
        }
    }

    /// Determine if notification sound should play for the given sessions
    /// Returns true if ANY session is not actively focused
    private func shouldPlayNotificationSound(for sessions: [SessionState]) async -> Bool {
        for session in sessions {
            guard let pid = session.pid else {
                // No PID means we can't check focus, assume not focused
                return true
            }

            let isFocused = await TerminalVisibilityDetector.isSessionFocused(sessionPid: pid)
            if !isFocused {
                return true
            }
        }

        return false
    }
}
