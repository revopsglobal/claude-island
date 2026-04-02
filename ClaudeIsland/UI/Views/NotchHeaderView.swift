//
//  NotchHeaderView.swift
//  ClaudeIsland
//
//  Header bar for the dynamic island
//

import Combine
import SwiftUI

struct ClaudeCrabIcon: View {
    let size: CGFloat
    let color: Color
    var animateLegs: Bool = false
    var emotion: CrabEmotion = .neutral

    @State private var legPhase: Int = 0
    @State private var bobPhase: Double = 0
    @State private var swayAngle: Double = 0
    @State private var trembleOffset: Double = 0

    // Timer for leg animation
    private let legTimer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()
    // Timer for bob/sway animation (smoother, 60fps-ish)
    private let motionTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    init(size: CGFloat = 16, color: Color = Color(red: 0.85, green: 0.47, blue: 0.34), animateLegs: Bool = false, emotion: CrabEmotion = .neutral) {
        self.size = size
        self.color = color
        self.animateLegs = animateLegs
        self.emotion = emotion
    }

    // MARK: - Emotion-driven motion parameters

    private var bobAmplitude: CGFloat {
        switch emotion {
        case .neutral: return 1.5
        case .happy: return 2.5
        case .sad: return 0.5
        case .sob: return 0
        }
    }

    private var bobDuration: Double {
        switch emotion {
        case .neutral: return 1.5
        case .happy: return 0.8
        case .sad: return 2.5
        case .sob: return 0
        }
    }

    private var swayAmplitudeDeg: Double {
        switch emotion {
        case .neutral: return 0.5
        case .happy: return 2.0
        case .sad: return 0.25
        case .sob: return 0.15
        }
    }

    private var trembleAmplitude: Double {
        emotion == .sob ? 1.0 : 0
    }

    /// Emotion-based color tint
    private var emotionColor: Color {
        switch emotion {
        case .neutral: return color
        case .happy: return Color(red: 0.95, green: 0.55, blue: 0.25)  // warmer orange
        case .sad: return Color(red: 0.65, green: 0.45, blue: 0.50)    // muted mauve
        case .sob: return Color(red: 0.55, green: 0.40, blue: 0.50)    // deeper mauve
        }
    }

    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 52.0
            let xOffset = (canvasSize.width - 66 * scale) / 2

            // Left antenna
            let leftAntenna = Path { p in
                p.addRect(CGRect(x: 0, y: 13, width: 6, height: 13))
            }.applying(CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: xOffset / scale, y: 0))
            context.fill(leftAntenna, with: .color(emotionColor))

            // Right antenna
            let rightAntenna = Path { p in
                p.addRect(CGRect(x: 60, y: 13, width: 6, height: 13))
            }.applying(CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: xOffset / scale, y: 0))
            context.fill(rightAntenna, with: .color(emotionColor))

            // Animated legs
            let baseLegPositions: [CGFloat] = [6, 18, 42, 54]
            let baseLegHeight: CGFloat = 13

            let legHeightOffsets: [[CGFloat]] = [
                [3, -3, 3, -3],
                [0, 0, 0, 0],
                [-3, 3, -3, 3],
                [0, 0, 0, 0],
            ]

            let currentHeightOffsets = animateLegs ? legHeightOffsets[legPhase % 4] : [CGFloat](repeating: 0, count: 4)

            for (index, xPos) in baseLegPositions.enumerated() {
                let heightOffset = currentHeightOffsets[index]
                let legHeight = baseLegHeight + heightOffset
                let leg = Path { p in
                    p.addRect(CGRect(x: xPos, y: 39, width: 6, height: legHeight))
                }.applying(CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: xOffset / scale, y: 0))
                context.fill(leg, with: .color(emotionColor))
            }

            // Main body
            let body = Path { p in
                p.addRect(CGRect(x: 6, y: 0, width: 54, height: 39))
            }.applying(CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: xOffset / scale, y: 0))
            context.fill(body, with: .color(emotionColor))

            // Eyes - emotion-driven
            let eyeColor: Color = .black
            let leftEyeY: CGFloat
            let rightEyeY: CGFloat
            let eyeHeight: CGFloat

            switch emotion {
            case .neutral:
                leftEyeY = 13; rightEyeY = 13; eyeHeight = 6.5
            case .happy:
                // Eyes slightly squinted (happy squint)
                leftEyeY = 15; rightEyeY = 15; eyeHeight = 4.0
            case .sad:
                // Eyes droopy (lower, taller)
                leftEyeY = 16; rightEyeY = 16; eyeHeight = 5.0
            case .sob:
                // Eyes wide (distressed)
                leftEyeY = 11; rightEyeY = 11; eyeHeight = 9.0
            }

            let leftEye = Path { p in
                p.addRect(CGRect(x: 12, y: leftEyeY, width: 6, height: eyeHeight))
            }.applying(CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: xOffset / scale, y: 0))
            context.fill(leftEye, with: .color(eyeColor))

            let rightEye = Path { p in
                p.addRect(CGRect(x: 48, y: rightEyeY, width: 6, height: eyeHeight))
            }.applying(CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: xOffset / scale, y: 0))
            context.fill(rightEye, with: .color(eyeColor))

            // Mouth - emotion-driven
            switch emotion {
            case .happy:
                // Simple smile: two pixels forming a curve
                let smile1 = Path { p in
                    p.addRect(CGRect(x: 22, y: 28, width: 4, height: 3))
                }.applying(CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: xOffset / scale, y: 0))
                let smile2 = Path { p in
                    p.addRect(CGRect(x: 26, y: 30, width: 14, height: 3))
                }.applying(CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: xOffset / scale, y: 0))
                let smile3 = Path { p in
                    p.addRect(CGRect(x: 40, y: 28, width: 4, height: 3))
                }.applying(CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: xOffset / scale, y: 0))
                context.fill(smile1, with: .color(eyeColor))
                context.fill(smile2, with: .color(eyeColor))
                context.fill(smile3, with: .color(eyeColor))
            case .sad, .sob:
                // Frown
                let frown1 = Path { p in
                    p.addRect(CGRect(x: 22, y: 32, width: 4, height: 3))
                }.applying(CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: xOffset / scale, y: 0))
                let frown2 = Path { p in
                    p.addRect(CGRect(x: 26, y: 30, width: 14, height: 3))
                }.applying(CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: xOffset / scale, y: 0))
                let frown3 = Path { p in
                    p.addRect(CGRect(x: 40, y: 32, width: 4, height: 3))
                }.applying(CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: xOffset / scale, y: 0))
                context.fill(frown1, with: .color(eyeColor))
                context.fill(frown2, with: .color(eyeColor))
                context.fill(frown3, with: .color(eyeColor))
            default:
                break  // neutral: no mouth
            }
        }
        .frame(width: size * (66.0 / 52.0), height: size)
        // Bob animation (vertical)
        .offset(y: bobAmplitude > 0 ? CGFloat(sin(bobPhase) * Double(bobAmplitude)) : 0)
        // Sway animation (rotation)
        .rotationEffect(.degrees(swayAngle * swayAmplitudeDeg))
        // Tremble animation (horizontal shake)
        .offset(x: CGFloat(trembleOffset * trembleAmplitude))
        .onReceive(legTimer) { _ in
            if animateLegs {
                legPhase = (legPhase + 1) % 4
            }
        }
        .onReceive(motionTimer) { _ in
            // Bob: smooth sine wave
            if bobDuration > 0 {
                bobPhase += (2.0 * .pi) / (bobDuration * 30.0)
            }
            // Sway: slower sine
            swayAngle = sin(bobPhase * 0.7)
            // Tremble: rapid random shake for sob
            if emotion == .sob {
                trembleOffset = Double.random(in: -1.0 ... 1.0)
            } else {
                trembleOffset = 0
            }
        }
        .animation(.easeInOut(duration: 0.3), value: emotion)
    }
}

// Pixel art permission indicator icon
struct PermissionIndicatorIcon: View {
    let size: CGFloat
    let color: Color

    init(size: CGFloat = 14, color: Color = Color(red: 0.11, green: 0.12, blue: 0.13)) {
        self.size = size
        self.color = color
    }

    // Visible pixel positions from the SVG (at 30x30 scale)
    private let pixels: [(CGFloat, CGFloat)] = [
        (7, 7), (7, 11),           // Left column
        (11, 3),                    // Top left
        (15, 3), (15, 19), (15, 27), // Center column
        (19, 3), (19, 15),          // Right of center
        (23, 7), (23, 11)           // Right column
    ]

    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 30.0
            let pixelSize: CGFloat = 4 * scale

            for (x, y) in pixels {
                let rect = CGRect(
                    x: x * scale - pixelSize / 2,
                    y: y * scale - pixelSize / 2,
                    width: pixelSize,
                    height: pixelSize
                )
                context.fill(Path(rect), with: .color(color))
            }
        }
        .frame(width: size, height: size)
    }
}

// Pixel art "ready for input" indicator icon (checkmark/done shape)
struct ReadyForInputIndicatorIcon: View {
    let size: CGFloat
    let color: Color

    init(size: CGFloat = 14, color: Color = TerminalColors.green) {
        self.size = size
        self.color = color
    }

    // Checkmark shape pixel positions (at 30x30 scale)
    private let pixels: [(CGFloat, CGFloat)] = [
        (5, 15),                    // Start of checkmark
        (9, 19),                    // Down stroke
        (13, 23),                   // Bottom of checkmark
        (17, 19),                   // Up stroke begins
        (21, 15),                   // Up stroke
        (25, 11),                   // Up stroke
        (29, 7)                     // End of checkmark
    ]

    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 30.0
            let pixelSize: CGFloat = 4 * scale

            for (x, y) in pixels {
                let rect = CGRect(
                    x: x * scale - pixelSize / 2,
                    y: y * scale - pixelSize / 2,
                    width: pixelSize,
                    height: pixelSize
                )
                context.fill(Path(rect), with: .color(color))
            }
        }
        .frame(width: size, height: size)
    }
}
