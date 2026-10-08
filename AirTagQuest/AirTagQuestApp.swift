import SwiftUI

@main
struct AirTagQuestApp: App {
    var body: some Scene {
        WindowGroup {
            AdventureView()
                .preferredColorScheme(.dark)
        }
    }
}

private enum QuestPage {
    case home, game, missions, upgrades, settings
}

private struct GlassSurface: ViewModifier {
    var corner: CGFloat = 22
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: corner))
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: corner))
                .overlay(RoundedRectangle(cornerRadius: corner)
                    .strokeBorder(.white.opacity(0.16), lineWidth: 1))
        }
    }
}

private extension View {
    func questGlass(_ radius: CGFloat = 22) -> some View {
        modifier(GlassSurface(corner: radius))
    }
}

struct AdventureView: View {
    @StateObject private var engine = AdventureEngine()
    @State private var page: QuestPage = .home
    @State private var showingStory = false

    private var accent: Color { QuestPalette.forStage(engine.mission.stage).accent }

    var body: some View {
        ZStack {
            CosmicBackground(accent: accent)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 19) {
                    header
                    switch page {
                    case .home: home
                    case .game: game
                    case .missions: missions
                    case .upgrades: upgrades
                    case .settings: settings
                    }
                    footer
                }
                .frame(maxWidth: 570)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 17)
                .padding(.top, 12)
                .padding(.bottom, 38)
            }
            if showingStory {
                storyOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingStory)
        .tint(accent)
    }

    private var header: some View {
        HStack(alignment: .center) {
            Button {
                showingStory = false
                page = .home
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 21, weight: .black))
                        .foregroundStyle(accent)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("AIRTAG")
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                        Text("LOST SIGNAL")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(accent)
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundStyle(.yellow)
                Text("\(engine.save.credits)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .questGlass(20)
        }
    }

    private var home: some View {
        VStack(spacing: 18) {
            VStack(spacing: 16) {
                Text("A TINY TAG.\nA HUGE UNIVERSE.")
                    .font(.system(size: 29, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .tracking(-0.7)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)
                TagEmblem()
                    .frame(height: 174)
                Text("An original pixel adventure about one lost tracker, five mysterious worlds and a signal that refuses to disappear.")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    stat("30+", caption: "MISSIONS")
                    stat("05", caption: "WORLDS")
                    stat("∞", caption: "ENDLESS")
                }
                QuestAction(title: engine.save.lastMission == nil ? "BEGIN ADVENTURE" : "CONTINUE ADVENTURE",
                            symbol: "play.fill", color: accent) {
                    page = .game
                    showingStory = engine.mission.steps == 0
                }
            }
            .padding(21)
            .questGlass(28)

            HStack(spacing: 10) {
                menuTile("MISSIONS", symbol: "map.fill", color: .cyan) { page = .missions }
                menuTile("UPGRADES", symbol: "bolt.shield.fill", color: .yellow) { page = .upgrades }
                menuTile("SETTINGS", symbol: "gearshape.fill", color: .white) { page = .settings }
            }
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("YOUR SIGNAL LOG")
                HStack {
                    progressStat("UNLOCKED", "\(min(engine.save.highestUnlocked, 31))/31")
                    Spacer()
                    progressStat("RECOVERED", "\(engine.save.recoveredSignals)")
                    Spacer()
                    progressStat("BEST SCORE", "\(engine.save.bestScore)")
                }
                Rectangle()
                    .fill(.white.opacity(0.1))
                    .frame(height: 1)
                Text("The signal is out there. Every recovered ping brings TAG-01 closer to home.")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .padding(19)
            .questGlass()
        }
    }

    private var game: some View {
        VStack(spacing: 12) {
            HStack {
                Button { page = .home } label: {
                    Label("MENU", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)
                Spacer()
                Text(engine.mission.isEndless ? "INFINITE FREQUENCY" :
                        "WORLD \(engine.mission.chapter + 1) / MISSION \(engine.mission.chapterLevel)")
                    .foregroundStyle(accent)
            }
            .font(.system(size: 11, weight: .black, design: .monospaced))
            .padding(.top, 4)

            VStack(spacing: 7) {
                HStack {
                    Text(AdventureLore.chapters[engine.mission.chapter])
                        .font(.system(size: 18, weight: .heavy, design: .monospaced))
                    Spacer()
                    Label("\(engine.mission.score)", systemImage: "sparkle")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.yellow)
                }
                HStack(spacing: 8) {
                    Label("\(engine.mission.hearts)", systemImage: "heart.fill")
                        .foregroundStyle(.pink)
                    Label("\(engine.mission.energy)%", systemImage: "bolt.fill")
                        .foregroundStyle(.cyan)
                    Label("\(engine.mission.shield)", systemImage: "shield.fill")
                        .foregroundStyle(.mint)
                    Spacer()
                    Text("PING \(engine.mission.signals.count)")
                        .foregroundStyle(accent)
                }
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.1))
                        Capsule().fill(LinearGradient(colors: [.cyan, accent], startPoint: .leading,
                                                    endPoint: .trailing))
                            .frame(width: g.size.width * CGFloat(engine.mission.energy) / 100)
                    }
                }
                .frame(height: 5)
            }
            .padding(13)
            .questGlass(16)

            PixelBoard(mission: engine.mission)
                .frame(maxWidth: 485)
                .gesture(
                    DragGesture(minimumDistance: 17)
                        .onEnded { movement in
                            let dx = movement.translation.width
                            let dy = movement.translation.height
                            if abs(dx) > abs(dy) {
                                engine.move(dx < 0 ? .left : .right)
                            } else {
                                engine.move(dy < 0 ? .up : .down)
                            }
                        }
                )

            HStack(spacing: 7) {
                Image(systemName: engine.mission.portalReady ? "checkmark.circle.fill" : "waveform.path")
                    .foregroundStyle(engine.mission.portalReady ? .green : accent)
                Text(engine.mission.message)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .questGlass(15)

            if engine.mission.phase == .playing {
                HStack(alignment: .center, spacing: 15) {
                    dpad
                    Spacer(minLength: 4)
                    VStack(spacing: 11) {
                        Button { engine.pulse() } label: {
                            actionCircle("SONAR", symbol: "waveform.path", tint: .cyan)
                        }
                        .buttonStyle(.plain)
                        Button { engine.dash() } label: {
                            actionCircle("DASH", symbol: "bolt.fill", tint: .orange)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                Text("SWIPE THE MAP OR USE THE D-PAD  •  SONAR 30⚡  •  DASH 18⚡")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.48))
                    .multilineTextAlignment(.center)
            } else {
                resultPanel
            }
            HStack(spacing: 9) {
                miniAction("STORY", symbol: "text.book.closed") { showingStory = true }
                miniAction("RESTART", symbol: "arrow.clockwise") { engine.restart() }
                miniAction("SHOP", symbol: "cart") { page = .upgrades }
            }
        }
    }

    private var dpad: some View {
        VStack(spacing: 4) {
            directionButton(.up, symbol: "chevron.up")
            HStack(spacing: 4) {
                directionButton(.left, symbol: "chevron.left")
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white.opacity(0.08))
                    .frame(width: 55, height: 48)
                    .overlay(Image(systemName: "circle.hexagongrid").foregroundStyle(accent.opacity(0.4)))
                directionButton(.right, symbol: "chevron.right")
            }
            directionButton(.down, symbol: "chevron.down")
        }
    }

    private func directionButton(_ direction: MoveDirection, symbol: String) -> some View {
        Button { engine.move(direction) } label: {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 55, height: 48)
                .questGlass(12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Move \(symbol.replacingOccurrences(of: "chevron.", with: ""))")
    }

    private func actionCircle(_ name: String, symbol: String, tint: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(tint)
            Text(name)
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
        }
        .frame(width: 91, height: 65)
        .questGlass(17)
    }

    private var resultPanel: some View {
        VStack(spacing: 13) {
            Image(systemName: engine.mission.phase == .cleared ? "checkmark.seal.fill" : "wifi.slash")
                .font(.system(size: 38))
                .foregroundStyle(engine.mission.phase == .cleared ? .green : .pink)
            Text(engine.mission.phase == .cleared ? "SIGNAL RESTORED" : "SIGNAL LOST")
                .font(.system(size: 22, weight: .black, design: .monospaced))
            Text(engine.mission.phase == .cleared ?
                 "Mission clear! 50 bonus bits earned. The next transmission awaits." :
                 "Your connection faded in the static. Reboot TAG-01 and try another route.")
                .multilineTextAlignment(.center)
                .font(.system(size: 12, design: .monospaced))
            QuestAction(title: engine.mission.phase == .cleared ? "NEXT TRANSMISSION" : "RETRY MISSION",
                        symbol: "arrow.right.circle.fill", color: accent) {
                if engine.mission.phase == .cleared {
                    engine.advance()
                    showingStory = true
                } else {
                    engine.restart()
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .questGlass()
    }

    private var missions: some View {
        VStack(alignment: .leading, spacing: 15) {
            pageHeading("MISSION SELECT", detail: "Thirty handcrafted story beats across five worlds, followed by procedurally generated endless missions.")
            ForEach(0..<5, id: \.self) { chapter in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: ["building.2.crop.circle", "leaf.circle", "externaldrive",
                                           "moon.stars.circle", "sparkles"][chapter])
                            .font(.system(size: 22))
                            .foregroundStyle(QuestPalette.forStage(chapter * 6 + 1).accent)
                        VStack(alignment: .leading) {
                            Text("0\(chapter + 1) // \(AdventureLore.chapters[chapter])")
                                .font(.system(size: 15, weight: .heavy, design: .monospaced))
                            Text(AdventureLore.subtitles[chapter])
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        Spacer()
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 6), spacing: 7) {
                        ForEach(1...6, id: \.self) { level in
                            let stage = chapter * 6 + level
                            Button {
                                engine.start(stage: stage)
                                page = .game
                                showingStory = true
                            } label: {
                                Text(stage <= engine.save.highestUnlocked ? "\(level)" : "🔒")
                                    .font(.system(size: 15, weight: .black, design: .monospaced))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 43)
                                    .background(stage < engine.save.highestUnlocked ?
                                                Color.green.opacity(0.22) : .white.opacity(0.07),
                                                in: RoundedRectangle(cornerRadius: 11))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 11)
                                            .stroke(stage == engine.save.highestUnlocked ? accent : .white.opacity(0.08),
                                                    lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                            .disabled(stage > engine.save.highestUnlocked)
                        }
                    }
                }
                .padding(16)
                .questGlass(19)
            }
            if engine.save.highestUnlocked > 30 {
                QuestAction(title: "ENTER INFINITE FREQUENCY", symbol: "infinity", color: .green) {
                    engine.start(stage: max(31, engine.save.highestUnlocked))
                    page = .game
                    showingStory = true
                }
            }
            miniAction("BACK TO MAIN MENU", symbol: "house") { page = .home }
        }
    }

    private var upgrades: some View {
        VStack(spacing: 12) {
            pageHeading("THE SIGNAL LAB", detail: "Recovered pings give you bits. Upgrade TAG-01 for longer expeditions; purchases are permanent.")
            HStack {
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                Text("\(engine.save.credits) BITS")
                    .font(.system(size: 23, weight: .black, design: .monospaced))
                Spacer()
            }
            .padding(17)
            .questGlass()
            ForEach(0..<4, id: \.self) { index in
                let names = ["REINFORCED SHELL", "LARGER BATTERY", "SONAR AMPLIFIER", "SIGNAL SHIELD"]
                let captions = ["+1 maximum heart each tier", "+15 starting energy each tier",
                                "+1 sonar detection range each tier", "+1 starting shield each tier"]
                let icons = ["heart.circle.fill", "battery.100percent", "waveform.path.ecg", "shield.lefthalf.filled"]
                HStack(spacing: 13) {
                    Image(systemName: icons[index])
                        .font(.system(size: 27))
                        .foregroundStyle(index == 0 ? .pink : index == 1 ? .cyan : index == 2 ? .purple : .green)
                        .frame(width: 44)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(names[index])
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                        Text(captions[index])
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("TIER \(engine.upgradeLevel(index)) / 3")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(accent)
                    }
                    Spacer(minLength: 0)
                    Button {
                        engine.purchase(index)
                    } label: {
                        Text(engine.upgradeLevel(index) == 3 ? "MAX" : "\(engine.upgradeCost(index))")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 11)
                            .background(accent.opacity(0.25), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(engine.upgradeLevel(index) >= 3 ||
                              engine.save.credits < engine.upgradeCost(index))
                }
                .padding(15)
                .questGlass(20)
            }
            miniAction("BACK TO MAIN MENU", symbol: "house") { page = .home }
        }
    }

    private var settings: some View {
        VStack(spacing: 15) {
            pageHeading("SYSTEM SETTINGS", detail: "Your adventure is saved on this device automatically after every action.")
            VStack(alignment: .leading, spacing: 15) {
                Toggle(isOn: Binding(get: { engine.save.haptics },
                                     set: { engine.setHaptics($0) })) {
                    Label("Haptic feedback", systemImage: "hand.tap")
                }
                .tint(accent)
                Divider()
                Label("Offline, single-player adventure", systemImage: "wifi.slash")
                Divider()
                Label("No location permissions or tracking required", systemImage: "location.slash")
                Divider()
                Label("Local progress and permanent upgrades", systemImage: "square.and.arrow.down")
            }
            .font(.system(size: 13, weight: .medium, design: .monospaced))
            .padding(20)
            .questGlass()
            Text("TAG-01 is a fictional character. This game is not affiliated with Apple and cannot locate a real AirTag.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
            miniAction("BACK TO MAIN MENU", symbol: "house") { page = .home }
        }
    }

    private var storyOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 43))
                    .foregroundStyle(accent)
                Text("INCOMING TRANSMISSION")
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundStyle(accent)
                Text(AdventureLore.story(for: engine.mission.stage))
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .lineSpacing(5)
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                QuestAction(title: "CONNECT TO SIGNAL", symbol: "antenna.radiowaves.left.and.right",
                            color: accent) { showingStory = false }
            }
            .frame(maxWidth: 440)
            .padding(24)
            .questGlass(28)
            .padding(.horizontal, 20)
        }
    }

    private var footer: some View {
        Text("TAG-01  ◇  LOCAL SAVE  ◇  MADE FOR iOS")
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .tracking(1.2)
            .foregroundStyle(.white.opacity(0.37))
            .padding(.top, 9)
    }

    private func stat(_ value: String, caption: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 26, weight: .black, design: .monospaced))
                .foregroundStyle(accent)
            Text(caption)
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundStyle(.white.opacity(0.67))
        }
        .frame(maxWidth: .infinity)
    }

    private func progressStat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 16, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .heavy, design: .monospaced))
            .foregroundStyle(accent)
    }

    private func pageHeading(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 25, weight: .black, design: .rounded))
            Text(detail)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.white.opacity(0.66))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private func menuTile(_ title: String, symbol: String, color: Color,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 11) {
                Image(systemName: symbol)
                    .font(.system(size: 25))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .questGlass(17)
        }
        .buttonStyle(.plain)
    }

    private func miniAction(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .questGlass(12)
        }
        .buttonStyle(.plain)
    }
}

private struct QuestAction: View {
    let title: String
    let symbol: String
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(.black.opacity(0.85))
                .background(
                    LinearGradient(colors: [color, color.opacity(0.76)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .shadow(color: color.opacity(0.33), radius: 13, y: 3)
        }
        .buttonStyle(.plain)
    }
}

private struct CosmicBackground: View {
    let accent: Color
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [
                    Color(red: 0.015, green: 0.035, blue: 0.09),
                    Color(red: 0.055, green: 0.025, blue: 0.12),
                    Color(red: 0.01, green: 0.02, blue: 0.055)
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle()
                    .fill(accent.opacity(0.13))
                    .frame(width: 330, height: 330)
                    .blur(radius: 85)
                    .position(x: geometry.size.width * 0.85, y: 170)
                Circle()
                    .fill(Color.purple.opacity(0.10))
                    .frame(width: 260, height: 260)
                    .blur(radius: 75)
                    .position(x: 20, y: geometry.size.height * 0.77)
                Canvas { context, size in
                    for i in 0..<75 {
                        let x = CGFloat((i * 127 + 31) % 997) / 997 * size.width
                        let y = CGFloat((i * 241 + 77) % 991) / 991 * size.height
                        let radius = CGFloat(i % 3 + 1)
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y,
                                                           width: radius, height: radius)),
                                     with: .color(.white.opacity(i % 4 == 0 ? 0.37 : 0.13)))
                    }
                }
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
}

private struct TagEmblem: View {
    var body: some View {
        ZStack {
            Circle().stroke(.cyan.opacity(0.13), lineWidth: 1).frame(width: 158, height: 158)
            Circle().stroke(.cyan.opacity(0.28), lineWidth: 1).frame(width: 125, height: 125)
            Circle().fill(.cyan.opacity(0.12)).frame(width: 107, height: 107).blur(radius: 24)
            Circle()
                .fill(LinearGradient(colors: [.white, Color(red: 0.49, green: 0.65, blue: 0.77)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 91, height: 91)
                .shadow(color: .cyan.opacity(0.45), radius: 23)
            Circle().fill(Color(red: 0.1, green: 0.15, blue: 0.25))
                .frame(width: 61, height: 61)
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 27, weight: .bold))
                .foregroundStyle(.white)
            ForEach(0..<8, id: \.self) { i in
                Circle().fill(.cyan)
                    .frame(width: 3, height: 3)
                    .offset(y: -79)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
        }
    }
}
