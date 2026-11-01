import AppKit

// A code-drawn, original vector mark; no external image or font assets.
let destination = CommandLine.arguments[1]
let image = NSImage(size: NSSize(width: 1024, height: 1024))
image.lockFocus()
let outer = NSBezierPath(roundedRect: NSRect(x: 70, y: 70, width: 884, height: 884), xRadius: 204, yRadius: 204)
NSGradient(starting: NSColor(red: 0.36, green: 0.25, blue: 0.82, alpha: 1), ending: NSColor(red: 0.66, green: 0.49, blue: 1, alpha: 1))!.draw(in: outer, angle: 45)
NSGraphicsContext.saveGraphicsState()
let transform = NSAffineTransform()
transform.translateX(by: 470, yBy: 495)
transform.rotate(byDegrees: -12)
transform.concat()
NSColor.white.withAlphaComponent(0.22).setFill()
NSBezierPath(roundedRect: NSRect(x: -215, y: -225, width: 370, height: 480), xRadius: 46, yRadius: 46).fill()
NSGraphicsContext.restoreGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
shadow.shadowBlurRadius = 28
shadow.shadowOffset = NSSize(width: 0, height: -14)
NSGraphicsContext.saveGraphicsState()
shadow.set()
NSColor.white.setFill()
NSBezierPath(roundedRect: NSRect(x: 359, y: 266, width: 360, height: 474), xRadius: 46, yRadius: 46).fill()
NSGraphicsContext.restoreGraphicsState()
NSColor(red: 0.72, green: 0.63, blue: 0.98, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: 450, y: 708, width: 177, height: 60), xRadius: 24, yRadius: 24).fill()
NSColor(red: 0.48, green: 0.36, blue: 0.87, alpha: 1).setFill()
for (y, width) in [(610.0, 207.0), (544.0, 207.0), (478.0, 135.0)] {
    NSBezierPath(roundedRect: NSRect(x: 427, y: y, width: width, height: 24), xRadius: 12, yRadius: 12).fill()
}
let check = NSBezierPath()
check.move(to: NSPoint(x: 589, y: 368))
check.line(to: NSPoint(x: 625, y: 334))
check.line(to: NSPoint(x: 688, y: 402))
check.lineWidth = 27
check.lineCapStyle = .round
check.lineJoinStyle = .round
NSColor(red: 0.48, green: 0.36, blue: 0.87, alpha: 1).setStroke()
check.stroke()
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: destination))
