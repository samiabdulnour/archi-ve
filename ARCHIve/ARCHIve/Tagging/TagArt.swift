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

// MARK: - Line-art glyphs (Typology / Graphic kinds / Visual)

enum ArtGroup { case typology, graphic, visual, concept, room }

/// Architectural line-art for the remaining tag groups, in a 48-unit space.
/// Typology + Graphic are ported from the web app's SVGs where available;
/// Visual glyphs are designed to match the same hand.
struct LineArtGlyph: View {
    let group: ArtGroup
    let id: String
    var color: Color

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height) / 48
            let scale = CGAffineTransform(scaleX: s, y: s)
            func stroke(_ lw: CGFloat, _ build: (inout Path) -> Void) {
                var p = Path(); build(&p)
                ctx.stroke(p.applying(scale), with: .color(color),
                           style: StrokeStyle(lineWidth: lw * s, lineCap: .round, lineJoin: .round))
            }
            func line(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ lw: CGFloat = 1.8) {
                stroke(lw) { $0.move(to: CGPoint(x: x1, y: y1)); $0.addLine(to: CGPoint(x: x2, y: y2)) }
            }
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ lw: CGFloat = 1.8) {
                stroke(lw) { $0.addRect(CGRect(x: x, y: y, width: w, height: h)) }
            }
            func poly(_ pts: [(CGFloat, CGFloat)], close: Bool = false, _ lw: CGFloat = 1.8) {
                stroke(lw) { p in
                    guard let f = pts.first else { return }
                    p.move(to: CGPoint(x: f.0, y: f.1))
                    for q in pts.dropFirst() { p.addLine(to: CGPoint(x: q.0, y: q.1)) }
                    if close { p.closeSubpath() }
                }
            }
            func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ lw: CGFloat = 1.8) {
                stroke(lw) { $0.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: 2*r, height: 2*r)) }
            }
            func dot(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
                ctx.fill(Path(ellipseIn: CGRect(x: (cx-r)*s, y: (cy-r)*s, width: 2*r*s, height: 2*r*s)),
                         with: .color(color))
            }
            func disc(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) { dot(cx, cy, r) }
            func fillRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
                ctx.fill(Path(CGRect(x: x*s, y: y*s, width: w*s, height: h*s)), with: .color(color))
            }
            func quad(_ lw: CGFloat, _ pts: [(CGFloat, CGFloat)], controls: [(CGFloat, CGFloat)]) {
                stroke(lw) { p in
                    p.move(to: CGPoint(x: pts[0].0, y: pts[0].1))
                    for i in 1..<pts.count {
                        p.addQuadCurve(to: CGPoint(x: pts[i].0, y: pts[i].1),
                                       control: CGPoint(x: controls[i-1].0, y: controls[i-1].1))
                    }
                }
            }
            func qmark() {
                let t = ctx.resolve(Text("?").font(.system(size: 20 * s, weight: .semibold))
                    .foregroundColor(color))
                ctx.draw(t, at: CGPoint(x: 24 * s, y: 25 * s))
            }

            switch (group, id) {

            // MARK: Typology
            case (.typology, "Residential"):
                poly([(7,24),(24,9),(41,24)])
                poly([(11,22),(11,41),(37,41),(37,22)])
                rect(21,29,6,12); rect(14,26,5,5); rect(29,26,5,5); line(32,14,32,19)
            case (.typology, "Office"):
                poly([(10,7),(38,7),(38,41),(10,41)], close: true)
                for y in [11.0,17,23,29,35] {
                    for x in [14.0,20,26,32] { fillRect(x, y-1, 2, 2) }
                }
            case (.typology, "Public"):
                poly([(5,18),(24,7),(43,18)], close: true)
                line(5,40,43,40); line(6,36,42,36); line(6,20,42,20)
                for vx in [12.0,20.0,28.0,36.0] { line(vx,20,vx,36) }
                line(24,3,24,9); poly([(24,4),(30,6),(24,8)], 0.7)
            case (.typology, "Commercial"):
                rect(7,11,34,30)
                poly([(7,17),(11,21),(37,21),(41,17)])
                for x in [14.0,20,26,32] { line(x,17,x,21,0.8) }
                rect(21,28,6,13); dot(25.5,34,0.6)
                rect(10,25,9,13); rect(29,25,9,13)
                line(14.5,25,14.5,38,0.6); line(33.5,25,33.5,38,0.6)
            case (.typology, "Hospitality"):
                rect(6,9,36,32); line(6,14,42,14,1)
                for y in [16.0,22,28,34] {
                    for x in [8.0,15,22,29,36] { rect(x,y,5,3,0.9) }
                }
            case (.typology, "Heritage"):
                poly([(14,11),(34,11),(34,14),(14,14)], close: true)
                poly([(16,14),(16,35),(32,35),(32,14)])
                poly([(11,35),(37,35),(37,38),(11,38)], close: true)
                poly([(9,38),(39,38),(39,41),(9,41)], close: true)
                for x in [20.0,24,28] { line(x,15,x,34,0.7) }
                dot(19,12.5,0.7); dot(29,12.5,0.7)
            case (.typology, "Landscape"):
                circle(36,11,2.6)
                stroke(1.8) { p in
                    p.move(to: CGPoint(x: 4, y: 36))
                    p.addQuadCurve(to: CGPoint(x: 22, y: 30), control: CGPoint(x: 12, y: 26))
                    p.addQuadCurve(to: CGPoint(x: 44, y: 24), control: CGPoint(x: 32, y: 34))
                }
                line(4,42,44,42); line(12,36,12,26); circle(12,21,5)

            // MARK: Graphic kinds
            case (.graphic, "Artwork"):
                rect(6,9,36,30); rect(10,13,28,22,0.7); circle(32,19,2.2)
                poly([(10,30),(17,23),(22,28),(28,22),(34,27),(38,24),(38,35),(10,35)], close: true)
            case (.graphic, "Book"):
                line(24,12,24,40)
                stroke(1.8) { p in p.move(to: CGPoint(x:24,y:12)); p.addQuadCurve(to: CGPoint(x:7,y:13), control: CGPoint(x:15,y:9)); p.addLine(to: CGPoint(x:7,y:37)); p.addQuadCurve(to: CGPoint(x:24,y:36), control: CGPoint(x:15,y:33)) }
                stroke(1.8) { p in p.move(to: CGPoint(x:24,y:12)); p.addQuadCurve(to: CGPoint(x:41,y:13), control: CGPoint(x:33,y:9)); p.addLine(to: CGPoint(x:41,y:37)); p.addQuadCurve(to: CGPoint(x:24,y:36), control: CGPoint(x:33,y:33)) }
            case (.graphic, "Drawing"):
                poly([(8,6),(32,6),(40,14),(40,42),(8,42)], close: true)
                poly([(32,6),(32,14),(40,14)])
                poly([(12,22),(20,16),(26,22),(34,18)], 1.0)
                line(12,30,34,30,0.7); line(12,34,34,34,0.7); line(12,38,28,38,0.7)
            case (.graphic, "Plan"):
                rect(6,6,36,36); line(6,22,42,22); line(22,22,22,42)
                rect(10,11,8,6,0.7); rect(32,32,6,6,0.7)
            case (.graphic, "Render"):
                poly([(10,16),(24,10),(38,16),(38,34),(24,40),(10,34)], close: true)
                poly([(10,16),(24,22),(38,16)]); line(24,22,24,40)
                circle(38,9,2.4); line(35,6,33,8,0.6); line(41,6,43,8,0.6); line(38,3,38,5,0.6)
            case (.graphic, "Diagram"):
                line(8,40,42,40); line(8,8,8,40)
                rect(13,28,5,12,0.9); rect(21,22,5,18,0.9); rect(29,14,5,26,0.9); rect(37,24,5,16,0.9)
            case (.graphic, "Contact"):
                rect(6,11,36,26); circle(15,20,3)
                stroke(1.8) { p in p.move(to: CGPoint(x:9,y:32)); p.addQuadCurve(to: CGPoint(x:21,y:32), control: CGPoint(x:15,y:24)) }
                line(26,18,38,18,1.0); line(26,23,38,23,1.0); line(26,28,35,28,1.0)

            // MARK: Visual
            case (.visual, "Colorful"):
                circle(18,20,9); circle(30,20,9); circle(24,30,9)
            case (.visual, "Monochrome"):
                circle(24,24,14)
                ctx.fill(Path { p in p.addArc(center: CGPoint(x:24*s,y:24*s), radius: 14*s, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false) }, with: .color(color))
            case (.visual, "Textured"):
                rect(9,9,30,30)
                for d in stride(from: -24.0, through: 30.0, by: 6.0) { line(max(9,9+d),max(9,9-d), min(39,39+d),min(39,39-d),0.8) }
            case (.visual, "Minimal"):
                rect(10,10,28,28,0.8); dot(24,24,2)
            case (.visual, "Patterned"):
                for cx in [15.0,24.0,33.0] { for cy in [15.0,24.0,33.0] { dot(cx,cy,1.8) } }
            case (.visual, "Ornate"):
                circle(24,24,12,0.9); circle(24,24,7,0.9); dot(24,24,2)
                for a in stride(from: 0.0, to: 360.0, by: 45.0) {
                    let r1 = 12.0, r2 = 16.0, rad = a * .pi/180
                    line(24+r1*cos(rad), 24+r1*sin(rad), 24+r2*cos(rad), 24+r2*sin(rad), 0.8)
                }
            case (.visual, "Dark"):
                disc(24,24,13)
            case (.visual, "Light"):
                circle(24,24,7)
                for a in stride(from: 0.0, to: 360.0, by: 45.0) {
                    let rad = a * .pi/180
                    line(24+11*cos(rad), 24+11*sin(rad), 24+16*cos(rad), 24+16*sin(rad), 1.2)
                }

            // MARK: Concept (ported exactly from the web _v2 glyphs)
            case (.concept, "form"):
                poly([(24,6),(40,14),(40,32),(24,40),(8,32),(8,14)], close: true)
                line(24,6,24,24); line(24,24,8,14); line(24,24,40,14)
            case (.concept, "space"):
                rect(7,7,34,34); rect(14,14,20,20)
                line(14,22,14,26,3); line(7,22,7,26,3)
            case (.concept, "light"):
                circle(24,24,6)
                for a in stride(from: 0.0, to: 360.0, by: 45.0) {
                    let r = a * .pi/180
                    line(24+cos(r)*11, 24+sin(r)*11, 24+cos(r)*16, 24+sin(r)*16)
                }
            case (.concept, "materiality"):
                rect(8,8,32,32); line(24,8,24,40); line(8,24,40,24)
                for (x,y,r) in [(12.0,12.0,0.7),(16,14,0.6),(20,11,0.6),(14,18,0.6),(20,20,0.7),(11,22,0.6),(17,22,0.5)] { dot(x,y,r) }
                for (x1,y1,x2,y2) in [(25.0,12.0,39.0,12.0),(25,16,39,16),(25,20,39,20),(29,9,29,12),(34,12,34,16),(29,16,29,20),(34,20,34,23)] { line(x1,y1,x2,y2,0.8) }
                quad(0.8, [(9,28),(19,28),(23,28)], controls: [(14,27),(24,29)])
                quad(0.8, [(9,32),(19,32),(23,32)], controls: [(14,33),(24,31)])
                quad(0.8, [(9,36),(19,36),(23,36)], controls: [(14,35),(24,37)])
                line(26,38,38,26,0.8); line(26,32,32,26,0.8); line(32,38,38,32,0.8)
            case (.concept, "structure"):
                line(5,16,43,16); line(5,30,43,30); line(5,16,5,30); line(43,16,43,30)
                poly([(5,30),(12,16),(19,30),(26,16),(33,30),(40,16),(43,30)])
                for x in [5.0,19,33] { dot(x,30,1.2) }
                for x in [12.0,26,40] { dot(x,16,1.2) }
            case (.concept, "context"):
                rect(6,6,36,36,0.7); line(6,22,42,22,0.8); line(22,6,22,42,0.8)
                fillRect(9,9,9,6); fillRect(11,26,8,11); fillRect(26,11,13,7); fillRect(29,28,6,6)
            case (.concept, "circulation"):
                quad(1.8, [(6,36),(18,30),(26,22),(36,14)], controls: [(14,36),(22,24),(32,20)])
                poly([(33,13),(38,12),(37,17)])
                dot(9,36,1.6); dot(38,11,1.6)

            // MARK: Rooms (ported from the web _v2 room glyphs; 1.5 stroke)
            case (.room, "library"):
                rect(6,6,36,36,1.5); line(6,20,42,20,1.5); line(6,34,42,34,1.5)
                for x in [10.0,14,18,22,26,30,34,38] { line(x,8,x,18,0.7); line(x,22,x,32,0.7) }
            case (.room, "auditorium"):
                rect(10,8,28,8,1.5)
                for y in [22.0,28,34,40] { line(6,y,42,y,0.8) }
            case (.room, "shop"):
                poly([(6,16),(24,8),(42,16)],1.5); poly([(8,16),(8,42),(40,42),(40,16)],1.5)
                rect(14,22,20,16,0.8); line(24,22,24,38,0.6); line(14,30,34,30,0.6)
            case (.room, "showroom"):
                rect(6,6,36,36,1.5); line(6,34,42,34,1.5)
                rect(12,14,6,20,0.7); circle(24,22,5,0.7); rect(32,18,6,16,0.7)
            case (.room, "bar"):
                poly([(6,26),(42,26),(42,32),(6,32)],close:true,1.5); line(14,32,14,40,1.5); line(34,32,34,40,1.5)
                rect(11,10,3,14,0.7); rect(18,8,3,16,0.7); rect(25,10,3,14,0.7); rect(32,12,3,12,0.7)
            case (.room, "spa"):
                for y in [16.0,24,32,40] {
                    quad(1.5, [(6,y),(18,y),(30,y),(42,y)], controls: [(12,y-4),(24,y+4),(36,y-4)])
                }
            case (.room, "lab"):
                stroke(1.5) { p in
                    p.move(to: CGPoint(x:18,y:8)); p.addLine(to: CGPoint(x:30,y:8)); p.addLine(to: CGPoint(x:30,y:16))
                    p.addLine(to: CGPoint(x:36,y:36)); p.addQuadCurve(to: CGPoint(x:32,y:40), control: CGPoint(x:36,y:40))
                    p.addLine(to: CGPoint(x:16,y:40)); p.addQuadCurve(to: CGPoint(x:12,y:36), control: CGPoint(x:12,y:40))
                    p.addLine(to: CGPoint(x:18,y:16)); p.closeSubpath()
                }
                line(14,28,34,28,0.7); dot(20,34,0.8); dot(25,32,0.6); dot(29,35,0.7)
            case (.room, "mechanical"):
                circle(24,24,9,1.5); circle(24,24,3,0.9)
                for a in stride(from: 0.0, to: 360.0, by: 45.0) {
                    let r = a * .pi/180
                    line(24+cos(r)*9, 24+sin(r)*9, 24+cos(r)*12, 24+sin(r)*12, 1.5)
                }
            case (.room, "chapel"):
                poly([(12,22),(24,12),(36,22)],1.5); poly([(14,22),(14,40),(34,40),(34,22)],1.5)
                line(24,14,24,19,1.5); line(21.5,16.5,26.5,16.5,1.5); rect(21,30,6,10,0.8)
            case (.room, "stairs"):
                poly([(6,40),(6,32),(14,32),(14,24),(22,24),(22,16),(30,16),(30,8),(42,8)],1.5)
                line(6,40,42,40,1.5); line(42,8,42,40,0.7)
            case (.room, "atrium"):
                line(14,6,34,6,1.5); line(14,10,34,10,0.7); line(6,10,6,42,1.5); line(42,10,42,42,1.5)
                line(6,42,42,42,1.5); line(14,42,14,22,0.7); line(34,42,34,22,0.7)
            case (.room, "lounge"):
                line(10,22,10,36,1.5); line(38,22,38,36,1.5); poly([(14,22),(34,22),(34,28)],1.5)
                poly([(6,26),(42,26),(42,32),(6,32)],close:true,1.5); line(12,32,12,40,1.5); line(36,32,36,40,1.5)
            case (.room, "window"):
                rect(6,8,36,30,1.5); line(6,40,42,40,1.5); line(24,8,24,38,0.6)
                rect(10,14,10,20,0.8); circle(33,22,5,0.8)
            case (.room, "counter"):
                poly([(6,30),(42,30),(42,40),(6,40)],close:true,1.5); line(6,34,42,34,0.6)
                rect(14,14,20,14,1.5); line(14,22,34,22,0.7)
                fillRect(16,24,3,2); fillRect(21,24,3,2); fillRect(26,24,3,2)
            case (.room, "outdoor"):
                circle(34,12,3,1.5); line(14,40,14,24,1.5); circle(14,18,6,1.5); line(6,40,42,40,1.5)
            case (.room, "living"):
                rect(8,24,32,10,1.5); poly([(8,24),(8,18),(40,18),(40,24)],0.9)
                line(24,24,24,34,0.6); line(12,34,12,40,1.5); line(36,34,36,40,1.5)
            case (.room, "bedroom"):
                poly([(8,20),(8,14),(40,14),(40,20)],0.9); rect(8,20,32,16,1.5)
                rect(11,23,9,6,0.8); line(8,36,8,40,1.5); line(40,36,40,40,1.5)
            case (.room, "kitchen"):
                rect(6,18,36,8,1.5); rect(6,26,36,14,1.5); circle(13,22,2,0.8); circle(20,22,2,0.8)
                line(6,32,42,32,0.6)
            case (.room, "bathroom"):
                rect(10,22,28,10,1.5); circle(13,17,2,1.5); line(13,19,13,22,0.8)
                line(12,32,12,38,1.5); line(36,32,36,38,1.5)
            case (.room, "dining"):
                rect(15,20,18,8,1.5); for x in [12.0,21,30,39] { dot(x,16,1.4); dot(x,32,1.4) }
            case (.room, "meeting"):
                circle(24,24,9,1.5); for a in stride(from: 0.0, to: 360.0, by: 60.0) {
                    let r = a * .pi/180; dot(24+cos(r)*13, 24+sin(r)*13, 1.6)
                }
            case (.room, "workspace"):
                line(8,38,40,38,1.5); rect(18,14,14,11,1.5); line(25,25,25,30,1.5); line(19,30,31,30,1.5)
            case (.room, "hall"):
                rect(10,6,28,36,1.5); poly([(10,6),(20,16),(20,42)],0.7); poly([(38,6),(28,16),(28,42)],0.7)
            case (.room, "storage"):
                rect(8,8,32,34,1.5); line(8,19,40,19,1.5); line(8,30,40,30,1.5)
                dot(24,13.5,1); dot(24,24.5,1); dot(24,36,1)
            case (.room, "service"):
                rect(14,8,20,34,1.5); line(24,8,24,42,0.8); dot(20,25,1); dot(28,25,1)

            default:
                if case .room = group {
                    rect(8,10,32,30,1.5); rect(18,26,12,14,1.0)   // generic room
                } else {
                    qmark()
                }
            }
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
    /// Line-art glyphs are inset (~62% like the web swatches); patterns and
    /// colour swatches fill the tile edge-to-edge.
    var fullBleed: Bool = false
    let art: Art
    let action: () -> Void

    init(label: String, selected: Bool, fullBleed: Bool = false,
         @ViewBuilder art: () -> Art, action: @escaping () -> Void) {
        self.label = label
        self.selected = selected
        self.fullBleed = fullBleed
        self.art = art()
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Palette.tile)
                        .overlay(art.padding(fullBleed ? 3 : 15).clipShape(RoundedRectangle(cornerRadius: 9)))
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
