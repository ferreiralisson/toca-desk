import AppKit

// Vector artwork rendered at every native icon size; no external assets.
let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let iconset = root.appendingPathComponent("TocaDesk.iconset", isDirectory: true)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor {
    NSColor(calibratedRed: r / 255, green: g / 255, blue: b / 255, alpha: 1)
}
func oval(_ rect: NSRect, _ fill: NSColor) {
    fill.setFill(); NSBezierPath(ovalIn: rect).fill()
}
func render(_ pixels: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let scale = CGFloat(pixels) / 1024
    let transform = AffineTransform(scale: scale)
    (transform as NSAffineTransform).concat()
    let tile = NSBezierPath(roundedRect: NSRect(x: 42, y: 42, width: 940, height: 940), xRadius: 214, yRadius: 214)
    NSGradient(starting: color(104, 232, 187), ending: color(34, 163, 133))!.draw(in: tile, angle: -65)
    color(224, 255, 241).withAlphaComponent(0.5).setStroke(); tile.lineWidth = 3; tile.stroke()
    // Soft ground shadow anchors the mascot on the tile.
    oval(NSRect(x: 222, y: 150, width: 580, height: 90), color(12, 94, 79).withAlphaComponent(0.20))
    let fur = color(28, 49, 53)
    oval(NSRect(x: 228, y: 543, width: 174, height: 192), fur)
    oval(NSRect(x: 622, y: 543, width: 174, height: 192), fur)
    oval(NSRect(x: 271, y: 590, width: 83, height: 98), color(79, 113, 108))
    oval(NSRect(x: 670, y: 590, width: 83, height: 98), color(79, 113, 108))
    let body = NSBezierPath()
    body.move(to: NSPoint(x: 231, y: 269))
    body.curve(to: NSPoint(x: 268, y: 633), controlPoint1: NSPoint(x: 164, y: 374), controlPoint2: NSPoint(x: 207, y: 545))
    body.curve(to: NSPoint(x: 756, y: 633), controlPoint1: NSPoint(x: 355, y: 788), controlPoint2: NSPoint(x: 669, y: 788))
    body.curve(to: NSPoint(x: 793, y: 269), controlPoint1: NSPoint(x: 817, y: 545), controlPoint2: NSPoint(x: 860, y: 374))
    body.curve(to: NSPoint(x: 231, y: 269), controlPoint1: NSPoint(x: 705, y: 170), controlPoint2: NSPoint(x: 319, y: 170))
    body.close()
    NSGradient(starting: color(54, 80, 81), ending: fur)!.draw(in: body, angle: -90)
    // Small eyes and a broad, warm muzzle stay legible at Dock sizes.
    oval(NSRect(x: 348, y: 493, width: 40, height: 48), color(237, 251, 243))
    oval(NSRect(x: 636, y: 493, width: 40, height: 48), color(237, 251, 243))
    oval(NSRect(x: 352, y: 285, width: 320, height: 225), color(232, 225, 205))
    let nose = NSBezierPath()
    nose.move(to: NSPoint(x: 452, y: 484))
    nose.curve(to: NSPoint(x: 572, y: 484), controlPoint1: NSPoint(x: 466, y: 522), controlPoint2: NSPoint(x: 558, y: 522))
    nose.curve(to: NSPoint(x: 512, y: 422), controlPoint1: NSPoint(x: 582, y: 457), controlPoint2: NSPoint(x: 537, y: 427))
    nose.curve(to: NSPoint(x: 452, y: 484), controlPoint1: NSPoint(x: 487, y: 427), controlPoint2: NSPoint(x: 442, y: 457))
    color(17, 38, 42).setFill(); nose.fill()
    let smile = NSBezierPath()
    smile.move(to: NSPoint(x: 465, y: 367))
    smile.curve(to: NSPoint(x: 559, y: 367), controlPoint1: NSPoint(x: 489, y: 343), controlPoint2: NSPoint(x: 535, y: 343))
    smile.lineWidth = 11; smile.lineCapStyle = .round; color(83, 94, 81).setStroke(); smile.stroke()
    // Leaf tuft ties the mascot to the application's green identity.
    let leaf = NSBezierPath()
    leaf.move(to: NSPoint(x: 510, y: 716))
    leaf.curve(to: NSPoint(x: 654, y: 837), controlPoint1: NSPoint(x: 494, y: 806), controlPoint2: NSPoint(x: 574, y: 851))
    leaf.curve(to: NSPoint(x: 510, y: 716), controlPoint1: NSPoint(x: 661, y: 756), controlPoint2: NSPoint(x: 599, y: 704))
    color(212, 254, 223).setFill(); leaf.fill()
    let vein = NSBezierPath(); vein.move(to: NSPoint(x: 512, y: 715)); vein.line(to: NSPoint(x: 603, y: 796))
    vein.lineWidth = 10; vein.lineCapStyle = .round; color(66, 166, 132).setStroke(); vein.stroke()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}
for size in [16, 32, 128, 256, 512] {
    try render(size).write(to: iconset.appendingPathComponent("icon_\(size)x\(size).png"))
    try render(size * 2).write(to: iconset.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
try render(1024).write(to: root.appendingPathComponent("TocaDesk.png"))
