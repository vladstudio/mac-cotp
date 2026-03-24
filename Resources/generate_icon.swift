import AppKit

let sizes: [(CGFloat, String)] = [
    (16, "icon_16x16"),
    (32, "icon_16x16@2x"),
    (32, "icon_32x32"),
    (64, "icon_32x32@2x"),
    (128, "icon_128x128"),
    (256, "icon_128x128@2x"),
    (256, "icon_256x256"),
    (512, "icon_256x256@2x"),
    (512, "icon_512x512"),
    (1024, "icon_512x512@2x"),
]

let iconsetPath = "/tmp/AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconsetPath)
try! FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

for (size, name) in sizes {
    let img = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        // Background rounded rect
        let radius = size * 0.22
        let bg = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.02, dy: size * 0.02), xRadius: radius, yRadius: radius)
        NSColor(calibratedRed: 0.2, green: 0.5, blue: 0.95, alpha: 1.0).setFill()
        bg.fill()

        // SF Symbol
        let symbolSize = size * 0.55
        let config = NSImage.SymbolConfiguration(pointSize: symbolSize, weight: .medium)
        if let symbol = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil)?
            .withSymbolConfiguration(config) {
            let symbolRect = symbol.alignmentRect
            let x = (size - symbolRect.width) / 2
            let y = (size - symbolRect.height) / 2
            NSColor.white.setFill()
            symbol.draw(in: NSRect(x: x, y: y, width: symbolRect.width, height: symbolRect.height))
        }
        return true
    }

    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    img.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()

    let png = rep.representation(using: .png, properties: [:])!
    try! png.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(name).png"))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetPath, "-o", "Resources/AppIcon.icns"]
try! process.run()
process.waitUntilExit()

try? FileManager.default.removeItem(atPath: iconsetPath)
print("Generated Resources/AppIcon.icns")
