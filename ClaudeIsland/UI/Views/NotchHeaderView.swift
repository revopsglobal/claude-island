//
//  NotchHeaderView.swift
//  ClaudeIsland
//
//  Header bar for the dynamic island
//

import Combine
import SwiftUI

// MARK: - Pixel Art Turtle Icon

struct ClaudeTurtleIcon: View {
    let size: CGFloat
    var animateLegs: Bool = false
    var emotion: CrabEmotion = .neutral

    @State private var legPhase: Int = 0

    private let legTimer = Timer.publish(every: 0.18, on: .main, in: .common).autoconnect()

    init(size: CGFloat = 16, animateLegs: Bool = false, emotion: CrabEmotion = .neutral) {
        self.size = size
        self.animateLegs = animateLegs
        self.emotion = emotion
    }

    /// Emotion-based shell color
    private var shellColor: Color {
        switch emotion {
        case .neutral: return Color(red: 0.35, green: 0.60, blue: 0.35)  // forest green
        case .happy: return Color(red: 0.40, green: 0.70, blue: 0.30)    // bright green
        case .sad: return Color(red: 0.35, green: 0.45, blue: 0.40)      // muted teal
        case .sob: return Color(red: 0.30, green: 0.38, blue: 0.38)      // grey-green
        }
    }

    private var skinColor: Color {
        switch emotion {
        case .neutral: return Color(red: 0.55, green: 0.75, blue: 0.40)
        case .happy: return Color(red: 0.60, green: 0.82, blue: 0.38)
        case .sad: return Color(red: 0.48, green: 0.58, blue: 0.45)
        case .sob: return Color(red: 0.42, green: 0.50, blue: 0.42)
        }
    }

    private var shellDetailColor: Color {
        switch emotion {
        case .neutral: return Color(red: 0.28, green: 0.48, blue: 0.28)
        case .happy: return Color(red: 0.32, green: 0.55, blue: 0.22)
        case .sad: return Color(red: 0.28, green: 0.38, blue: 0.32)
        case .sob: return Color(red: 0.24, green: 0.32, blue: 0.30)
        }
    }

    var body: some View {
        Canvas { context, canvasSize in
            let s = size / 48.0  // design grid is 48 units
            let xOff = (canvasSize.width - 56 * s) / 2

            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, color: Color) {
                let r = CGRect(x: (x + xOff / s) * s, y: y * s, width: w * s, height: h * s)
                context.fill(Path(r), with: .color(color))
            }

            // -- LEGS (4 stubby legs) --
            let legOffsets: [[CGFloat]] = [
                [2, -2, 2, -2],   // phase 0
                [0, 0, 0, 0],     // phase 1
                [-2, 2, -2, 2],   // phase 2
                [0, 0, 0, 0],     // phase 3
            ]
            let currentLeg = animateLegs ? legOffsets[legPhase % 4] : [CGFloat](repeating: 0, count: 4)
            let legPositions: [(CGFloat, CGFloat)] = [(8, 36), (18, 36), (32, 36), (42, 36)]
            for (i, pos) in legPositions.enumerated() {
                let h: CGFloat = 10 + currentLeg[i]
                rect(pos.0, pos.1, 6, h, color: skinColor)
            }

            // -- BODY (under shell) --
            rect(6, 28, 44, 10, color: skinColor)

            // -- SHELL (dome shape) --
            // Shell base
            rect(8, 8, 40, 22, color: shellColor)
            // Shell top curve
            rect(12, 4, 32, 6, color: shellColor)
            // Shell details (hexagonal pattern hints)
            rect(14, 10, 10, 8, color: shellDetailColor)
            rect(26, 10, 10, 8, color: shellDetailColor)
            rect(20, 20, 10, 8, color: shellDetailColor)
            rect(34, 20, 8, 6, color: shellDetailColor)

            // -- HEAD --
            rect(46, 20, 10, 12, color: skinColor)

            // -- TAIL --
            rect(0, 30, 8, 4, color: skinColor)
            rect(-2, 32, 4, 3, color: skinColor)

            // -- EYES --
            let eyeColor: Color = .black
            switch emotion {
            case .neutral:
                rect(50, 22, 3, 3, color: eyeColor)  // simple dot
            case .happy:
                rect(50, 24, 3, 2, color: eyeColor)  // squinted
            case .sad:
                rect(50, 23, 3, 4, color: eyeColor)  // droopy
            case .sob:
                rect(49, 21, 4, 5, color: eyeColor)  // wide open
            }

            // -- MOUTH --
            switch emotion {
            case .happy:
                rect(51, 28, 4, 2, color: eyeColor)  // smile
            case .sad, .sob:
                rect(51, 30, 4, 2, color: eyeColor)  // frown
            default:
                break
            }
        }
        .frame(width: size * (56.0 / 48.0), height: size)
        .onReceive(legTimer) { _ in
            if animateLegs {
                legPhase = (legPhase + 1) % 4
            }
        }
        .animation(.easeInOut(duration: 0.3), value: emotion)
    }
}

// MARK: - Turtle Scene (grass island with animated turtle)

struct TurtleSceneView: View {
    var emotion: CrabEmotion = .neutral
    var isProcessing: Bool = false
    let width: CGFloat
    let height: CGFloat

    @State private var bobPhase: Double = 0
    @State private var swayAngle: Double = 0
    @State private var trembleX: Double = 0

    private let motionTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    private var bobAmplitude: CGFloat {
        switch emotion {
        case .neutral: return 1.2
        case .happy: return 2.0
        case .sad: return 0.4
        case .sob: return 0
        }
    }

    private var bobSpeed: Double {
        isProcessing ? 0.6 : 1.5
    }

    private var swayDeg: Double {
        switch emotion {
        case .neutral: return 0.5
        case .happy: return 1.5
        case .sad: return 0.2
        case .sob: return 0.1
        }
    }

    // Grass colors
    private let grassDark = Color(red: 0.18, green: 0.32, blue: 0.15)
    private let grassLight = Color(red: 0.25, green: 0.42, blue: 0.20)
    private let grassHighlight = Color(red: 0.30, green: 0.50, blue: 0.22)
    private let dirtColor = Color(red: 0.22, green: 0.18, blue: 0.12)

    var body: some View {
        ZStack(alignment: .bottom) {
            // Grass island
            Canvas { context, canvasSize in
                let w = canvasSize.width
                let h = canvasSize.height
                let grassTop = h * 0.55

                // Dirt/ground layer
                let dirt = Path { p in
                    p.addRect(CGRect(x: 0, y: grassTop + 4, width: w, height: h - grassTop - 4))
                }
                context.fill(dirt, with: .color(dirtColor))

                // Grass surface (slightly wavy)
                let grass = Path { p in
                    p.move(to: CGPoint(x: 0, y: grassTop + 4))
                    for x in stride(from: 0, through: w, by: 2) {
                        let y = grassTop + sin(x * 0.15) * 2
                        p.addLine(to: CGPoint(x: x, y: y))
                    }
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.closeSubpath()
                }
                context.fill(grass, with: .color(grassDark))

                // Grass highlights (pixel tufts)
                for i in stride(from: CGFloat(3), to: w, by: 8) {
                    let tuftY = grassTop + sin(i * 0.15) * 2 - 3
                    let tuft = Path { p in
                        p.addRect(CGRect(x: i, y: tuftY, width: 2, height: 4))
                    }
                    let c = Int(i) % 16 < 8 ? grassLight : grassHighlight
                    context.fill(tuft, with: .color(c))
                }
            }

            // Turtle (centered, animated)
            ClaudeTurtleIcon(size: min(height * 0.55, 22), animateLegs: isProcessing, emotion: emotion)
                .offset(
                    x: emotion == .sob ? CGFloat(trembleX * 1.0) : 0,
                    y: -(height * 0.35) + CGFloat(sin(bobPhase) * Double(bobAmplitude))
                )
                .rotationEffect(.degrees(swayAngle * swayDeg), anchor: .bottom)
        }
        .frame(width: width, height: height)
        .onReceive(motionTimer) { _ in
            bobPhase += (2.0 * .pi) / (bobSpeed * 30.0)
            swayAngle = sin(bobPhase * 0.7)
            trembleX = emotion == .sob ? Double.random(in: -1.0 ... 1.0) : 0
        }
    }
}

// MARK: - Pixel art permission indicator icon

struct PermissionIndicatorIcon: View {
    let size: CGFloat
    let color: Color

    init(size: CGFloat = 14, color: Color = Color(red: 0.11, green: 0.12, blue: 0.13)) {
        self.size = size
        self.color = color
    }

    private let pixels: [(CGFloat, CGFloat)] = [
        (7, 7), (7, 11),
        (11, 3),
        (15, 3), (15, 19), (15, 27),
        (19, 3), (19, 15),
        (23, 7), (23, 11)
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

// MARK: - Pixel art "ready for input" indicator icon

struct ReadyForInputIndicatorIcon: View {
    let size: CGFloat
    let color: Color

    init(size: CGFloat = 14, color: Color = TerminalColors.green) {
        self.size = size
        self.color = color
    }

    private let pixels: [(CGFloat, CGFloat)] = [
        (5, 15),
        (9, 19),
        (13, 23),
        (17, 19),
        (21, 15),
        (25, 11),
        (29, 7)
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
