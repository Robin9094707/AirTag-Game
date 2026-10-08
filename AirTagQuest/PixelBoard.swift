import SwiftUI

struct QuestPalette {
    let accent: Color
    let accent2: Color
    let enemy: Color
    let floor: Color

    static func forStage(_ stage: Int) -> QuestPalette {
        let palettes: [QuestPalette] = [
            .init(accent: Color(red: 0.22, green: 0.96, blue: 0.98),
                  accent2: Color(red: 0.72, green: 0.34, blue: 1),
                  enemy: Color(red: 1, green: 0.23, blue: 0.48),
                  floor: Color(red: 0.035, green: 0.10, blue: 0.16)),
            .init(accent: Color(red: 0.51, green: 1, blue: 0.54),
                  accent2: Color(red: 0.13, green: 0.8, blue: 0.65),
                  enemy: Color(red: 1, green: 0.34, blue: 0.35),
                  floor: Color(red: 0.04, green: 0.13, blue: 0.10)),
            .init(accent: Color(red: 0.40, green: 0.71, blue: 1),
                  accent2: Color(red: 1, green: 0.71, blue: 0.25),
                  enemy: Color(red: 1, green: 0.27, blue: 0.55),
                  floor: Color(red: 0.04, green: 0.07, blue: 0.16)),
            .init(accent: Color(red: 0.88, green: 0.66, blue: 1),
                  accent2: Color(red: 0.27, green: 0.95, blue: 1),
                  enemy: Color(red: 1, green: 0.35, blue: 0.51),
                  floor: Color(red: 0.11, green: 0.06, blue: 0.16)),
            .init(accent: Color(red: 1, green: 0.79, blue: 0.35),
                  accent2: Color(red: 1, green: 0.39, blue: 0.56),
                  enemy: Color(red: 1, green: 0.14, blue: 0.28),
                  floor: Color(red: 0.15, green: 0.09, blue: 0.07))
        ]
        return palettes[min(max((stage - 1) / 6, 0), palettes.count - 1)]
    }
}

struct PixelBoard: View {
    let mission: Mission
    private var palette: QuestPalette { .forStage(mission.stage) }

    var body: some View {
        Canvas(opaque: true) { context, size in
            let side = min(size.width, size.height)
            let tile = floor(side / CGFloat(Mission.width))
            let origin = CGPoint(
                x: (size.width - tile * CGFloat(Mission.width)) / 2,
                y: (size.height - tile * CGFloat(Mission.height)) / 2
            )
            func cell(_ point: GridPoint, _ inset: CGFloat = 0) -> CGRect {
                CGRect(x: origin.x + CGFloat(point.x) * tile + inset,
                       y: origin.y + CGFloat(point.y) * tile + inset,
                       width: max(1, tile - inset * 2),
                       height: max(1, tile - inset * 2))
            }
            func paint(_ rect: CGRect, _ color: Color) {
                context.fill(Path(rect), with: .color(color))
            }
            paint(CGRect(origin: .zero, size: size), Color(red: 0.02, green: 0.04, blue: 0.09))
            for y in 0..<Mission.height {
                for x in 0..<Mission.width {
                    let point = GridPoint(x: x, y: y)
                    let tileCode = mission.tiles[y * Mission.width + x]
                    switch tileCode {
                    case 1:
                        paint(cell(point), palette.accent.opacity(0.19))
                        paint(cell(point, 2), Color(red: 0.07, green: 0.10, blue: 0.20))
                        paint(CGRect(x: cell(point).minX + 3, y: cell(point).minY + 3,
                                     width: max(2, tile - 6), height: 2),
                              palette.accent.opacity(0.35))
                    case 2:
                        paint(cell(point), palette.floor)
                        paint(cell(point, tile * 0.3), palette.enemy.opacity(0.58))
                        paint(CGRect(x: cell(point).minX, y: cell(point).minY,
                                     width: tile, height: 2), palette.enemy.opacity(0.4))
                    default:
                        paint(cell(point), palette.floor)
                        paint(cell(point, 1), Color(red: 0.035, green: 0.065, blue: 0.12))
                        if (x * 7 + y * 11) % 9 == 0 {
                            paint(CGRect(x: cell(point).midX, y: cell(point).midY,
                                         width: 2, height: 2), palette.accent.opacity(0.2))
                        }
                    }
                }
            }
            // The portal turns green only once every signal and guardian is cleared.
            let exitRect = cell(mission.exit, 2)
            let portal = mission.portalReady ? Color.green : palette.accent2.opacity(0.55)
            context.stroke(Path(ellipseIn: exitRect), with: .color(portal),
                           lineWidth: max(2, tile * 0.13))
            paint(CGRect(x: exitRect.midX - 2, y: exitRect.midY - 2,
                         width: 4, height: 4), portal)
            for position in mission.signals {
                let r = cell(position, tile * 0.19)
                paint(r, palette.accent.opacity(0.30))
                paint(r.insetBy(dx: tile * 0.13, dy: tile * 0.13), palette.accent)
                paint(CGRect(x: r.minX, y: r.minY, width: tile * 0.19,
                             height: tile * 0.19), .white)
            }
            for position in mission.batteries {
                let r = cell(position, tile * 0.23)
                paint(r, Color(red: 0.15, green: 0.8, blue: 0.97))
                paint(CGRect(x: r.midX - tile * 0.05, y: r.minY - 2,
                             width: tile * 0.1, height: 2), .white)
                paint(r.insetBy(dx: tile * 0.13, dy: tile * 0.10),
                      Color(red: 0.02, green: 0.20, blue: 0.36))
            }
            for position in mission.repairs {
                let r = cell(position, tile * 0.23)
                paint(r, Color(red: 0.95, green: 0.3, blue: 0.5))
                paint(CGRect(x: r.midX - 2, y: r.minY + 2,
                             width: 4, height: r.height - 4), .white)
                paint(CGRect(x: r.minX + 2, y: r.midY - 2,
                             width: r.width - 4, height: 4), .white)
            }
            for enemy in mission.enemies {
                let r = cell(enemy.location, enemy.isBoss ? tile * 0.06 : tile * 0.18)
                paint(r, palette.enemy.opacity(enemy.stunned > 0 ? 0.45 : 0.94))
                paint(r.insetBy(dx: tile * 0.14, dy: tile * 0.14),
                      Color(red: 0.20, green: 0.03, blue: 0.14))
                paint(CGRect(x: r.minX + r.width * 0.22, y: r.minY + r.height * 0.3,
                             width: 3, height: 3), .white)
                paint(CGRect(x: r.maxX - r.width * 0.3, y: r.minY + r.height * 0.3,
                             width: 3, height: 3), .white)
                if enemy.isBoss {
                    context.stroke(Path(r), with: .color(.yellow), lineWidth: 2)
                }
            }
            let playerRect = cell(mission.player, tile * 0.10)
            context.fill(Path(ellipseIn: playerRect), with: .color(.white.opacity(0.28)))
            context.fill(Path(ellipseIn: playerRect.insetBy(dx: tile * 0.11,
                                                            dy: tile * 0.11)),
                         with: .color(.white))
            context.fill(Path(ellipseIn: playerRect.insetBy(dx: tile * 0.27,
                                                            dy: tile * 0.27)),
                         with: .color(Color(red: 0.17, green: 0.25, blue: 0.36)))
            paint(CGRect(x: playerRect.minX + tile * 0.18,
                         y: playerRect.minY + tile * 0.16,
                         width: tile * 0.16, height: tile * 0.09), .white)
            if mission.pulseFlash {
                let radius = tile * CGFloat(2.4)
                let ring = CGRect(x: playerRect.midX - radius, y: playerRect.midY - radius,
                                  width: radius * 2, height: radius * 2)
                context.stroke(Path(ellipseIn: ring), with: .color(palette.accent),
                               lineWidth: 3)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(palette.accent.opacity(0.4), lineWidth: 1.5)
        }
        .shadow(color: palette.accent.opacity(0.23), radius: 20, y: 4)
        .accessibilityLabel("Retro maze. \(mission.signals.count) pings remain. \(mission.enemies.count) enemies.")
    }
}
