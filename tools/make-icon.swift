import AppKit
let out = CommandLine.arguments[1]
let fm = FileManager.default
try? fm.createDirectory(atPath: out, withIntermediateDirectories: true)
for (name, px) in [("16x16",16),("16x16@2x",32),("32x32",32),("32x32@2x",64),("128x128",128),("128x128@2x",256),("256x256",256),("256x256@2x",512),("512x512",512),("512x512@2x",1024)] {
    let s = CGFloat(px)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let inset = s * 0.08
    let rect = NSRect(x: inset, y: inset, width: s - 2*inset, height: s - 2*inset)
    let path = NSBezierPath(roundedRect: rect, xRadius: s*0.2, yRadius: s*0.2)
    NSGradient(starting: NSColor(calibratedRed: 0.96, green: 0.62, blue: 0.16, alpha: 1), ending: NSColor(calibratedRed: 0.62, green: 0.16, blue: 0.10, alpha: 1))!.draw(in: path, angle: -90)
    let para = NSMutableParagraphStyle(); para.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: s*0.36, weight: .heavy), .foregroundColor: NSColor.white, .paragraphStyle: para]
    let str = NSAttributedString(string: "HS", attributes: attrs)
    let h = str.size().height
    str.draw(in: NSRect(x: 0, y: (s - h)/2 + s*0.02, width: s, height: h))
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(out)/icon_\(name).png"))
}
