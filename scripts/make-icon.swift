import AppKit

// Original clipboard geometry on a neutral silver tile; no bundled fonts or Apple artwork.
let destination = CommandLine.arguments[1]
let image = NSImage(size: NSSize(width: 1024, height: 1024))
image.lockFocus()
let outer = NSBezierPath(roundedRect: NSRect(x: 70, y: 70, width: 884, height: 884), xRadius: 204, yRadius: 204)
NSGradient(starting: NSColor(white: 0.78, alpha: 1), ending: NSColor(white: 0.98, alpha: 1))!.draw(in: outer, angle: 90)
NSColor.white.withAlphaComponent(0.75).setStroke()
outer.lineWidth = 2
outer.stroke()
NSGraphicsContext.saveGraphicsState()
let transform = NSAffineTransform()
transform.translateX(by: 470, yBy: 495)
transform.rotate(byDegrees: -10)
transform.concat()
NSColor(white: 0.68, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: -215, y: -225, width: 370, height: 480), xRadius: 40, yRadius: 40).fill()
NSGraphicsContext.restoreGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
shadow.shadowBlurRadius = 24
shadow.shadowOffset = NSSize(width: 0, height: -12)
NSGraphicsContext.saveGraphicsState()
shadow.set()
NSColor.white.setFill()
NSBezierPath(roundedRect: NSRect(x: 349, y: 246, width: 370, height: 494), xRadius: 40, yRadius: 40).fill()
NSGraphicsContext.restoreGraphicsState()
NSGradient(starting: NSColor(white: 0.35, alpha: 1), ending: NSColor(white: 0.52, alpha: 1))!.draw(in: NSBezierPath(roundedRect: NSRect(x: 444, y: 708, width: 180, height: 60), xRadius: 20, yRadius: 20), angle: 90)
NSColor(white: 0.58, alpha: 1).setFill()
for (y, width) in [(610.0, 207.0), (544.0, 207.0), (478.0, 135.0)] {
    NSBezierPath(roundedRect: NSRect(x: 422, y: y, width: width, height: 20), xRadius: 10, yRadius: 10).fill()
}
let check = NSBezierPath()
check.move(to: NSPoint(x: 580, y: 362))
check.line(to: NSPoint(x: 616, y: 328))
check.line(to: NSPoint(x: 679, y: 396))
check.lineWidth = 25
check.lineCapStyle = .round
check.lineJoinStyle = .round
NSColor.systemBlue.setStroke()
check.stroke()
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: destination))
