import SwiftUI

/// Native ports of the old web app's illustrated tag art — hand-drawn,
/// architectural line-work and edge-to-edge material hatches — so the tag
/// choices regain their graphic character while keeping the app's clean tiles.

// MARK: - Materiality hatch patterns

/// The eight Materiality textures, drawn as repeating unit cells that run
/// edge-to-edge (matching the web `.sw-art--pattern`). Ported cell-for-cell
/// from the web SVG `<pattern>` definitions.
struct MaterialityPattern: View {
    let id: String          // "Concrete", "Brick", ...
    var ink: Color

    var body: some View {
        Canvas { ctx, size in
            switch id {
            case "Concrete": dots(ctx, size, cell: 6, [(1.5, 1.5, 0.8), (4.5, 3.5, 0.7), (2.2, 4.8, 0.55)])
            case "Stone":    dots(ctx, size, cell: 18, [(3,4,0.6),(10,3,0.55),(14,9,0.65),(6,12,0.6),(12,15,0.55),(2,16,0.6)])
            case "Plaster":  dots(ctx, size, cell: 14, [(3,3,0.7),(9,6,0.6),(5,10,0.6),(11,11,0.7)])
            case "Brick":    brick(ctx, size)
            case "Timber":   timber(ctx, size)
            case "Metal":    metal(ctx, size)
            case "Glass":    glass(ctx, size)
            default:         questionMark(ctx, size)   // "Other"
            }
        }
    }

    /// Tile a filled-dot cell across the whole area.
    private func dots(_ ctx: GraphicsContext, _ size: CGSize, cell: CGFloat,
                      _ pts: [(CGFloat, CGFloat, CGFloat)]) {
        tile(size, cell: cell) { ox, oy in
            for p in pts {
                let r = p.2
                let rect = CGRect(x: ox + p.0 - r, y: oy + p.1 - r, width: r * 2, height: r * 2)
                ctx.fill(Path(ellipseIn: rect), with: .color(ink))
            }
        }
    }

    private func brick(_ ctx: GraphicsContext, _ size: CGSize) {
        tile(size, cell: CGSize(width: 14, height: 8)) { ox, oy in
            for r in [CGRect(x: 0, y: 0, width: 13, height: 3),
                      CGRect(x: -7, y: 4, width: 13, height: 3),
                      CGRect(x: 7, y: 4, width: 13, height: 3)] {
                let rr = CGRect(x: ox + r.minX, y: oy + r.minY, width: r.width, height: r.height)
                ctx.stroke(Path(rr), with: .color(ink), lineWidth: 0.9)
            }
        }
    }

    private func timber(_ ctx: GraphicsContext, _ size: CGSize) {
        tile(size, cell: CGSize(width: 20, height: 6)) { ox, oy in
            var top = Path()
            top.move(to: CGPoint(x: ox, y: oy + 2))
            top.addQuadCurve(to: CGPoint(x: ox + 10, y: oy + 2), control: CGPoint(x: ox + 5, y: oy + 1))
            top.addQuadCurve(to: CGPoint(x: ox + 20, y: oy + 2), control: CGPoint(x: ox + 15, y: oy + 3))
            ctx.stroke(top, with: .color(ink), lineWidth: 0.9)
            var bot = Path()
            bot.move(to: CGPoint(x: ox, y: oy + 4))
            bot.addQuadCurve(to: CGPoint(x: ox + 10, y: oy + 4), control: CGPoint(x: ox + 5, y: oy + 5))
            bot.addQuadCurve(to: CGPoint(x: ox + 20, y: oy + 4), control: CGPoint(x: ox + 15, y: oy + 3))
            ctx.stroke(bot, with: .color(ink), lineWidth: 0.7)
        }
    }

    private func metal(_ ctx: GraphicsContext, _ size: CGSize) {
        tile(size, cell: 6) { ox, oy in
            var p = Path()
            p.move(to: CGPoint(x: ox, y: oy));       p.addLine(to: CGPoint(x: ox + 6, y: oy + 6))
            p.move(to: CGPoint(x: ox + 6, y: oy));    p.addLine(to: CGPoint(x: ox, y: oy + 6))
            ctx.stroke(p, with: .color(ink), lineWidth: 0.9)
        }
    }

    private func glass(_ ctx: GraphicsContext, _ size: CGSize) {
        tile(size, cell: 10) { ox, oy in
            var p = Path()
            p.move(to: CGPoint(x: ox, y: oy + 2)); p.addLine(to: CGPoint(x: ox + 10, y: oy + 2))
            p.move(to: CGPoint(x: ox, y: oy + 6)); p.addLine(to: CGPoint(x: ox + 10, y: oy + 6))
            ctx.stroke(p, with: .color(ink), lineWidth: 0.9)
        }
    }

    private func questionMark(_ ctx: GraphicsContext, _ size: CGSize) {
        let text = ctx.resolve(Text("?").font(.system(size: size.height * 0.5, weight: .semibold)).foregroundStyle(ink))
        ctx.draw(text, at: CGPoint(x: size.width / 2, y: size.height / 2))
    }

    /// Repeat `body` over a square unit cell across the whole canvas.
    private func tile(_ size: CGSize, cell: CGFloat, _ body: (CGFloat, CGFloat) -> Void) {
        tile(size, cell: CGSize(width: cell, height: cell), body)
    }
    private func tile(_ size: CGSize, cell: CGSize, _ body: (CGFloat, CGFloat) -> Void) {
        var y = -cell.height
        while y < size.height + cell.height {
            var x = -cell.width
            while x < size.width + cell.width {
                body(x, y)
                x += cell.width
            }
            y += cell.height
        }
    }
}

// MARK: - Kind glyphs (Building / Element / Graphic)

/// Line-art glyphs for the three Kinds, ported from the web app's camera
/// type-segment SVGs (28-unit viewBox, 1.8 stroke).
struct KindGlyph: View {
    let id: String
    var color: Color

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height) / 28
            func P(_ build: (inout Path) -> Void) -> Path {
                var p = Path(); build(&p)
                return p.applying(CGAffineTransform(scaleX: s, y: s))
            }
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
            var paths: [Path] = []
            switch id {
            case "element":
                paths.append(P { p in p.move(to: pt(6,4)); p.addLine(to: pt(22,4)); p.addLine(to: pt(22,7)); p.addLine(to: pt(6,7)); p.closeSubpath() })
                paths.append(P { p in p.move(to: pt(8,7)); p.addLine(to: pt(8,21)); p.addLine(to: pt(20,21)); p.addLine(to: pt(20,7)) })
                paths.append(P { p in p.move(to: pt(12,8)); p.addLine(to: pt(12,21)) })
                paths.append(P { p in p.move(to: pt(16,8)); p.addLine(to: pt(16,21)) })
                paths.append(P { p in p.move(to: pt(5,21)); p.addLine(to: pt(23,21)); p.addLine(to: pt(23,24)); p.addLine(to: pt(5,24)); p.closeSubpath() })
            case "graphic":
                paths.append(P { p in p.move(to: pt(5,3)); p.addLine(to: pt(18,3)); p.addLine(to: pt(23,8)); p.addLine(to: pt(23,25)); p.addLine(to: pt(5,25)); p.closeSubpath() })
                paths.append(P { p in p.move(to: pt(18,3)); p.addLine(to: pt(18,8)); p.addLine(to: pt(23,8)) })
                paths.append(P { p in p.move(to: pt(9,14)); p.addLine(to: pt(19,14)) })
                paths.append(P { p in p.move(to: pt(9,18)); p.addLine(to: pt(19,18)) })
                paths.append(P { p in p.move(to: pt(9,22)); p.addLine(to: pt(15,22)) })
            default: // building
                paths.append(P { p in p.move(to: pt(3,13)); p.addLine(to: pt(14,4)); p.addLine(to: pt(25,13)) })
                paths.append(P { p in p.move(to: pt(6,13)); p.addLine(to: pt(6,24)); p.addLine(to: pt(22,24)); p.addLine(to: pt(22,13)) })
                paths.append(P { p in p.addRect(CGRect(x: 12, y: 16, width: 4, height: 8)) })
            }
            let style = StrokeStyle(lineWidth: 1.8 * s, lineCap: .round, lineJoin: .round)
            for path in paths { ctx.stroke(path, with: .color(color), style: style) }
        }
    }
}

// MARK: - Reusable illustrated tile

/// A selectable tile that shows artwork in a square panel with a label below
/// and a corner check when selected — the old swatch idiom, in the app's
/// rounded style with the indigo accent.
struct IllustratedTile<Art: View>: View {
    let label: String
    let selected: Bool
    let art: Art
    let action: () -> Void

    init(label: String, selected: Bool, @ViewBuilder art: () -> Art, action: @escaping () -> Void) {
        self.label = label
        self.selected = selected
        self.art = art()
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Palette.tile)
                        .overlay(art.padding(6).clipShape(RoundedRectangle(cornerRadius: 9)))
                        .overlay(RoundedRectangle(cornerRadius: 9)
                            .strokeBorder(selected ? Palette.coral : Palette.hairline,
                                          lineWidth: selected ? 2 : 0.5))
                        .aspectRatio(1, contentMode: .fit)
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Palette.coral, Palette.paperElev)
                            .padding(5)
                    }
                }
                Text(label)
                    .font(.caption2)
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .foregroundStyle(selected ? Palette.coral : Palette.ink2)
            }
        }
        .buttonStyle(.plain)
    }
}
