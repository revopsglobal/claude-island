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
    var isBlinking: Bool = false
    var headExtension: CGFloat = 0  // 0 = normal, negative = retracted, positive = extended
    var isSleeping: Bool = false
    var mouthOpen: Bool = false
    var lookingUp: Bool = false

    @State private var legPhase: Int = 0

    private let legTimer = Timer.publish(every: 0.18, on: .main, in: .common).autoconnect()

    init(size: CGFloat = 16, animateLegs: Bool = false, emotion: CrabEmotion = .neutral,
         isBlinking: Bool = false, headExtension: CGFloat = 0, isSleeping: Bool = false, mouthOpen: Bool = false, lookingUp: Bool = false) {
        self.size = size
        self.animateLegs = animateLegs
        self.emotion = emotion
        self.isBlinking = isBlinking
        self.headExtension = headExtension
        self.isSleeping = isSleeping
        self.mouthOpen = mouthOpen
        self.lookingUp = lookingUp
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

    var body: some View {
        Canvas { context, canvasSize in
            let s = size / 48.0
            let xOff = (canvasSize.width - 56 * s) / 2
            let headX = headExtension

            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, color: Color) {
                let r = CGRect(x: (x + xOff / s) * s, y: y * s, width: w * s, height: h * s)
                context.fill(Path(r), with: .color(color))
            }

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
                let h: CGFloat = 10 + currentLeg[i]
                rect(pos.0, pos.1, 6, h, color: skinColor)
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

            // -- HEAD (with extension) --
            rect(46 + headX, 20, 10, 12, color: skinColor)

            // -- TAIL --
            rect(0, 30, 8, 4, color: skinColor)
            rect(-2, 32, 4, 3, color: skinColor)

            // -- EYES --
            let eyeColor: Color = .black
            if isSleeping {
                // Sleeping: closed eyes (horizontal lines)
                rect(50 + headX, 24, 4, 1.5, color: eyeColor)
            } else if isBlinking {
                // Blink: thin horizontal line
                rect(50 + headX, 24, 3, 1, color: eyeColor)
            } else if lookingUp {
                // Looking up at user: eye shifted upward
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
                // Eating: mouth wide open
                rect(51 + headX, 27, 5, 5, color: eyeColor)
                // Inside of mouth (dark red)
                rect(52 + headX, 28, 3, 3, color: Color(red: 0.5, green: 0.15, blue: 0.1))
            } else if isSleeping {
                // Sleeping: no mouth
            } else {
                switch emotion {
                case .happy:
                    rect(51 + headX, 28, 4, 2, color: eyeColor)
                case .sad, .sob:
                    rect(51 + headX, 30, 4, 2, color: eyeColor)
                default:
                    break
                }
            }

            // -- SLEEP Zs (when sleeping) --
            if isSleeping {
                let zColor = Color.white.opacity(0.5)
                // Small z
                rect(54 + headX, 14, 4, 1, color: zColor)
                rect(55 + headX, 15, 2, 1, color: zColor)
                rect(54 + headX, 16, 4, 1, color: zColor)
                // Bigger Z
                rect(58 + headX, 8, 5, 1.5, color: zColor)
                rect(60 + headX, 9.5, 3, 1.5, color: zColor)
                rect(58 + headX, 11, 5, 1.5, color: zColor)
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

    // Motion state
    @State private var bobPhase: Double = 0
    @State private var swayAngle: Double = 0
    @State private var trembleX: Double = 0

    // Walking state
    @State private var walkX: CGFloat = -0.35       // normalized position (-0.5 to 0.5), start on left edge
    @State private var walkDirection: CGFloat = 1    // 1 = right, -1 = left
    @State private var isWalking: Bool = true
    @State private var walkPauseUntil: Date = .distantPast
    @State private var facingRight: Bool = true

    // Flower state
    @State private var flowerX: CGFloat = 0.35          // where the flower is (normalized)
    @State private var flowerVisible: Bool = false
    @State private var flowerScale: CGFloat = 0
    @State private var flowerEaten: Bool = false
    @State private var petalCount: Int = 5              // 5 petals, turtle eats them one by one
    @State private var petalRegrowing: Bool = false
    @State private var isEating: Bool = false
    @State private var mouthOpen: Bool = false

    // Nature state
    @State private var butterflies: [(x: CGFloat, y: CGFloat, phase: Double, speed: Double)] = []
    @State private var hearts: [(x: CGFloat, y: CGFloat, opacity: Double, age: Double)] = []
    @State private var raindrops: [(x: CGFloat, y: CGFloat)] = []
    @State private var timePhase: Double = 0  // for butterfly/particle animation

    // Life state
    @State private var isBlinking: Bool = false
    @State private var headExtension: CGFloat = 0
    @State private var isSleeping: Bool = false
    @State private var breathScale: CGFloat = 1.0
    @State private var lastActivityTime: Date = Date()
    @State private var tailWag: CGFloat = 0
    @State private var lookingUp: Bool = false

    // Timers
    private let motionTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()
    private let lifeTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    // Sleep after 3 minutes of idle
    private let sleepThreshold: TimeInterval = 180

    private var bobAmplitude: CGFloat {
        if isSleeping { return 0.3 }
        switch emotion {
        case .neutral: return 1.2
        case .happy: return 2.0
        case .sad: return 0.4
        case .sob: return 0
        }
    }

    private var bobSpeed: Double {
        if isSleeping { return 3.0 }
        return isProcessing ? 0.6 : 1.5
    }

    private var swayDeg: Double {
        if isSleeping { return 0.1 }
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

    var body: some View {
        ZStack(alignment: .bottom) {
            // Grass island
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
                        let sx = CGFloat(i) * w / 6.0 + sin(timePhase * 0.5 + Double(i)) * 3
                        let sy = CGFloat(3 + (i % 3) * 5) + sin(timePhase * 0.3 + Double(i) * 2) * 2
                        let glow = 0.3 + sin(timePhase * 2 + Double(i) * 1.5) * 0.3
                        let star = Path { p in
                            p.addEllipse(in: CGRect(x: sx, y: sy, width: 2, height: 2))
                        }
                        context.fill(star, with: .color(Color.yellow.opacity(glow)))
                    }
                }

                // Raindrops (when sad/sob)
                if emotion == .sad || emotion == .sob {
                    for drop in raindrops {
                        let raindrop = Path { p in
                            p.addRect(CGRect(x: drop.x, y: drop.y, width: 1, height: 3))
                        }
                        context.fill(raindrop, with: .color(Color(red: 0.5, green: 0.6, blue: 0.8).opacity(0.6)))
                    }
                }
            }

            // Butterflies
            ForEach(0 ..< butterflies.count, id: \.self) { i in
                let b = butterflies[i]
                Canvas { context, _ in
                    let wingPhase = sin(timePhase * b.speed * 8)
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
            ForEach(0 ..< hearts.count, id: \.self) { i in
                let h = hearts[i]
                Text("\u{2665}")
                    .font(.system(size: 6))
                    .foregroundColor(Color.red.opacity(h.opacity))
                    .offset(
                        x: h.x * width - width / 2,
                        y: h.y * height - height
                    )
                    .allowsHitTesting(false)
            }

            // Flower with individually visible petals
            if flowerVisible {
                Canvas { context, canvasSize in
                    let s = min(height * 0.35, 14) / 14.0
                    let cx = canvasSize.width / 2
                    let cy = canvasSize.height / 2

                    let stemColor = Color(red: 0.25, green: 0.55, blue: 0.18)
                    let leafColor = Color(red: 0.30, green: 0.62, blue: 0.22)
                    let petalColor = Color(red: 1.0, green: 0.40, blue: 0.55)
                    let petalLight = Color(red: 1.0, green: 0.60, blue: 0.70)
                    let centerColor = Color(red: 1.0, green: 0.82, blue: 0.15)

                    // Stem
                    let stem = Path { p in
                        p.addRect(CGRect(x: cx - 1.5 * s, y: cy + 3 * s, width: 3 * s, height: 10 * s))
                    }
                    context.fill(stem, with: .color(stemColor))

                    // Small leaf on stem
                    let leaf = Path { p in
                        p.addEllipse(in: CGRect(x: cx + 1 * s, y: cy + 6 * s, width: 5 * s, height: 3 * s))
                    }
                    context.fill(leaf, with: .color(leafColor))

                    // Petals (round ellipses arranged in a circle)
                    let petalAngles: [Double] = [0, 72, 144, 216, 288]  // 5 petals evenly spaced
                    let petalRadius: CGFloat = 5 * s
                    let petalW: CGFloat = 5 * s
                    let petalH: CGFloat = 7 * s

                    for (i, angle) in petalAngles.enumerated() {
                        guard i < petalCount else { continue }
                        let rad = angle * .pi / 180
                        let px = cx + cos(rad) * petalRadius - petalW / 2
                        let py = cy - 1 * s + sin(rad) * petalRadius - petalH / 2
                        let petal = Path { p in
                            p.addEllipse(in: CGRect(x: px, y: py, width: petalW, height: petalH))
                        }
                        let c = i % 2 == 0 ? petalColor : petalLight
                        context.fill(petal, with: .color(c))
                    }

                    // Center (always visible)
                    let center = Path { p in
                        p.addEllipse(in: CGRect(x: cx - 3 * s, y: cy - 4 * s, width: 6 * s, height: 6 * s))
                    }
                    context.fill(center, with: .color(centerColor))
                }
                .frame(width: 24, height: 24)
                .scaleEffect(flowerScale)
                .offset(
                    x: flowerX * width,
                    y: -(height * 0.15)
                )
                .transition(.scale.combined(with: .opacity))
                .animation(.easeInOut(duration: 0.2), value: petalCount)
            }

            // Turtle (walks across scene, flips direction)
            ClaudeTurtleIcon(
                size: min(height * 0.75, 28),
                animateLegs: (isWalking && !isSleeping && !isEating) || (isProcessing && !isSleeping && !isEating),
                emotion: emotion,
                isBlinking: isBlinking,
                headExtension: headExtension,
                isSleeping: isSleeping,
                mouthOpen: mouthOpen,
                lookingUp: lookingUp
            )
            .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
            .scaleEffect(x: facingRight ? breathScale : -breathScale, y: breathScale, anchor: .bottom)
            .offset(
                x: walkX * width + (emotion == .sob ? CGFloat(trembleX) : 0) + tailWag,
                y: -(height * 0.25) + CGFloat(sin(bobPhase) * Double(bobAmplitude))
            )
            .rotationEffect(.degrees(swayAngle * swayDeg), anchor: .bottom)
        }
        .frame(width: width, height: height)
        .onReceive(motionTimer) { now in
            // Core motion
            bobPhase += (2.0 * .pi) / (bobSpeed * 30.0)
            swayAngle = sin(bobPhase * 0.7)
            trembleX = emotion == .sob ? Double.random(in: -1.0 ... 1.0) : 0

            // Breathing: subtle shell pulse
            let breathCycle = sin(bobPhase * 0.4) * 0.015
            breathScale = 1.0 + CGFloat(breathCycle)

            // Nature animation clock
            timePhase += 1.0 / 30.0

            // Butterfly movement (gentle drift)
            for i in 0 ..< butterflies.count {
                butterflies[i].x += CGFloat(sin(timePhase * butterflies[i].speed + butterflies[i].phase)) * 0.002
                butterflies[i].y += CGFloat(cos(timePhase * butterflies[i].speed * 0.7 + butterflies[i].phase)) * 0.003
                // Wrap around
                if butterflies[i].x < -0.1 { butterflies[i].x = 1.1 }
                if butterflies[i].x > 1.1 { butterflies[i].x = -0.1 }
                if butterflies[i].y < 0.05 { butterflies[i].y = 0.4 }
                if butterflies[i].y > 0.5 { butterflies[i].y = 0.05 }
            }

            // Heart particles (float up and fade)
            for i in (0 ..< hearts.count).reversed() {
                hearts[i].y -= 0.01
                hearts[i].opacity -= 0.015
                hearts[i].age += 1.0 / 30.0
                if hearts[i].opacity <= 0 {
                    hearts.remove(at: i)
                }
            }

            // Raindrops (fall and respawn)
            if emotion == .sad || emotion == .sob {
                for i in 0 ..< raindrops.count {
                    raindrops[i].y += 2
                    if raindrops[i].y > height {
                        raindrops[i].y = 0
                        raindrops[i].x = CGFloat.random(in: 0 ... width)
                    }
                }
            }

            // Walking logic
            guard !isSleeping else { return }
            guard now > walkPauseUntil else { return }

            if isWalking {
                // Walk speed: slower when idle, faster when processing
                let speed: CGFloat = isProcessing ? 0.0018 : 0.0008
                walkX += walkDirection * speed

                // Edge boundaries (where the visible areas are)
                let leftEdge: CGFloat = -0.45
                let rightEdge: CGFloat = 0.45

                // Hit an edge: pause, then turn around
                if walkX >= rightEdge {
                    walkX = rightEdge
                    isWalking = false
                    // Pause at edge 2-5 seconds (longer on edges = more visible time)
                    let pause = Double.random(in: 2.0 ... 5.0)
                    walkPauseUntil = now.addingTimeInterval(pause)
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(pause))
                        walkDirection = -1
                        facingRight = false
                        isWalking = true
                    }
                } else if walkX <= leftEdge {
                    walkX = leftEdge
                    isWalking = false
                    let pause = Double.random(in: 2.0 ... 5.0)
                    walkPauseUntil = now.addingTimeInterval(pause)
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(pause))
                        walkDirection = 1
                        facingRight = true
                        isWalking = true
                    }
                }

                // When crossing through center (behind notch), speed up
                let centerZone: CGFloat = 0.15
                if abs(walkX) < centerZone {
                    walkX += walkDirection * speed * 2  // 3x speed through center
                }

                // Check if turtle reached the flower (only when walking toward it with full petals)
                if flowerVisible && !flowerEaten && !petalRegrowing && petalCount >= 5 && abs(walkX - flowerX) < 0.06 {
                    eatFlower()
                }
            }
        }
        .onReceive(lifeTimer) { now in
            // Track activity
            if isProcessing {
                lastActivityTime = now
                if isSleeping {
                    // Wake up
                    withAnimation(.easeInOut(duration: 0.5)) { isSleeping = false }
                }
            }

            // Sleep check
            if !isProcessing && now.timeIntervalSince(lastActivityTime) > sleepThreshold && !isSleeping {
                withAnimation(.easeInOut(duration: 1.0)) { isSleeping = true }
            }

            // Blinking (every 3-6 seconds, 150ms blink)
            if !isSleeping && !isBlinking && Int.random(in: 0 ..< 8) == 0 {
                isBlinking = true
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(150))
                    isBlinking = false
                }
            }

            // Hearts when happy
            if emotion == .happy && !isSleeping && Int.random(in: 0 ..< 4) == 0 {
                hearts.append((
                    x: CGFloat(walkX) + 0.5 + CGFloat.random(in: -0.02 ... 0.02),
                    y: 0.6,
                    opacity: 0.9,
                    age: 0
                ))
                // Cap at 5 hearts
                if hearts.count > 5 { hearts.removeFirst() }
            }

            // Rain management
            if (emotion == .sad || emotion == .sob) && raindrops.count < 15 {
                for _ in 0 ..< 3 {
                    raindrops.append((
                        x: CGFloat.random(in: 0 ... max(width, 1)),
                        y: CGFloat.random(in: 0 ... max(height, 1))
                    ))
                }
            } else if emotion != .sad && emotion != .sob && !raindrops.isEmpty {
                raindrops.removeAll()
            }

            // Look up at user occasionally (breaks fourth wall)
            if !isSleeping && !isEating && !lookingUp && Int.random(in: 0 ..< 40) == 0 {
                lookingUp = true
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(Double.random(in: 1.0 ... 2.0)))
                    lookingUp = false
                }
            }

            // Idle fidgets (random head movements and tail wags)
            if !isProcessing && !isSleeping {
                // Head peek (occasionally extend/retract)
                if Int.random(in: 0 ..< 20) == 0 {
                    let target = CGFloat.random(in: -2 ... 3)
                    withAnimation(.easeInOut(duration: 0.4)) { headExtension = target }
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(800))
                        withAnimation(.easeInOut(duration: 0.3)) { headExtension = 0 }
                    }
                }

                // Tail wag (small horizontal shift)
                if Int.random(in: 0 ..< 25) == 0 {
                    withAnimation(.easeInOut(duration: 0.15)) { tailWag = CGFloat.random(in: -0.5 ... 0.5) }
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(300))
                        withAnimation(.easeInOut(duration: 0.15)) { tailWag = 0 }
                    }
                }
            }
        }
        .onAppear {
            // Always have a flower on the scene
            if !flowerVisible {
                spawnFlower()
            }
            // Spawn 2-3 butterflies
            if butterflies.isEmpty {
                for _ in 0 ..< Int.random(in: 2 ... 3) {
                    butterflies.append((
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
            if nowProcessing && isSleeping {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isSleeping = false }
            }
            lastActivityTime = Date()

            // Spawn a new flower if there isn't one
            if nowProcessing && !flowerVisible {
                spawnFlower()
            }
        }
        .onChange(of: emotion) { _, newEmotion in
            // Happy bounce reaction
            if newEmotion == .happy {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                    headExtension = 4
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(400))
                    withAnimation(.easeInOut(duration: 0.3)) { headExtension = 0 }
                }
            }
            // Sad: retract head
            if newEmotion == .sad || newEmotion == .sob {
                withAnimation(.easeInOut(duration: 0.5)) { headExtension = -3 }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(1200))
                    withAnimation(.easeInOut(duration: 0.4)) { headExtension = 0 }
                }
            }
        }
    }

    // MARK: - Flower Logic

    private func spawnFlower() {
        // Place flower on a visible edge (randomly left or right)
        let side: CGFloat = Bool.random() ? -1 : 1
        flowerX = side * CGFloat.random(in: 0.38 ... 0.44)
        flowerEaten = false
        petalCount = 5
        petalRegrowing = false
        flowerVisible = true
        flowerScale = 0

        // Grow animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            flowerScale = 1.0
        }
        // Don't redirect turtle -- let him walk naturally and eat when he passes by
    }

    private func eatFlower() {
        guard !flowerEaten else { return }
        flowerEaten = true
        isEating = true
        isWalking = false  // Stop walking to eat

        // Eat petals one by one with mouth chomping
        Task { @MainActor in
            for petal in stride(from: petalCount, to: 0, by: -1) {
                // Open mouth + head forward
                mouthOpen = true
                withAnimation(.spring(response: 0.1, dampingFraction: 0.5)) {
                    headExtension = 3
                }
                try? await Task.sleep(for: .milliseconds(250))

                // Close mouth (chomp!) + remove a petal
                mouthOpen = false
                withAnimation(.easeOut(duration: 0.15)) {
                    petalCount = petal - 1
                }
                withAnimation(.easeOut(duration: 0.1)) {
                    headExtension = 1
                }
                try? await Task.sleep(for: .milliseconds(200))

                // Open mouth again for next bite
                if petal - 1 > 0 {
                    mouthOpen = true
                    try? await Task.sleep(for: .milliseconds(150))
                    mouthOpen = false
                    try? await Task.sleep(for: .milliseconds(100))
                }
            }

            // Done eating
            mouthOpen = false
            withAnimation(.easeOut(duration: 0.2)) { headExtension = 0 }
            isEating = false

            // All petals eaten, turtle walks away
            petalRegrowing = true
            startPetalRegrowth()

            // Walk away from flower
            let awayDirection: CGFloat = walkX > 0 ? -1 : 1
            walkDirection = awayDirection
            facingRight = walkDirection > 0
            isWalking = true
        }
    }

    private func startPetalRegrowth() {
        Task { @MainActor in
            // Wait a bit before regrowing
            try? await Task.sleep(for: .seconds(2.0))

            // Regrow petals one by one
            for p in 1 ... 5 {
                guard flowerVisible && petalRegrowing else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    petalCount = p
                }
                try? await Task.sleep(for: .milliseconds(600))
            }

            // Flower is fully regrown, turtle can come eat it again
            petalRegrowing = false
            flowerEaten = false
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
