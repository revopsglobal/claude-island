//
//  NotchHeaderView.swift
//  ClaudeIsland
//
//  Header bar for the dynamic island
//

import Combine
import SwiftUI

// MARK: - Turtle Hat Types

enum TurtleHat {
    case none
    case nightcap     // midnight coding
    case santa        // December
    case party        // birthday / milestones
    case tophat       // new year
}

// MARK: - Pixel Art Turtle Icon

struct ClaudeTurtleIcon: View {
    let size: CGFloat
    var animateLegs: Bool = false
    var emotion: CrabEmotion = .neutral
    var isBlinking: Bool = false
    var headExtension: CGFloat = 0  // 0 = normal, negative = retracted, positive = extended
    var isSleeping: Bool = false
    var mouthOpen: Bool = false
    var lookingUp: Bool = false
    var hiddenInShell: Bool = false   // error streak: only eyes peek out
    var hatType: TurtleHat = .none
    var shellProgress: CGFloat = 0    // 0-1 fill for task progress

    @State private var legPhase: Int = 0

    private let legTimer = Timer.publish(every: 0.18, on: .main, in: .common).autoconnect()

    init(size: CGFloat = 16, animateLegs: Bool = false, emotion: CrabEmotion = .neutral,
         isBlinking: Bool = false, headExtension: CGFloat = 0, isSleeping: Bool = false,
         mouthOpen: Bool = false, lookingUp: Bool = false,
         hiddenInShell: Bool = false, hatType: TurtleHat = .none, shellProgress: CGFloat = 0) {
        self.size = size
        self.animateLegs = animateLegs
        self.emotion = emotion
        self.isBlinking = isBlinking
        self.headExtension = headExtension
        self.isSleeping = isSleeping
        self.mouthOpen = mouthOpen
        self.lookingUp = lookingUp
        self.hiddenInShell = hiddenInShell
        self.hatType = hatType
        self.shellProgress = shellProgress
    }

    // Emotion-based shell color (bright enough to pop against dark grass)
    private var shellColor: Color {
        switch emotion {
        case .neutral: return Color(red: 0.45, green: 0.72, blue: 0.40)
        case .happy: return Color(red: 0.50, green: 0.82, blue: 0.35)
        case .sad: return Color(red: 0.40, green: 0.52, blue: 0.48)
        case .sob: return Color(red: 0.35, green: 0.45, blue: 0.45)
        }
    }

    private var skinColor: Color {
        switch emotion {
        case .neutral: return Color(red: 0.65, green: 0.85, blue: 0.45)
        case .happy: return Color(red: 0.72, green: 0.92, blue: 0.42)
        case .sad: return Color(red: 0.55, green: 0.65, blue: 0.52)
        case .sob: return Color(red: 0.48, green: 0.58, blue: 0.48)
        }
    }

    private var shellDetailColor: Color {
        switch emotion {
        case .neutral: return Color(red: 0.35, green: 0.58, blue: 0.32)
        case .happy: return Color(red: 0.40, green: 0.65, blue: 0.28)
        case .sad: return Color(red: 0.32, green: 0.42, blue: 0.38)
        case .sob: return Color(red: 0.28, green: 0.38, blue: 0.35)
        }
    }

    private var hatPadding: CGFloat {
        hatType == .none ? 0 : 12
    }

    var body: some View {
        Canvas { context, canvasSize in
            let s = size / 48.0
            let xOff = (canvasSize.width - 56 * s) / 2
            let headX = headExtension
            let yPad = hatPadding * s  // shift everything down to make room for hat

            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, color: Color) {
                let r = CGRect(x: (x + xOff / s) * s, y: y * s + yPad, width: w * s, height: h * s)
                context.fill(Path(r), with: .color(color))
            }

            if hiddenInShell {
                // -- HIDDEN IN SHELL (error streak) --
                // Just shell sitting on ground, eyes peeking from front
                rect(8, 14, 40, 22, color: shellColor)
                rect(12, 10, 32, 6, color: shellColor)
                rect(14, 16, 10, 8, color: shellDetailColor)
                rect(26, 16, 10, 8, color: shellDetailColor)
                rect(20, 26, 10, 6, color: shellDetailColor)
                // Tiny eyes peeking out front
                let eyeColor: Color = .black
                rect(46, 28, 3, 3, color: skinColor)  // skin around eyes
                rect(47, 29, 2, 2, color: eyeColor)   // eyes
            } else {
                // -- LEGS --
                let legOffsets: [[CGFloat]] = [
                    [2, -2, 2, -2],
                    [0, 0, 0, 0],
                    [-2, 2, -2, 2],
                    [0, 0, 0, 0],
                ]
                let currentLeg = animateLegs ? legOffsets[legPhase % 4] : [CGFloat](repeating: 0, count: 4)
                let legPositions: [(CGFloat, CGFloat)] = [(8, 36), (18, 36), (32, 36), (42, 36)]
                for (i, pos) in legPositions.enumerated() {
                    let lh: CGFloat = 10 + currentLeg[i]
                    rect(pos.0, pos.1, 6, lh, color: skinColor)
                }

                // -- BODY --
                rect(6, 28, 44, 10, color: skinColor)

                // -- SHELL --
                rect(8, 8, 40, 22, color: shellColor)
                rect(12, 4, 32, 6, color: shellColor)
                rect(14, 10, 10, 8, color: shellDetailColor)
                rect(26, 10, 10, 8, color: shellDetailColor)
                rect(20, 20, 10, 8, color: shellDetailColor)
                rect(34, 20, 8, 6, color: shellDetailColor)

                // -- SHELL PROGRESS (fills from left) --
                if shellProgress > 0 {
                    let pw = 38 * shellProgress
                    let progressColor = Color(red: 0.3, green: 0.75, blue: 0.4).opacity(0.4)
                    rect(9, 9, pw, 20, color: progressColor)
                }

                // -- HEAD (with extension) --
                rect(46 + headX, 20, 10, 12, color: skinColor)

                // -- TAIL --
                rect(0, 30, 8, 4, color: skinColor)
                rect(-2, 32, 4, 3, color: skinColor)

                // -- EYES --
                let eyeColor: Color = .black
                if isSleeping {
                    rect(50 + headX, 24, 4, 1.5, color: eyeColor)
                } else if isBlinking {
                    rect(50 + headX, 24, 3, 1, color: eyeColor)
                } else if lookingUp {
                    rect(50 + headX, 19, 3, 3, color: eyeColor)
                } else {
                    switch emotion {
                    case .neutral:
                        rect(50 + headX, 22, 3, 3, color: eyeColor)
                    case .happy:
                        rect(50 + headX, 24, 3, 2, color: eyeColor)
                    case .sad:
                        rect(50 + headX, 23, 3, 4, color: eyeColor)
                    case .sob:
                        rect(49 + headX, 21, 4, 5, color: eyeColor)
                    }
                }

                // -- MOUTH --
                if mouthOpen {
                    rect(51 + headX, 27, 5, 5, color: eyeColor)
                    rect(52 + headX, 28, 3, 3, color: Color(red: 0.5, green: 0.15, blue: 0.1))
                } else if !isSleeping {
                    switch emotion {
                    case .happy:
                        rect(51 + headX, 28, 4, 2, color: eyeColor)
                    case .sad, .sob:
                        rect(51 + headX, 30, 4, 2, color: eyeColor)
                    default:
                        break
                    }
                }

                // -- HAT --
                switch hatType {
                case .nightcap:
                    // Droopy cap sitting on top of head, tip flops slightly right
                    let capColor = Color(red: 0.3, green: 0.3, blue: 0.7)
                    rect(46 + headX, 16, 12, 5, color: capColor)   // base band on head
                    rect(48 + headX, 12, 8, 5, color: capColor)    // middle section
                    rect(50 + headX, 8, 6, 5, color: capColor)     // upper section
                    rect(53 + headX, 5, 5, 4, color: capColor)     // tip drooping forward
                    // Pompom at tip
                    rect(55 + headX, 3, 4, 4, color: .white)
                case .santa:
                    // Red santa hat on head
                    let santaRed = Color(red: 0.85, green: 0.15, blue: 0.15)
                    rect(44 + headX, 18, 14, 3, color: .white)  // brim on head
                    rect(45 + headX, 14, 12, 5, color: santaRed)
                    rect(47 + headX, 10, 9, 5, color: santaRed)
                    rect(49 + headX, 7, 6, 4, color: santaRed)
                    rect(52 + headX, 5, 4, 4, color: .white)    // pompom
                case .party:
                    // Cone hat on head
                    rect(45 + headX, 17, 12, 4, color: Color(red: 0.9, green: 0.4, blue: 0.7))
                    rect(47 + headX, 13, 8, 5, color: Color(red: 0.4, green: 0.7, blue: 0.9))
                    rect(49 + headX, 10, 5, 4, color: Color(red: 0.9, green: 0.8, blue: 0.2))
                    rect(50 + headX, 8, 4, 3, color: Color(red: 0.9, green: 0.4, blue: 0.3))
                case .tophat:
                    // Top hat on head
                    let hatBlack = Color(red: 0.15, green: 0.15, blue: 0.15)
                    rect(44 + headX, 18, 14, 3, color: hatBlack)  // brim
                    rect(46 + headX, 10, 10, 9, color: hatBlack)  // crown
                    rect(46 + headX, 15, 10, 2, color: Color(red: 0.6, green: 0.5, blue: 0.2)) // band
                case .none:
                    break
                }

                // -- SLEEP Zs --
                if isSleeping {
                    let zColor = Color.white.opacity(0.5)
                    rect(54 + headX, 14, 4, 1, color: zColor)
                    rect(55 + headX, 15, 2, 1, color: zColor)
                    rect(54 + headX, 16, 4, 1, color: zColor)
                    rect(58 + headX, 8, 5, 1.5, color: zColor)
                    rect(60 + headX, 9.5, 3, 1.5, color: zColor)
                    rect(58 + headX, 11, 5, 1.5, color: zColor)
                }
            }
        }
        .frame(width: size * (56.0 / 48.0), height: size + hatPadding * (size / 48.0))
        .onReceive(legTimer) { _ in
            if animateLegs {
                legPhase = (legPhase + 1) % 4
            }
        }
        .animation(.easeInOut(duration: 0.3), value: emotion)
    }
}

// MARK: - Turtle Scene State (persists across view recreation)

@MainActor
class TurtleSceneState: ObservableObject {
    // Motion
    @Published var bobPhase: Double = 0
    @Published var swayAngle: Double = 0
    @Published var trembleX: Double = 0

    // Walking
    @Published var walkX: CGFloat = -0.35
    @Published var walkDirection: CGFloat = 1
    @Published var isWalking: Bool = true
    @Published var walkPauseUntil: Date = .distantPast
    @Published var facingRight: Bool = true

    // Flower
    @Published var flowerX: CGFloat = 0.35
    @Published var flowerVisible: Bool = false
    @Published var flowerScale: CGFloat = 0
    @Published var flowerEaten: Bool = false
    @Published var petalCount: Int = 5
    @Published var petalRegrowing: Bool = false
    @Published var isEating: Bool = false
    @Published var mouthOpen: Bool = false

    // Nature
    @Published var butterflies: [(x: CGFloat, y: CGFloat, phase: Double, speed: Double)] = []
    @Published var hearts: [(x: CGFloat, y: CGFloat, opacity: Double, age: Double)] = []
    @Published var raindrops: [(x: CGFloat, y: CGFloat)] = []
    @Published var seasonalParticles: [(x: CGFloat, y: CGFloat, drift: CGFloat, speed: CGFloat)] = []
    @Published var confetti: [(x: CGFloat, y: CGFloat, color: Int, speed: CGFloat)] = []
    @Published var timePhase: Double = 0

    // Creatures
    @Published var birdX: CGFloat = -0.2
    @Published var birdVisible: Bool = false
    @Published var birdLanded: Bool = false
    @Published var wormVisible: Bool = false
    @Published var wormY: CGFloat = 0

    // Interaction
    @Published var spinAngle: Double = 0
    @Published var promptCount: Int = 0
    @Published var errorStreak: Int = 0
    @Published var hiddenInShell: Bool = false

    // Life
    @Published var isBlinking: Bool = false
    @Published var headExtension: CGFloat = 0
    @Published var isSleeping: Bool = false
    @Published var breathScale: CGFloat = 1.0
    @Published var lastActivityTime: Date = Date()
    @Published var tailWag: CGFloat = 0
    @Published var lookingUp: Bool = false

    // New features
    @Published var shootingStars: [(x: CGFloat, y: CGFloat, dx: CGFloat, life: Double)] = []
    @Published var showRainbow: Bool = false
    @Published var rainbowOpacity: Double = 0
    @Published var campfireFlicker: Double = 0
    @Published var mushrooms: [(x: CGFloat, size: CGFloat)] = []
    @Published var footprints: [(x: CGFloat, opacity: Double)] = []
    @Published var snailX: CGFloat = -0.5
    @Published var snailVisible: Bool = false
    @Published var sessionStartTime: Date = Date()
    @Published var musicNotes: [(x: CGFloat, y: CGFloat, opacity: Double)] = []
    @Published var cursorNearNotch: Bool = false
    @Published var cursorX: CGFloat = 0  // normalized cursor X position relative to scene
    @Published var hasLuminbeatSession: Bool = false  // any active session in luminbeat repo

    // Puddles (after rain)
    @Published var puddles: [(x: CGFloat, opacity: Double)] = []

    static let shared = TurtleSceneState()
}

// MARK: - Turtle Scene (grass island with animated turtle)

struct TurtleSceneView: View {
    var emotion: CrabEmotion = .neutral
    var isProcessing: Bool = false
    let width: CGFloat
    let height: CGFloat

    @ObservedObject private var s = TurtleSceneState.shared

    // Timers
    private let motionTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()
    private let lifeTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    // Sleep after 3 minutes of idle
    private let sleepThreshold: TimeInterval = 180

    private var bobAmplitude: CGFloat {
        if s.isSleeping { return 0.3 }
        switch emotion {
        case .neutral: return 1.2
        case .happy: return 2.0
        case .sad: return 0.4
        case .sob: return 0
        }
    }

    private var bobSpeed: Double {
        if s.isSleeping { return 3.0 }
        return isProcessing ? 0.6 : 1.5
    }

    private var swayDeg: Double {
        if s.isSleeping { return 0.1 }
        switch emotion {
        case .neutral: return 0.5
        case .happy: return 1.5
        case .sad: return 0.2
        case .sob: return 0.1
        }
    }

    // Day/night cycle based on actual time
    private var daylight: CGFloat {
        let hour = Calendar.current.component(.hour, from: Date())
        // 0.0 = full night, 1.0 = full day
        switch hour {
        case 6 ..< 8: return CGFloat(hour - 6) / 2.0 * 0.7 + 0.3   // dawn
        case 8 ..< 17: return 1.0                                     // day
        case 17 ..< 20: return 1.0 - CGFloat(hour - 17) / 3.0 * 0.6 // dusk
        case 20 ..< 22: return 0.4 - CGFloat(hour - 20) / 2.0 * 0.2 // evening
        default: return 0.2                                            // night
        }
    }

    private var isNighttime: Bool { daylight < 0.4 }



    // Grass colors adjusted for time of day
    private var grassDark: Color {
        Color(red: 0.18 * daylight, green: 0.32 * daylight, blue: 0.15 * daylight)
    }
    private var grassLight: Color {
        Color(red: 0.25 * daylight, green: 0.42 * daylight, blue: 0.20 * daylight)
    }
    private var grassHighlight: Color {
        Color(red: 0.30 * daylight, green: 0.50 * daylight, blue: 0.22 * daylight)
    }
    private var dirtColor: Color {
        Color(red: 0.22 * daylight, green: 0.18 * daylight, blue: 0.12 * daylight)
    }
    private var skyColor: Color {
        isNighttime ? Color(red: 0.02, green: 0.02, blue: 0.08) : .clear
    }

    // Season based on month
    private enum Season { case spring, summer, autumn, winter }
    private var currentSeason: Season {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3 ... 5: return .spring
        case 6 ... 8: return .summer
        case 9 ... 11: return .autumn
        default: return .winter
        }
    }

    // Hat based on date/time
    private var currentHat: TurtleHat {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: Date())
        let month = cal.component(.month, from: Date())
        let day = cal.component(.day, from: Date())

        // Midnight coding (11pm - 4am)
        if hour >= 23 || hour < 4 { return .nightcap }
        // December = santa
        if month == 12 { return .santa }
        // Jan 1 = top hat
        if month == 1 && day == 1 { return .tophat }
        // Confetti active = party hat
        if !s.confetti.isEmpty { return .party }
        return .none
    }

    // MARK: - Sub-views (broken out to help the type checker)

    @ViewBuilder
    private var grassCanvas: some View {
        Canvas { context, canvasSize in
                let w = canvasSize.width
                let h = canvasSize.height
                let grassTop = h * 0.55

                // Dirt layer
                let dirt = Path { p in
                    p.addRect(CGRect(x: 0, y: grassTop + 4, width: w, height: h - grassTop - 4))
                }
                context.fill(dirt, with: .color(dirtColor))

                // Grass surface
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

                // Grass tufts
                for i in stride(from: CGFloat(3), to: w, by: 8) {
                    let tuftY = grassTop + sin(i * 0.15) * 2 - 3
                    let tuft = Path { p in
                        p.addRect(CGRect(x: i, y: tuftY, width: 2, height: 4))
                    }
                    let c = Int(i) % 16 < 8 ? grassLight : grassHighlight
                    context.fill(tuft, with: .color(c))
                }

                // Stars/fireflies at night
                if isNighttime {
                    for i in 0 ..< 6 {
                        let sx = CGFloat(i) * w / 6.0 + sin(s.timePhase * 0.5 + Double(i)) * 3
                        let sy = CGFloat(3 + (i % 3) * 5) + sin(s.timePhase * 0.3 + Double(i) * 2) * 2
                        let glow = 0.3 + sin(s.timePhase * 2 + Double(i) * 1.5) * 0.3
                        let star = Path { p in
                            p.addEllipse(in: CGRect(x: sx, y: sy, width: 2, height: 2))
                        }
                        context.fill(star, with: .color(Color.yellow.opacity(glow)))
                    }
                }

                // Raindrops (when sad/sob)
                if emotion == .sad || emotion == .sob {
                    for drop in s.raindrops {
                        let raindrop = Path { p in
                            p.addRect(CGRect(x: drop.x, y: drop.y, width: 1, height: 3))
                        }
                        context.fill(raindrop, with: .color(Color(red: 0.5, green: 0.6, blue: 0.8).opacity(0.6)))
                    }
                }
            }

    }

    @ViewBuilder
    private var natureOverlay: some View {
            // Butterflies
            ForEach(0 ..< s.butterflies.count, id: \.self) { i in
                let b = s.butterflies[i]
                Canvas { context, _ in
                    let wingPhase = sin(s.timePhase * b.speed * 8)
                    let wingW: CGFloat = 3 + CGFloat(wingPhase) * 1.5
                    // Left wing
                    let lw = Path { p in
                        p.addEllipse(in: CGRect(x: -wingW, y: -2, width: wingW, height: 4))
                    }
                    // Right wing
                    let rw = Path { p in
                        p.addEllipse(in: CGRect(x: 1, y: -2, width: wingW, height: 4))
                    }
                    let colors: [Color] = [
                        Color(red: 0.9, green: 0.6, blue: 0.2),
                        Color(red: 0.6, green: 0.4, blue: 0.9),
                        Color(red: 0.2, green: 0.7, blue: 0.9),
                    ]
                    let c = colors[i % colors.count]
                    context.fill(lw, with: .color(c.opacity(0.8)))
                    context.fill(rw, with: .color(c.opacity(0.8)))
                    // Body
                    let body = Path { p in
                        p.addRect(CGRect(x: -0.5, y: -1.5, width: 1.5, height: 3))
                    }
                    context.fill(body, with: .color(.black.opacity(0.5)))
                }
                .frame(width: 12, height: 8)
                .offset(
                    x: b.x * width - width / 2,
                    y: b.y * height - height / 2
                )
                .allowsHitTesting(false)
            }

            // Hearts (when happy)
            ForEach(0 ..< s.hearts.count, id: \.self) { i in
                let h = s.hearts[i]
                Text("\u{2665}")
                    .font(.system(size: 6))
                    .foregroundColor(Color.red.opacity(h.opacity))
                    .offset(
                        x: h.x * width - width / 2,
                        y: h.y * height - height
                    )
                    .allowsHitTesting(false)
            }

            // Seasonal particles (snow, cherry blossoms, leaves)
            ForEach(0 ..< s.seasonalParticles.count, id: \.self) { i in
                let p = s.seasonalParticles[i]
                Canvas { context, _ in
                    switch currentSeason {
                    case .winter:
                        // Snowflake
                        let snow = Path { path in path.addEllipse(in: CGRect(x: -1.5, y: -1.5, width: 3, height: 3)) }
                        context.fill(snow, with: .color(.white.opacity(0.8)))
                    case .spring:
                        // Cherry blossom petal
                        let petal = Path { path in path.addEllipse(in: CGRect(x: -2, y: -1, width: 4, height: 3)) }
                        context.fill(petal, with: .color(Color(red: 1.0, green: 0.7, blue: 0.8).opacity(0.7)))
                    case .autumn:
                        // Falling leaf
                        let leaf = Path { path in path.addEllipse(in: CGRect(x: -2, y: -1.5, width: 4, height: 3)) }
                        context.fill(leaf, with: .color(Color(red: 0.85, green: 0.5, blue: 0.15).opacity(0.7)))
                    case .summer:
                        break  // no particles in summer (s.butterflies are enough)
                    }
                }
                .frame(width: 6, height: 6)
                .offset(x: p.x - width / 2, y: p.y)
                .allowsHitTesting(false)
            }

            // Confetti (milestones)
            ForEach(0 ..< s.confetti.count, id: \.self) { i in
                let c = s.confetti[i]
                let colors: [Color] = [.red, .yellow, .blue, .green, .orange, .purple]
                Rectangle()
                    .fill(colors[c.color % colors.count])
                    .frame(width: 3, height: 3)
                    .offset(x: c.x - width / 2, y: c.y)
                    .allowsHitTesting(false)
            }

            // Bird visitor
            if s.birdVisible {
                Canvas { context, _ in
                    let birdColor = Color(red: 0.6, green: 0.35, blue: 0.2)
                    // Body
                    let body = Path { p in p.addEllipse(in: CGRect(x: -3, y: -2, width: 7, height: 5)) }
                    context.fill(body, with: .color(birdColor))
                    // Head
                    let head = Path { p in p.addEllipse(in: CGRect(x: 3, y: -3, width: 4, height: 4)) }
                    context.fill(head, with: .color(birdColor))
                    // Beak
                    let beak = Path { p in p.addRect(CGRect(x: 6, y: -1.5, width: 3, height: 2)) }
                    context.fill(beak, with: .color(Color(red: 0.9, green: 0.7, blue: 0.2)))
                    // Eye
                    let eye = Path { p in p.addEllipse(in: CGRect(x: 4.5, y: -2, width: 1.5, height: 1.5)) }
                    context.fill(eye, with: .color(.black))
                    // Wing (if not landed, show flap)
                    if !s.birdLanded {
                        let wing = Path { p in p.addEllipse(in: CGRect(x: -2, y: -5, width: 6, height: 4)) }
                        context.fill(wing, with: .color(birdColor.opacity(0.7)))
                    }
                }
                .frame(width: 16, height: 12)
                .offset(
                    x: s.birdX * width,
                    y: s.birdLanded ? -(height * 0.3) : -(height * 0.6 + CGFloat(sin(s.timePhase * 3)) * 3)
                )
                .allowsHitTesting(false)
            }

            // Worm poking out of dirt
            if s.wormVisible {
                Canvas { context, _ in
                    let wormColor = Color(red: 0.7, green: 0.45, blue: 0.35)
                    let body = Path { p in p.addRoundedRect(in: CGRect(x: -1.5, y: 0, width: 3, height: 8), cornerSize: CGSize(width: 1.5, height: 1.5)) }
                    context.fill(body, with: .color(wormColor))
                    let eye = Path { p in p.addEllipse(in: CGRect(x: -0.5, y: 1, width: 1.5, height: 1.5)) }
                    context.fill(eye, with: .color(.black))
                }
                .frame(width: 6, height: 10)
                .offset(x: CGFloat.random(in: -0.3 ... 0.3) * width, y: s.wormY)
                .allowsHitTesting(false)
            }

            // Shooting stars (night only)
            ForEach(0 ..< s.shootingStars.count, id: \.self) { i in
                let star = s.shootingStars[i]
                Canvas { context, _ in
                    let trail = Path { p in
                        p.move(to: CGPoint(x: 0, y: 0))
                        p.addLine(to: CGPoint(x: -8, y: 2))
                    }
                    context.stroke(trail, with: .color(.white.opacity(star.life)), lineWidth: 1.5)
                    let dot = Path { p in p.addEllipse(in: CGRect(x: -1, y: -1, width: 2, height: 2)) }
                    context.fill(dot, with: .color(.white.opacity(star.life)))
                }
                .frame(width: 12, height: 6)
                .offset(x: star.x - width / 2, y: star.y)
                .allowsHitTesting(false)
            }

            // Rainbow (after rain clears)
            if s.showRainbow {
                Canvas { context, canvasSize in
                    let w = canvasSize.width
                    let h = canvasSize.height
                    let rainbowColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
                    for (i, color) in rainbowColors.enumerated() {
                        let radius = w * 0.4 - CGFloat(i) * 2
                        let arc = Path { p in
                            p.addArc(center: CGPoint(x: w / 2, y: h), radius: radius, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                        }
                        context.stroke(arc, with: .color(color.opacity(s.rainbowOpacity * 0.5)), lineWidth: 1.5)
                    }
                }
                .frame(width: width, height: height)
                .allowsHitTesting(false)
            }

            // Campfire (night, idle)
            if isNighttime && !isProcessing {
                Canvas { context, _ in
                    // Logs
                    let log1 = Path { p in p.addRect(CGRect(x: -4, y: 2, width: 8, height: 2)) }
                    let log2 = Path { p in p.addRect(CGRect(x: -3, y: 0, width: 6, height: 2)) }
                    context.fill(log1, with: .color(Color(red: 0.4, green: 0.25, blue: 0.1)))
                    context.fill(log2, with: .color(Color(red: 0.35, green: 0.2, blue: 0.08)))
                    // Flame
                    let flameH = 5 + s.campfireFlicker * 2
                    let flame = Path { p in
                        p.addEllipse(in: CGRect(x: -2, y: -CGFloat(flameH), width: 4, height: CGFloat(flameH)))
                    }
                    context.fill(flame, with: .color(Color(red: 1.0, green: 0.6, blue: 0.1).opacity(0.8)))
                    let innerFlame = Path { p in
                        p.addEllipse(in: CGRect(x: -1, y: -CGFloat(flameH * 0.6), width: 2, height: CGFloat(flameH * 0.6)))
                    }
                    context.fill(innerFlame, with: .color(Color(red: 1.0, green: 0.9, blue: 0.3).opacity(0.9)))
                }
                .frame(width: 12, height: 14)
                .offset(x: 0, y: -(height * 0.2))
                .allowsHitTesting(false)
            }

            // Mushrooms (grow over time on grass)
            ForEach(0 ..< s.mushrooms.count, id: \.self) { i in
                let m = s.mushrooms[i]
                Canvas { context, _ in
                    let sz = m.size
                    // Stem
                    let stem = Path { p in p.addRect(CGRect(x: -1 * sz, y: 0, width: 2 * sz, height: 4 * sz)) }
                    context.fill(stem, with: .color(Color(red: 0.9, green: 0.85, blue: 0.7)))
                    // Cap
                    let cap = Path { p in p.addEllipse(in: CGRect(x: -2.5 * sz, y: -2 * sz, width: 5 * sz, height: 3 * sz)) }
                    context.fill(cap, with: .color(Color(red: 0.8, green: 0.2, blue: 0.15)))
                    // Spots
                    let spot = Path { p in p.addEllipse(in: CGRect(x: -0.5 * sz, y: -1.5 * sz, width: 1.5 * sz, height: 1 * sz)) }
                    context.fill(spot, with: .color(.white.opacity(0.8)))
                }
                .frame(width: 10, height: 10)
                .offset(x: m.x * width - width / 2, y: -(height * 0.1))
                .allowsHitTesting(false)
            }

            // Footprints (fade behind walking turtle)
            ForEach(0 ..< s.footprints.count, id: \.self) { i in
                let fp = s.footprints[i]
                Circle()
                    .fill(Color(red: 0.15, green: 0.25, blue: 0.12).opacity(fp.opacity))
                    .frame(width: 2, height: 2)
                    .offset(x: fp.x * width, y: -(height * 0.05))
                    .allowsHitTesting(false)
            }

            // Snail companion (appears during long sessions)
            if s.snailVisible {
                Canvas { context, _ in
                    let shellC = Color(red: 0.7, green: 0.5, blue: 0.3)
                    let bodyC = Color(red: 0.6, green: 0.55, blue: 0.4)
                    // Body
                    let body = Path { p in p.addEllipse(in: CGRect(x: -4, y: 0, width: 8, height: 3)) }
                    context.fill(body, with: .color(bodyC))
                    // Shell
                    let shell = Path { p in p.addEllipse(in: CGRect(x: -2, y: -4, width: 6, height: 6)) }
                    context.fill(shell, with: .color(shellC))
                    // Shell spiral
                    let spiral = Path { p in p.addEllipse(in: CGRect(x: 0, y: -2.5, width: 3, height: 3)) }
                    context.fill(spiral, with: .color(shellC.opacity(0.6)))
                    // Eye stalks
                    let stalk = Path { p in p.addRect(CGRect(x: -4, y: -3, width: 1, height: 3)) }
                    context.fill(stalk, with: .color(bodyC))
                    let eye = Path { p in p.addEllipse(in: CGRect(x: -4.5, y: -4, width: 2, height: 2)) }
                    context.fill(eye, with: .color(.black))
                }
                .frame(width: 14, height: 10)
                .offset(x: s.snailX * width, y: -(height * 0.15))
                .allowsHitTesting(false)
            }

            // Music notes (when Luminbeat session active)
            ForEach(0 ..< s.musicNotes.count, id: \.self) { i in
                let note = s.musicNotes[i]
                Text("\u{266A}")
                    .font(.system(size: 7))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9).opacity(note.opacity))
                    .offset(x: note.x * width - width / 2, y: note.y * height - height)
                    .allowsHitTesting(false)
            }

            // Puddles (after rain evaporates)
            ForEach(0 ..< s.puddles.count, id: \.self) { i in
                let puddle = s.puddles[i]
                Canvas { context, _ in
                    let water = Path { p in
                        p.addEllipse(in: CGRect(x: -4, y: -1.5, width: 8, height: 3))
                    }
                    context.fill(water, with: .color(Color(red: 0.4, green: 0.5, blue: 0.75).opacity(puddle.opacity * 0.6)))
                    // Highlight
                    let shine = Path { p in
                        p.addEllipse(in: CGRect(x: -2, y: -1, width: 3, height: 1.5))
                    }
                    context.fill(shine, with: .color(Color.white.opacity(puddle.opacity * 0.3)))
                }
                .frame(width: 12, height: 6)
                .offset(x: puddle.x * width, y: -(height * 0.05))
                .allowsHitTesting(false)
            }

    }

    @ViewBuilder
    private var flowerAndTurtle: some View {
            // Flower with individually visible petals
            if s.flowerVisible {
                Canvas { context, canvasSize in
                    let sc = min(height * 0.35, 14) / 14.0
                    let cx = canvasSize.width / 2
                    let cy = canvasSize.height / 2

                    let stemColor = Color(red: 0.25, green: 0.55, blue: 0.18)
                    let leafColor = Color(red: 0.30, green: 0.62, blue: 0.22)
                    let petalColor = Color(red: 1.0, green: 0.40, blue: 0.55)
                    let petalLight = Color(red: 1.0, green: 0.60, blue: 0.70)
                    let centerColor = Color(red: 1.0, green: 0.82, blue: 0.15)

                    // Stem
                    let stem = Path { p in
                        p.addRect(CGRect(x: cx - 1.5 * sc, y: cy + 3 * sc, width: 3 * sc, height: 10 * sc))
                    }
                    context.fill(stem, with: .color(stemColor))

                    // Small leaf on stem
                    let leaf = Path { p in
                        p.addEllipse(in: CGRect(x: cx + 1 * sc, y: cy + 6 * sc, width: 5 * sc, height: 3 * sc))
                    }
                    context.fill(leaf, with: .color(leafColor))

                    // Petals (round ellipses arranged in a circle)
                    let petalAngles: [Double] = [0, 72, 144, 216, 288]
                    let petalRadius: CGFloat = 5 * sc
                    let petalW: CGFloat = 5 * sc
                    let petalH: CGFloat = 7 * sc
                    let currentPetalCount = self.s.petalCount

                    for (i, angle) in petalAngles.enumerated() {
                        guard i < currentPetalCount else { continue }
                        let rad = angle * .pi / 180
                        let px = cx + cos(rad) * petalRadius - petalW / 2
                        let py = cy - 1 * sc + sin(rad) * petalRadius - petalH / 2
                        let petal = Path { p in
                            p.addEllipse(in: CGRect(x: px, y: py, width: petalW, height: petalH))
                        }
                        let c = i % 2 == 0 ? petalColor : petalLight
                        context.fill(petal, with: .color(c))
                    }

                    // Center (always visible)
                    let center = Path { p in
                        p.addEllipse(in: CGRect(x: cx - 3 * sc, y: cy - 4 * sc, width: 6 * sc, height: 6 * sc))
                    }
                    context.fill(center, with: .color(centerColor))
                }
                .frame(width: 24, height: 24)
                .scaleEffect(s.flowerScale)
                .offset(
                    x: s.flowerX * width,
                    y: -(height * 0.22)
                )
                .transition(.scale.combined(with: .opacity))
                .animation(.easeInOut(duration: 0.2), value: s.petalCount)
            }

            // Turtle (walks across scene, flips direction)
            ClaudeTurtleIcon(
                size: min(height * 0.75, 28),
                animateLegs: (s.isWalking && !s.isSleeping && !s.isEating) || (isProcessing && !s.isSleeping && !s.isEating),
                emotion: emotion,
                isBlinking: s.isBlinking,
                headExtension: s.headExtension,
                isSleeping: s.isSleeping,
                mouthOpen: s.mouthOpen,
                lookingUp: s.lookingUp,
                hiddenInShell: s.hiddenInShell,
                hatType: currentHat,
                shellProgress: 0
            )
            .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
            .scaleEffect(x: s.facingRight ? s.breathScale : -s.breathScale, y: s.breathScale, anchor: .bottom)
            .offset(
                x: s.walkX * width + (emotion == .sob ? CGFloat(s.trembleX) : 0) + s.tailWag,
                y: -(height * 0.25) + CGFloat(sin(s.bobPhase) * Double(bobAmplitude))
            )
            .rotationEffect(.degrees(s.swayAngle * swayDeg + s.spinAngle), anchor: .bottom)
            .onTapGesture {
                // Click turtle → spin!
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    s.spinAngle += 360
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(600))
                    withAnimation(.easeOut(duration: 0.2)) { s.spinAngle = 0 }
                }
            }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            grassCanvas
            natureOverlay
            flowerAndTurtle
        }
        .frame(width: width, height: height)
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                s.cursorNearNotch = true
                s.cursorX = (location.x / max(width, 1)) - 0.5  // -0.5 to 0.5
                // Sheldon looks toward cursor when idle and nudges toward it
                if !s.isWalking && !s.isEating && !s.isSleeping {
                    s.facingRight = s.cursorX > s.walkX
                    // Gentle nudge toward cursor (very slow creep)
                    let dist = s.cursorX - s.walkX
                    if abs(dist) > 0.05 {
                        s.walkX += dist * 0.008  // ease toward cursor
                        // Clamp to edges
                        s.walkX = max(-0.45, min(0.45, s.walkX))
                    }
                }
            case .ended:
                s.cursorNearNotch = false
            @unknown default:
                break
            }
        }
        .onReceive(motionTimer) { now in
            // Core motion
            s.bobPhase += (2.0 * .pi) / (bobSpeed * 30.0)
            s.swayAngle = sin(s.bobPhase * 0.7)
            s.trembleX = emotion == .sob ? Double.random(in: -1.0 ... 1.0) : 0

            // Breathing: subtle shell pulse
            let breathCycle = sin(s.bobPhase * 0.4) * 0.015
            s.breathScale = 1.0 + CGFloat(breathCycle)

            // Nature animation clock
            s.timePhase += 1.0 / 30.0

            // Butterfly movement (gentle drift)
            for i in 0 ..< s.butterflies.count {
                s.butterflies[i].x += CGFloat(sin(s.timePhase * s.butterflies[i].speed + s.butterflies[i].phase)) * 0.002
                s.butterflies[i].y += CGFloat(cos(s.timePhase * s.butterflies[i].speed * 0.7 + s.butterflies[i].phase)) * 0.003
                // Wrap around
                if s.butterflies[i].x < -0.1 { s.butterflies[i].x = 1.1 }
                if s.butterflies[i].x > 1.1 { s.butterflies[i].x = -0.1 }
                if s.butterflies[i].y < 0.05 { s.butterflies[i].y = 0.4 }
                if s.butterflies[i].y > 0.5 { s.butterflies[i].y = 0.05 }
            }

            // Heart particles (float up and fade)
            for i in (0 ..< s.hearts.count).reversed() {
                s.hearts[i].y -= 0.01
                s.hearts[i].opacity -= 0.015
                s.hearts[i].age += 1.0 / 30.0
                if s.hearts[i].opacity <= 0 {
                    s.hearts.remove(at: i)
                }
            }

            // Raindrops (fall and respawn)
            if emotion == .sad || emotion == .sob {
                for i in 0 ..< s.raindrops.count {
                    s.raindrops[i].y += 2
                    if s.raindrops[i].y > height {
                        s.raindrops[i].y = 0
                        s.raindrops[i].x = CGFloat.random(in: 0 ... max(width, 1))
                    }
                }
            }

            // Seasonal particles (drift and fall)
            for i in 0 ..< s.seasonalParticles.count {
                s.seasonalParticles[i].y += s.seasonalParticles[i].speed
                s.seasonalParticles[i].x += s.seasonalParticles[i].drift + CGFloat(sin(s.timePhase + Double(i))) * 0.3
                if s.seasonalParticles[i].y > height {
                    s.seasonalParticles[i].y = -5
                    s.seasonalParticles[i].x = CGFloat.random(in: 0 ... max(width, 1))
                }
            }

            // Confetti (fall and fade)
            for i in (0 ..< s.confetti.count).reversed() {
                s.confetti[i].y += s.confetti[i].speed
                s.confetti[i].x += CGFloat(sin(s.timePhase * 3 + Double(i) * 2)) * 0.5
                if s.confetti[i].y > height + 10 {
                    s.confetti.remove(at: i)
                }
            }

            // Bird flight
            if s.birdVisible && !s.birdLanded {
                s.birdX += 0.002
                if s.birdX > 0.5 {
                    s.birdLanded = true
                }
            }

            // Shooting stars (move and fade)
            for i in (0 ..< s.shootingStars.count).reversed() {
                s.shootingStars[i].x += s.shootingStars[i].dx
                s.shootingStars[i].y += 0.5
                s.shootingStars[i].life -= 0.02
                if s.shootingStars[i].life <= 0 {
                    s.shootingStars.remove(at: i)
                }
            }

            // Campfire flicker
            if isNighttime {
                s.campfireFlicker = sin(s.timePhase * 8) * 0.5 + Double.random(in: -0.2 ... 0.2)
            }

            // Footprints (fade)
            for i in (0 ..< s.footprints.count).reversed() {
                s.footprints[i].opacity -= 0.003
                if s.footprints[i].opacity <= 0 {
                    s.footprints.remove(at: i)
                }
            }

            // Snail creep (very slow)
            if s.snailVisible {
                s.snailX += 0.0002
                if s.snailX > 0.5 { s.snailX = -0.5 }
            }

            // Puddle evaporation
            for i in (0 ..< s.puddles.count).reversed() {
                s.puddles[i].opacity -= 0.001
                if s.puddles[i].opacity <= 0 {
                    s.puddles.remove(at: i)
                }
            }

            // Music notes (float up and fade)
            for i in (0 ..< s.musicNotes.count).reversed() {
                s.musicNotes[i].y -= 0.008
                s.musicNotes[i].opacity -= 0.01
                if s.musicNotes[i].opacity <= 0 {
                    s.musicNotes.remove(at: i)
                }
            }

            // Rainbow fade
            if s.showRainbow {
                s.rainbowOpacity = max(0, s.rainbowOpacity - 0.002)
                if s.rainbowOpacity <= 0 { s.showRainbow = false }
            }

            // Walking logic -- only walks when Claude is processing and not eating
            guard !s.isSleeping else { return }
            guard !s.isEating else { return }
            guard isProcessing else {
                // Walk to resting spot when idle (visible edges, not behind notch)
                let leftRest: CGFloat = -0.45
                let rightRest: CGFloat = 0.45
                let restTarget = s.walkDirection >= 0 ? rightRest : leftRest
                let distToRest = abs(s.walkX - restTarget)

                if distToRest > 0.02 {
                    // Walk toward resting spot
                    let dir: CGFloat = restTarget > s.walkX ? 1 : -1
                    s.walkX += dir * 0.003
                    s.facingRight = dir > 0
                    s.walkDirection = dir

                    // Can still eat flower on the way to rest
                    if s.flowerVisible && !s.flowerEaten && !s.petalRegrowing && s.petalCount > 0 && abs(s.walkX - s.flowerX) < 0.03 {
                        eatFlower()
                    }
                    return
                }
                // Arrived at resting spot -- face away from notch
                s.walkX = restTarget
                s.isWalking = false
                s.facingRight = restTarget > 0  // right side faces right, left side faces left
                return
            }
            guard now > s.walkPauseUntil else { return }

            s.isWalking = true
            let baseSpeed: CGFloat = 0.0015
            let speed: CGFloat = abs(s.walkX) < 0.15 ? baseSpeed * 3 : baseSpeed
            s.walkX += s.walkDirection * speed

            // Edge boundaries
            let leftEdge: CGFloat = -0.45
            let rightEdge: CGFloat = 0.45
            if true {

                // Hit an edge: pause, then turn around
                if s.walkX >= rightEdge {
                    s.walkX = rightEdge
                    s.isWalking = false
                    // Pause at edge 2-5 seconds (longer on edges = more visible time)
                    let pause = Double.random(in: 2.0 ... 5.0)
                    s.walkPauseUntil = now.addingTimeInterval(pause)
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(pause))
                        s.walkDirection = -1
                        s.facingRight = false
                        s.isWalking = true
                    }
                } else if s.walkX <= leftEdge {
                    s.walkX = leftEdge
                    s.isWalking = false
                    let pause = Double.random(in: 2.0 ... 5.0)
                    s.walkPauseUntil = now.addingTimeInterval(pause)
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(pause))
                        s.walkDirection = 1
                        s.facingRight = true
                        s.isWalking = true
                    }
                }

                // Check if turtle is near the flower
                let eatGap: CGFloat = 0.04  // small gap so head reaches flower
                if s.flowerVisible && !s.flowerEaten && !s.petalRegrowing && s.petalCount > 0 && abs(s.walkX - s.flowerX) < eatGap {
                    eatFlower()
                }
            }
        }
        .onReceive(lifeTimer) { now in
            // Track activity
            if isProcessing {
                s.lastActivityTime = now
                if s.isSleeping {
                    // Wake up
                    withAnimation(.easeInOut(duration: 0.5)) { s.isSleeping = false }
                }
            }

            // Sleep check
            if !isProcessing && now.timeIntervalSince(s.lastActivityTime) > sleepThreshold && !s.isSleeping {
                withAnimation(.easeInOut(duration: 1.0)) { s.isSleeping = true }
            }

            // Blinking (every 3-6 seconds, 150ms blink)
            if !s.isSleeping && !s.isBlinking && Int.random(in: 0 ..< 8) == 0 {
                s.isBlinking = true
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(150))
                    s.isBlinking = false
                }
            }

            // Hearts when happy
            if emotion == .happy && !s.isSleeping && Int.random(in: 0 ..< 4) == 0 {
                s.hearts.append((
                    x: CGFloat(s.walkX) + 0.5 + CGFloat.random(in: -0.02 ... 0.02),
                    y: 0.6,
                    opacity: 0.9,
                    age: 0
                ))
                // Cap at 5 s.hearts
                if s.hearts.count > 5 { s.hearts.removeFirst() }
            }

            // Rain management
            if (emotion == .sad || emotion == .sob) && s.raindrops.count < 15 {
                for _ in 0 ..< 3 {
                    s.raindrops.append((
                        x: CGFloat.random(in: 0 ... max(width, 1)),
                        y: CGFloat.random(in: 0 ... max(height, 1))
                    ))
                }
            } else if emotion != .sad && emotion != .sob && !s.raindrops.isEmpty {
                s.raindrops.removeAll()
            }

            // Shooting stars at night (random, rare)
            if isNighttime && s.shootingStars.count < 2 && Int.random(in: 0 ..< 60) == 0 {
                s.shootingStars.append((
                    x: CGFloat.random(in: 0 ... max(width, 1)),
                    y: CGFloat.random(in: 0 ... 8),
                    dx: CGFloat.random(in: 2 ... 4),
                    life: 1.0
                ))
            }

            // Mushroom growth (slowly appear over time, max 3)
            if s.mushrooms.count < 3 && Int.random(in: 0 ..< 300) == 0 {
                let newMushroom = (x: CGFloat.random(in: -0.4 ... 0.4), size: CGFloat(0.3))
                s.mushrooms.append(newMushroom)
            }
            // Grow existing mushrooms
            for i in 0 ..< s.mushrooms.count {
                if s.mushrooms[i].size < 1.0 {
                    s.mushrooms[i].size = min(1.0, s.mushrooms[i].size + 0.005)
                }
            }

            // Snail appears after 10 minutes of session time
            if !s.snailVisible && Date().timeIntervalSince(s.sessionStartTime) > 600 {
                s.snailVisible = true
                s.snailX = -0.5
            }

            // Music notes when a luminbeat session is active
            if s.hasLuminbeatSession && isProcessing && s.musicNotes.count < 4 && Int.random(in: 0 ..< 6) == 0 {
                s.musicNotes.append((
                    x: CGFloat(s.walkX) + 0.5 + CGFloat.random(in: -0.05 ... 0.05),
                    y: 0.7,
                    opacity: 0.9
                ))
            }

            // Footprints while walking
            if s.isWalking && isProcessing && Int.random(in: 0 ..< 4) == 0 {
                s.footprints.append((x: s.walkX, opacity: 0.4))
                if s.footprints.count > 20 { s.footprints.removeFirst() }
            }

            // Seasonal particle spawning
            if currentSeason != .summer && s.seasonalParticles.count < 8 && Int.random(in: 0 ..< 6) == 0 {
                s.seasonalParticles.append((
                    x: CGFloat.random(in: 0 ... max(width, 1)),
                    y: -5,
                    drift: CGFloat.random(in: -0.3 ... 0.3),
                    speed: CGFloat.random(in: 0.3 ... 0.8)
                ))
            }

            // Bird visitor (random, about every 2 minutes)
            if !s.birdVisible && Int.random(in: 0 ..< 240) == 0 {
                s.birdX = -0.5
                s.birdVisible = true
                s.birdLanded = false
                // Bird flies away after 10-15 seconds
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(Double.random(in: 10 ... 15)))
                    s.birdVisible = false
                    s.birdLanded = false
                }
            }

            // Worm pokes out occasionally
            if !s.wormVisible && Int.random(in: 0 ..< 120) == 0 {
                s.wormVisible = true
                s.wormY = 0
                Task { @MainActor in
                    // Poke up
                    for _ in 0 ..< 5 {
                        withAnimation(.easeOut(duration: 0.2)) { s.wormY -= 2 }
                        try? await Task.sleep(for: .milliseconds(200))
                    }
                    // Pause
                    try? await Task.sleep(for: .seconds(Double.random(in: 2 ... 4)))
                    // Retract
                    for _ in 0 ..< 5 {
                        withAnimation(.easeIn(duration: 0.15)) { s.wormY += 2 }
                        try? await Task.sleep(for: .milliseconds(150))
                    }
                    s.wormVisible = false
                }
            }

            // Error streak → hide in shell
            if emotion == .sob && s.errorStreak >= 3 && !s.hiddenInShell {
                withAnimation(.easeIn(duration: 0.3)) { s.hiddenInShell = true }
                s.isWalking = false
            }
            if emotion != .sob && s.hiddenInShell {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { s.hiddenInShell = false }
                s.isWalking = true
                s.errorStreak = 0
            }

            // Look up at user occasionally (breaks fourth wall)
            if !s.isSleeping && !s.isEating && !s.lookingUp && Int.random(in: 0 ..< 40) == 0 {
                s.lookingUp = true
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(Double.random(in: 1.0 ... 2.0)))
                    s.lookingUp = false
                }
            }

            // Idle fidgets (random head movements and tail wags)
            if !isProcessing && !s.isSleeping {
                // Head peek (occasionally extend/retract)
                if Int.random(in: 0 ..< 20) == 0 {
                    let target = CGFloat.random(in: -2 ... 3)
                    withAnimation(.easeInOut(duration: 0.4)) { s.headExtension = target }
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(800))
                        withAnimation(.easeInOut(duration: 0.3)) { s.headExtension = 0 }
                    }
                }

                // Tail wag (small horizontal shift)
                if Int.random(in: 0 ..< 25) == 0 {
                    withAnimation(.easeInOut(duration: 0.15)) { s.tailWag = CGFloat.random(in: -0.5 ... 0.5) }
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(300))
                        withAnimation(.easeInOut(duration: 0.15)) { s.tailWag = 0 }
                    }
                }
            }
        }
        .onAppear {
            // Always have a flower on the scene
            if !s.flowerVisible {
                spawnFlower()
            }
            // Spawn 2-3 s.butterflies
            if s.butterflies.isEmpty {
                for _ in 0 ..< Int.random(in: 2 ... 3) {
                    s.butterflies.append((
                        x: CGFloat.random(in: 0.1 ... 0.9),
                        y: CGFloat.random(in: 0.1 ... 0.4),
                        phase: Double.random(in: 0 ... .pi * 2),
                        speed: Double.random(in: 0.5 ... 1.5)
                    ))
                }
            }
        }
        .onChange(of: isProcessing) { wasProcessing, nowProcessing in
            // Wake up when processing starts
            if nowProcessing && s.isSleeping {
                // First prompt after sleep = stretch wake-up
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { s.isSleeping = false }
                // Yawn/stretch: head extends way out then back
                Task { @MainActor in
                    withAnimation(.easeOut(duration: 0.4)) { s.headExtension = 6 }
                    try? await Task.sleep(for: .milliseconds(600))
                    withAnimation(.easeInOut(duration: 0.3)) { s.headExtension = 0 }
                }
            }
            s.lastActivityTime = Date()

            if nowProcessing {
                s.promptCount += 1
                s.errorStreak = 0

                // Confetti at milestones (every 50 prompts)
                if s.promptCount % 50 == 0 {
                    for _ in 0 ..< 20 {
                        s.confetti.append((
                            x: CGFloat.random(in: 0 ... max(width, 1)),
                            y: -CGFloat.random(in: 0 ... 10),
                            color: Int.random(in: 0 ..< 6),
                            speed: CGFloat.random(in: 0.5 ... 1.5)
                        ))
                    }
                }
            }

            // Spawn a new flower if there isn't one
            if nowProcessing && !s.flowerVisible {
                spawnFlower()
            }
        }
        .onChange(of: emotion) { oldEmotion, newEmotion in
            // Track error streaks
            if newEmotion == .sad || newEmotion == .sob {
                s.errorStreak += 1
            } else if newEmotion == .happy || newEmotion == .neutral {
                s.errorStreak = 0
            }

            // Puddles after rain clears (sad/sob -> neutral/happy)
            if (oldEmotion == .sad || oldEmotion == .sob) && (newEmotion == .happy || newEmotion == .neutral) {
                // Spawn 3-5 puddles where rain was
                let puddleCount = Int.random(in: 3 ... 5)
                for _ in 0 ..< puddleCount {
                    s.puddles.append((
                        x: CGFloat.random(in: -0.4 ... 0.4),
                        opacity: Double.random(in: 0.6 ... 1.0)
                    ))
                }
                // Cap puddles
                if s.puddles.count > 8 { s.puddles = Array(s.puddles.suffix(8)) }
            }

            // Rainbow after rain clears (sad/sob -> happy)
            if (oldEmotion == .sad || oldEmotion == .sob) && newEmotion == .happy {
                s.showRainbow = true
                s.rainbowOpacity = 1.0
            }

            // Happy bounce reaction
            if newEmotion == .happy {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                    s.headExtension = 4
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(400))
                    withAnimation(.easeInOut(duration: 0.3)) { s.headExtension = 0 }
                }
            }
            // Sad: retract head
            if newEmotion == .sad || newEmotion == .sob {
                withAnimation(.easeInOut(duration: 0.5)) { s.headExtension = -3 }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(1200))
                    withAnimation(.easeInOut(duration: 0.4)) { s.headExtension = 0 }
                }
            }
        }
    }

    // MARK: - Flower Logic

    private func spawnFlower() {
        // Flower always on the right edge
        s.flowerX = CGFloat.random(in: 0.40 ... 0.44)
        s.flowerEaten = false
        s.petalCount = 5
        s.petalRegrowing = false
        s.flowerVisible = true
        s.flowerScale = 0

        // Grow animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            s.flowerScale = 1.0
        }
        // Don't redirect turtle -- let him walk naturally and eat when he passes by
    }

    private func eatFlower() {
        guard !s.flowerEaten else { return }
        s.flowerEaten = true
        s.isEating = true
        s.isWalking = false  // Stop walking to eat

        // Eat petals one by one with mouth chomping
        Task { @MainActor in
            for petal in stride(from: s.petalCount, to: 0, by: -1) {
                // Open mouth + head forward
                s.mouthOpen = true
                withAnimation(.spring(response: 0.1, dampingFraction: 0.5)) {
                    s.headExtension = 3
                }
                try? await Task.sleep(for: .milliseconds(250))

                // Close mouth (chomp!) + remove a petal
                s.mouthOpen = false
                withAnimation(.easeOut(duration: 0.15)) {
                    s.petalCount = petal - 1
                }
                withAnimation(.easeOut(duration: 0.1)) {
                    s.headExtension = 1
                }
                try? await Task.sleep(for: .milliseconds(200))

                // Open mouth again for next bite
                if petal - 1 > 0 {
                    s.mouthOpen = true
                    try? await Task.sleep(for: .milliseconds(150))
                    s.mouthOpen = false
                    try? await Task.sleep(for: .milliseconds(100))
                }
            }

            // Done eating
            s.mouthOpen = false
            withAnimation(.easeOut(duration: 0.2)) { s.headExtension = 0 }
            s.isEating = false

            // All petals eaten, turtle walks away
            s.petalRegrowing = true
            startPetalRegrowth()

            // Walk away from flower
            let awayDirection: CGFloat = s.walkX > 0 ? -1 : 1
            s.walkDirection = awayDirection
            s.facingRight = s.walkDirection > 0
            s.isWalking = true
        }
    }

    private func startPetalRegrowth() {
        Task { @MainActor in
            // Wait a bit before regrowing
            try? await Task.sleep(for: .seconds(2.0))

            // Regrow petals one by one
            for p in 1 ... 5 {
                guard s.flowerVisible && s.petalRegrowing else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    s.petalCount = p
                }
                try? await Task.sleep(for: .milliseconds(600))
            }

            // Flower is fully regrown, turtle can come eat it again
            s.petalRegrowing = false
            s.flowerEaten = false
            // Don't redirect turtle -- he'll eat it next time he walks past
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
