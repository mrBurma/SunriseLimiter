import AppKit
import CoreGraphics
import Foundation

// Sunrise Limiter app icon: white audio speaker protected by a padlock,
// over a deep lagoon-coloured background.
let size = 1024
let inset = 72.0
let rect = CGRect(x: inset, y: inset, width: Double(size) - inset * 2, height: Double(size) - inset * 2)
guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
      let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                          bytesPerRow: 0, space: colorSpace,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    fatalError("Could not create icon context")
}
let squircle = CGPath(roundedRect: rect, cornerWidth: 210, cornerHeight: 210, transform: nil)
ctx.saveGState()
ctx.addPath(squircle)
ctx.clip()
let bg = CGGradient(colorsSpace: colorSpace, colors: [
    CGColor(red: 0.039, green: 0.16, blue: 0.23, alpha: 1),
    CGColor(red: 0.039, green: 0.37, blue: 0.46, alpha: 1),
    CGColor(red: 0.043, green: 0.039, blue: 0.063, alpha: 1)
] as CFArray, locations: [0, 0.55, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 180, y: 920), end: CGPoint(x: 850, y: 80), options: [])

// Subtle turquoise halo behind the white glyph.
let halo = CGGradient(colorsSpace: colorSpace, colors: [
    CGColor(red: 0.13, green: 0.78, blue: 0.75, alpha: 0.42),
    CGColor(red: 0.13, green: 0.78, blue: 0.75, alpha: 0.0)
] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(halo, startCenter: CGPoint(x: 520, y: 535), startRadius: 30,
                       endCenter: CGPoint(x: 520, y: 535), endRadius: 500, options: [])

// Rounded lock body.
let white = CGColor(red: 0.98, green: 0.99, blue: 1.0, alpha: 1)
ctx.setStrokeColor(white)
ctx.setFillColor(CGColor(red: 0.92, green: 0.98, blue: 0.98, alpha: 0.10))
ctx.setLineWidth(34)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)
let body = CGPath(roundedRect: CGRect(x: 270, y: 225, width: 485, height: 390), cornerWidth: 72, cornerHeight: 72, transform: nil)
ctx.addPath(body)
ctx.drawPath(using: .fillStroke)

// Open-top shackle.
let shackle = CGMutablePath()
shackle.move(to: CGPoint(x: 365, y: 610))
shackle.addLine(to: CGPoint(x: 365, y: 710))
shackle.addCurve(to: CGPoint(x: 660, y: 710), control1: CGPoint(x: 365, y: 820), control2: CGPoint(x: 660, y: 820))
shackle.addLine(to: CGPoint(x: 660, y: 610))
ctx.addPath(shackle)
ctx.strokePath()

// Speaker cone inside the lock.
let speaker = CGMutablePath()
speaker.move(to: CGPoint(x: 365, y: 375))
speaker.addLine(to: CGPoint(x: 445, y: 375))
speaker.addLine(to: CGPoint(x: 545, y: 300))
speaker.addLine(to: CGPoint(x: 545, y: 540))
speaker.addLine(to: CGPoint(x: 445, y: 465))
speaker.addLine(to: CGPoint(x: 365, y: 465))
speaker.closeSubpath()
ctx.addPath(speaker)
ctx.setFillColor(white)
ctx.fillPath()

// Two clean sound-wave arcs.
ctx.setStrokeColor(white)
ctx.setLineWidth(28)
ctx.setLineCap(.round)
for radius in [72.0, 132.0] {
    let arc = CGMutablePath()
    arc.move(to: CGPoint(x: 575 + radius * 0.52, y: 390 - radius * 0.78))
    arc.addQuadCurve(to: CGPoint(x: 575 + radius * 0.52, y: 450 + radius * 0.78),
                     control: CGPoint(x: 575 + radius * 1.25, y: 420))
    ctx.addPath(arc)
    ctx.strokePath()
}

// Keyhole: small turquoise circle and stem, making the protection metaphor clear.
ctx.setFillColor(CGColor(red: 0.13, green: 0.78, blue: 0.75, alpha: 1))
ctx.fillEllipse(in: CGRect(x: 622, y: 365, width: 38, height: 38))
ctx.fill(CGRect(x: 635, y: 340, width: 12, height: 36))
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(squircle)
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.16))
ctx.setLineWidth(3)
ctx.strokePath()
ctx.restoreGState()

guard let image = ctx.makeImage() else { fatalError("Could not render icon") }
let bitmap = NSBitmapImageRep(cgImage: image)
guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("Could not encode icon") }
let output = URL(fileURLWithPath: CommandLine.arguments[1])
try png.write(to: output)
print("wrote \(output.path)")
