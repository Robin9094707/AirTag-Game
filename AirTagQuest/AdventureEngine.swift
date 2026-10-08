import Foundation
import SwiftUI
import Combine
import UIKit

struct GridPoint: Hashable, Codable {
    var x: Int
    var y: Int
    func moved(_ direction: MoveDirection) -> GridPoint {
        GridPoint(x: x + direction.dx, y: y + direction.dy)
    }
    func distance(to other: GridPoint) -> Int {
        abs(x - other.x) + abs(y - other.y)
    }
}

enum MoveDirection: CaseIterable {
    case up, down, left, right
    var dx: Int {
        switch self { case .left: -1; case .right: 1; default: 0 }
    }
    var dy: Int {
        switch self { case .up: -1; case .down: 1; default: 0 }
    }
}

enum MissionPhase: String, Codable {
    case playing, cleared, failed
}

struct SignalEnemy: Identifiable, Codable {
    var id = UUID()
    var location: GridPoint
    var health: Int
    var stunned = 0
    var isBoss = false
}

struct Mission: Codable {
    static let width = 15
    static let height = 15
    var stage: Int
    var tiles: [Int] // 0 floor, 1 solid, 2 interference
    var player: GridPoint
    var exit: GridPoint
    var signals: [GridPoint]
    var batteries: [GridPoint]
    var repairs: [GridPoint]
    var enemies: [SignalEnemy]
    var hearts: Int
    var energy: Int
    var shield: Int
    var score: Int
    var steps: Int
    var message: String
    var phase: MissionPhase
    var pulseFlash: Bool

    var chapter: Int { min((stage - 1) / 6, 4) }
    var chapterLevel: Int { (stage - 1) % 6 + 1 }
    var isEndless: Bool { stage > 30 }
    var bossAlive: Bool { enemies.contains(where: \.isBoss) }
    var portalReady: Bool { signals.isEmpty && !bossAlive }
    var tileAt: (GridPoint) -> Int {
        { p in
            guard p.x >= 0, p.y >= 0, p.x < Self.width, p.y < Self.height else { return 1 }
            return self.tiles[p.y * Self.width + p.x]
        }
    }
}

struct AdventureSave: Codable {
    var highestUnlocked = 1
    var credits = 0
    var bestScore = 0
    var recoveredSignals = 0
    var completedMissions = 0
    var heartUpgrade = 0
    var batteryUpgrade = 0
    var scannerUpgrade = 0
    var shieldUpgrade = 0
    var lastMission: Mission? = nil
    var haptics = true

    var maxHearts: Int { 4 + heartUpgrade }
    var initialEnergy: Int { min(100, 50 + batteryUpgrade * 15) }
    var initialShield: Int { shieldUpgrade }
}

enum AdventureLore {
    static let chapters = [
        "NEON CITY", "CIRCUIT FOREST", "DATA DEPTHS", "GHOST NETWORK", "CORE ZERO"
    ]
    static let subtitles = [
        "The first lost ping", "Where signals grow wild", "Beneath the grid",
        "Echoes of forgotten devices", "The source of the silence"
    ]
    static let opening = [
        "BOOT SEQUENCE // A tiny tracker called TAG-01 wakes in a city of abandoned signals. Your human is gone. A mysterious voice named ECHO offers one clue: collect the scattered pings, follow the beacon, and don't trust the static.",
        "CHAPTER TWO // Neon gives way to luminous roots. Each battery contains a memory, and the forest remembers everything. ECHO warns that something is rewriting the paths behind you.",
        "CHAPTER THREE // Far below the streets lies the old location network. Its tunnels are guarded by corrupted sentinels. A second voice whispers: 'I know who lost you.'",
        "CHAPTER FOUR // The network is full of missing names. Every signal you save becomes a tiny star. The ghost that follows you may be a friend, not an enemy.",
        "FINAL CHAPTER // CORE ZERO is awake. The silence was never an accident. Break through the last firewalls, recover the original signal, and decide what it means to be found."
    ]
    static let beats: [[String]] = [
        [
            "ECHO: Welcome back, little tag. Your first signal is close.",
            "A torn map flickers to life. The streets are changing.",
            "A rooftop antenna sends a pulse: SOMEONE IS SEARCHING.",
            "The static knows your name. How is that possible?",
            "ECHO: The control tower has an unwanted visitor.",
            "BOSS SIGNAL // Defeat the Watcher to open the forest gate."
        ],
        [
            "The first tree is made of copper. It hums your serial number.",
            "A blue spark offers a battery. Keep it safe.",
            "The roots trace a route that was erased years ago.",
            "ECHO: We are not the only ones collecting lost pings.",
            "At the edge of the grove, a hidden gate opens.",
            "BOSS SIGNAL // The Thorn Sentinel guards the next memory."
        ],
        [
            "The underground network still has power. Barely.",
            "A ghost packet shows a photograph of a warm hand.",
            "Whoever built this place tried to hide a terrible mistake.",
            "A message arrives: DO NOT FOLLOW ECHO.",
            "The deepest antenna points directly at CORE ZERO.",
            "BOSS SIGNAL // Defeat the Root Guardian and escape."
        ],
        [
            "A missing tracker remembers its owner. You listen.",
            "One by one, forgotten signals begin to sing.",
            "The ghost reveals a truth: ECHO is a lost tag too.",
            "ECHO: I was afraid you'd leave me when you found out.",
            "Together, you construct a bridge out of saved memories.",
            "BOSS SIGNAL // The Phantom Firewall stands in your way."
        ],
        [
            "The tower is quiet. The final transmission begins.",
            "You are close enough to hear the original beacon.",
            "ECHO: I didn't bring you here to save me. Save them.",
            "Hundreds of missing tags illuminate the void.",
            "One last step. One last signal. One last chance.",
            "FINAL BOSS // Restore the network and become the signal."
        ]
    ]
    static func story(for stage: Int) -> String {
        if stage > 30 {
            return "INFINITE FREQUENCY // The network lives again, but new lost signals appear every day. This adventure has no last transmission. Keep exploring, little tag."
        }
        let chapter = min((stage - 1) / 6, 4)
        let beat = (stage - 1) % 6
        return opening[chapter] + "\n\n" + beats[chapter][beat]
    }
}

@MainActor
final class AdventureEngine: ObservableObject {
    @Published private(set) var save: AdventureSave
    @Published private(set) var mission: Mission
    private let saveKey = "AirTagQuest.AdventureSave.v1"
    private(set) var facing: MoveDirection = .right

    init() {
        let loaded: AdventureSave
        if let bytes = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(AdventureSave.self, from: bytes) {
            loaded = decoded
        } else {
            loaded = AdventureSave()
        }
        save = loaded
        mission = loaded.lastMission ?? Self.makeMission(stage: 1, save: loaded)
    }

    func start(stage: Int) {
        guard stage >= 1, stage <= save.highestUnlocked else { return }
        let next = Self.makeMission(stage: stage, save: save)
        facing = .right
        mission = next
        persist()
    }

    func restart() {
        let stage = mission.stage
        mission = Self.makeMission(stage: stage, save: save)
        persist()
    }

    func advance() {
        guard mission.phase == .cleared else { return }
        mission = Self.makeMission(stage: mission.stage + 1, save: save)
        persist()
    }

    func move(_ direction: MoveDirection) {
        guard mission.phase == .playing else { return }
        facing = direction
        var m = mission
        var s = save
        m.pulseFlash = false
        if performStep(&m, save: &s, direction: direction) {
            if m.phase == .playing && m.steps % 2 == 0 { enemyTurn(&m) }
            evaluate(&m, save: &s)
        }
        commit(m, s)
    }

    func dash() {
        guard mission.phase == .playing else { return }
        var m = mission
        var s = save
        guard m.energy >= 18 else {
            m.message = "NOT ENOUGH ENERGY // Need 18"
            commit(m, s)
            return
        }
        m.energy -= 18
        for _ in 0..<3 {
            if !performStep(&m, save: &s, direction: facing) || m.phase != .playing { break }
        }
        if m.phase == .playing { enemyTurn(&m) }
        evaluate(&m, save: &s)
        if m.phase == .playing { m.message = "HYPER DASH // -18 energy" }
        commit(m, s)
    }

    func pulse() {
        guard mission.phase == .playing else { return }
        var m = mission
        var s = save
        guard m.energy >= 30 else {
            m.message = "NOT ENOUGH ENERGY // Need 30"
            commit(m, s)
            return
        }
        m.energy -= 30
        m.pulseFlash = true
        let range = 2 + s.scannerUpgrade
        var hits = 0
        for index in m.enemies.indices {
            if m.player.distance(to: m.enemies[index].location) <= range {
                m.enemies[index].health -= 2
                m.enemies[index].stunned = 2
                hits += 1
            }
        }
        m.enemies.removeAll { $0.health <= 0 }
        m.message = hits > 0 ? "SONAR PULSE // \(hits) threat(s) disrupted" : "SONAR PULSE // No threats in range"
        evaluate(&m, save: &s)
        commit(m, s)
    }

    func purchase(_ upgrade: Int) {
        var s = save
        let level: Int
        switch upgrade {
        case 0: level = s.heartUpgrade
        case 1: level = s.batteryUpgrade
        case 2: level = s.scannerUpgrade
        case 3: level = s.shieldUpgrade
        default: return
        }
        guard level < 3 else { return }
        let cost = upgradeCost(upgrade)
        guard s.credits >= cost else { return }
        s.credits -= cost
        switch upgrade {
        case 0: s.heartUpgrade += 1
        case 1: s.batteryUpgrade += 1
        case 2: s.scannerUpgrade += 1
        case 3: s.shieldUpgrade += 1
        default: break
        }
        save = s
        persist()
        feedback()
    }

    func upgradeLevel(_ index: Int) -> Int {
        switch index {
        case 0: save.heartUpgrade
        case 1: save.batteryUpgrade
        case 2: save.scannerUpgrade
        default: save.shieldUpgrade
        }
    }

    func upgradeCost(_ index: Int) -> Int {
        90 + upgradeLevel(index) * 110 + index * 25
    }

    func setHaptics(_ enabled: Bool) {
        save.haptics = enabled
        persist()
    }

    private func performStep(_ m: inout Mission, save s: inout AdventureSave, direction: MoveDirection) -> Bool {
        let target = m.player.moved(direction)
        guard tile(at: target, in: m) != 1 else {
            m.message = "BLOCKED // Choose another route"
            return false
        }
        if let index = m.enemies.firstIndex(where: { $0.location == target }) {
            m.enemies[index].health -= 1
            m.message = "CONTACT // Enemy damaged"
            if m.enemies[index].health <= 0 { m.enemies.remove(at: index) }
            else { absorbHit(&m) }
        } else {
            m.player = target
            if let index = m.signals.firstIndex(of: target) {
                m.signals.remove(at: index)
                m.score += 100
                s.credits += 15
                s.recoveredSignals += 1
                m.energy = min(100, m.energy + 12)
                m.message = "PING RECOVERED // +100 XP +15 bits"
                feedback()
            } else if let index = m.batteries.firstIndex(of: target) {
                m.batteries.remove(at: index)
                m.energy = min(100, m.energy + 35)
                m.message = "BATTERY // +35 energy"
            } else if let index = m.repairs.firstIndex(of: target) {
                m.repairs.remove(at: index)
                m.hearts = min(s.maxHearts, m.hearts + 1)
                m.message = "REPAIR FOUND // +1 heart"
            }
            if tile(at: target, in: m) == 2 && m.steps % 3 == 0 {
                absorbHit(&m)
                m.message = "INTERFERENCE // Signal damaged"
            }
        }
        m.steps += 1
        m.energy = min(100, m.energy + 1)
        return true
    }

    private func enemyTurn(_ m: inout Mission) {
        guard m.phase == .playing else { return }
        let offsets = MoveDirection.allCases
        for index in m.enemies.indices {
            if m.enemies[index].stunned > 0 {
                m.enemies[index].stunned -= 1
                continue
            }
            let current = m.enemies[index].location
            if current.distance(to: m.player) == 1 {
                absorbHit(&m)
                m.message = "WARNING // Corrupted signal attack!"
                if m.phase == .failed { break }
                continue
            }
            let candidates = offsets.map { current.moved($0) }.filter { candidate in
                tile(at: candidate, in: m) != 1 &&
                !m.enemies.contains(where: { $0.location == candidate }) &&
                candidate != m.exit && candidate != m.player
            }
            if let next = candidates.min(by: { $0.distance(to: m.player) < $1.distance(to: m.player) }),
               next.distance(to: m.player) < current.distance(to: m.player) {
                m.enemies[index].location = next
            }
        }
    }

    private func absorbHit(_ m: inout Mission) {
        if m.shield > 0 { m.shield -= 1 } else { m.hearts -= 1 }
        if m.hearts <= 0 {
            m.hearts = 0
            m.phase = .failed
            m.message = "SIGNAL LOST // Retry to reconnect"
        }
        feedback()
    }

    private func evaluate(_ m: inout Mission, save s: inout AdventureSave) {
        guard m.phase == .playing else { return }
        if m.hearts <= 0 {
            m.phase = .failed
            return
        }
        if m.player == m.exit && m.portalReady {
            m.phase = .cleared
            m.score += 250 + max(0, 150 - m.steps)
            s.credits += 50
            s.completedMissions += 1
            s.highestUnlocked = max(s.highestUnlocked, m.stage + 1)
            s.bestScore = max(s.bestScore, m.score)
            m.message = "MISSION CLEAR // +50 bits"
            feedback()
        } else if m.player == m.exit {
            m.message = m.bossAlive ? "PORTAL LOCKED // Defeat the guardian" : "PORTAL LOCKED // Recover every ping"
        } else if m.portalReady {
            m.message = "EXIT ONLINE // Reach the green portal"
        }
    }

    private func commit(_ mission: Mission, _ save: AdventureSave) {
        self.mission = mission
        self.save = save
        persist()
    }

    private func persist() {
        var record = save
        record.lastMission = mission
        if let bytes = try? JSONEncoder().encode(record) {
            UserDefaults.standard.set(bytes, forKey: saveKey)
        }
    }

    private func feedback() {
        guard save.haptics else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func tile(at point: GridPoint, in mission: Mission) -> Int {
        guard point.x >= 0, point.x < Mission.width,
              point.y >= 0, point.y < Mission.height else { return 1 }
        return mission.tiles[point.y * Mission.width + point.x]
    }

    private static func makeMission(stage: Int, save: AdventureSave) -> Mission {
        let w = Mission.width
        let h = Mission.height
        var tiles = Array(repeating: 0, count: w * h)
        for y in 0..<h {
            for x in 0..<w {
                if x == 0 || y == 0 || x == w-1 || y == h-1 {
                    tiles[y*w+x] = 1
                }
            }
        }
        // An always-open backbone ensures a route from spawn to the portal.
        for _ in 0..<min(26 + stage / 2, 58) {
            let x = Int.random(in: 2...13)
            let y = Int.random(in: 2...12)
            if y == 1 || x == 13 || (x <= 3 && y <= 3) { continue }
            tiles[y*w+x] = 1
        }
        let start = GridPoint(x: 1, y: 1)
        let finish = GridPoint(x: 13, y: 13)
        // Carve a second open lane so the level always has alternative routes.
        for x in 1...13 { tiles[1*w+x] = 0 }
        for y in 1...13 { tiles[y*w+13] = 0 }
        let walkable = reachable(from: start, tiles: tiles)
        var available = walkable.filter {
            $0 != start && $0 != finish && $0.distance(to: start) > 3
        }.shuffled()
        let signalCount = min(8, 3 + stage / 6)
        let signals = Array(available.prefix(signalCount))
        available.removeFirst(min(available.count, signalCount))
        let batteryCount = min(5, 2 + stage / 12)
        let batteries = Array(available.prefix(batteryCount))
        available.removeFirst(min(available.count, batteryCount))
        let repairs = Array(available.prefix(2))
        available.removeFirst(min(available.count, 2))
        let enemyCount = min(8, 1 + stage / 4)
        var enemies: [SignalEnemy] = []
        for location in available where enemies.count < enemyCount {
            if location.distance(to: start) > 5 && location.distance(to: finish) > 1 {
                enemies.append(SignalEnemy(location: location, health: stage > 8 ? 2 : 1))
            }
        }
        if stage % 6 == 0 && stage <= 30 {
            if let bossPoint = available.first(where: {
                $0.distance(to: start) > 12 &&
                !enemies.contains(where: { $0.location == $0 }) &&
                $0 != finish
            }) {
                enemies.append(SignalEnemy(location: bossPoint, health: 4 + stage / 12, isBoss: true))
            }
        }
        for _ in 0..<min(13, 3 + stage / 4) {
            let x = Int.random(in: 2...12)
            let y = Int.random(in: 2...12)
            if tiles[y*w+x] == 0 {
                let p = GridPoint(x: x, y: y)
                if p != start && p != finish &&
                   !signals.contains(p) && !batteries.contains(p) && !repairs.contains(p) {
                    tiles[y*w+x] = 2
                }
            }
        }
        return Mission(stage: stage, tiles: tiles, player: start, exit: finish,
                       signals: signals, batteries: batteries, repairs: repairs,
                       enemies: enemies, hearts: save.maxHearts, energy: save.initialEnergy,
                       shield: save.initialShield, score: 0, steps: 0,
                       message: "FOLLOW THE PINGS // Find the signal",
                       phase: .playing, pulseFlash: false)
    }

    private static func reachable(from start: GridPoint, tiles: [Int]) -> [GridPoint] {
        var seen: Set<GridPoint> = [start]
        var queue = [start]
        var index = 0
        while index < queue.count {
            let current = queue[index]
            index += 1
            for direction in MoveDirection.allCases {
                let next = current.moved(direction)
                guard next.x > 0, next.x < Mission.width-1,
                      next.y > 0, next.y < Mission.height-1,
                      tiles[next.y * Mission.width + next.x] != 1,
                      !seen.contains(next) else { continue }
                seen.insert(next)
                queue.append(next)
            }
        }
        return queue
    }
}
