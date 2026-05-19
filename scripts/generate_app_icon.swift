#!/usr/bin/env swift

import AppKit
import Foundation

let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconsetURL = rootURL.appendingPathComponent(".build/icon/Clack.iconset")
let iconURL = rootURL.appendingPathComponent("Packaging/Clack.icns")

try FileManager.default.removeItemIfPresent(at: iconsetURL)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
try FileManager.default.createDirectory(
  at: iconURL.deletingLastPathComponent(),
  withIntermediateDirectories: true
)

let iconFiles: [(pixels: Int, name: String)] = [
  (16, "icon_16x16.png"),
  (32, "icon_16x16@2x.png"),
  (32, "icon_32x32.png"),
  (64, "icon_32x32@2x.png"),
  (128, "icon_128x128.png"),
  (256, "icon_128x128@2x.png"),
  (256, "icon_256x256.png"),
  (512, "icon_256x256@2x.png"),
  (512, "icon_512x512.png"),
  (1024, "icon_512x512@2x.png")
]

for iconFile in iconFiles {
  try drawIcon(
    pixels: iconFile.pixels,
    to: iconsetURL.appendingPathComponent(iconFile.name)
  )
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = [
  "-c",
  "icns",
  iconsetURL.path,
  "-o",
  iconURL.path
]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
  throw IconGenerationError.iconutilFailed(process.terminationStatus)
}

print(iconURL.path)

private func drawIcon(pixels: Int, to url: URL) throws {
  guard
    let bitmap = NSBitmapImageRep(
      bitmapDataPlanes: nil,
      pixelsWide: pixels,
      pixelsHigh: pixels,
      bitsPerSample: 8,
      samplesPerPixel: 4,
      hasAlpha: true,
      isPlanar: false,
      colorSpaceName: .deviceRGB,
      bytesPerRow: 0,
      bitsPerPixel: 0
    )
  else {
    throw IconGenerationError.bitmapCreationFailed
  }

  bitmap.size = NSSize(width: pixels, height: pixels)

  NSGraphicsContext.saveGraphicsState()
  guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
    throw IconGenerationError.graphicsContextCreationFailed
  }
  NSGraphicsContext.current = graphicsContext
  graphicsContext.cgContext.setAllowsAntialiasing(true)
  graphicsContext.cgContext.setShouldAntialias(true)
  graphicsContext.cgContext.scaleBy(
    x: CGFloat(pixels) / 1024,
    y: CGFloat(pixels) / 1024
  )

  drawBase()
  drawClipboard()
  drawMemoryMarks()

  NSGraphicsContext.restoreGraphicsState()

  guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    throw IconGenerationError.pngEncodingFailed
  }

  try pngData.write(to: url)
}

private func drawBase() {
  let rect = NSRect(x: 80, y: 80, width: 864, height: 864)
  let basePath = NSBezierPath(roundedRect: rect, xRadius: 210, yRadius: 210)
  let context = NSGraphicsContext.current?.cgContext

  context?.saveGState()
  context?.setShadow(
    offset: CGSize(width: 0, height: -18),
    blur: 42,
    color: CGColor(red: 0.02, green: 0.06, blue: 0.14, alpha: 0.34)
  )
  basePath.addClip()
  NSGradient(colors: [
    NSColor(calibratedRed: 0.07, green: 0.24, blue: 0.54, alpha: 1),
    NSColor(calibratedRed: 0.02, green: 0.47, blue: 0.69, alpha: 1),
    NSColor(calibratedRed: 0.00, green: 0.66, blue: 0.60, alpha: 1)
  ])?.draw(in: rect, angle: 45)
  context?.restoreGState()

  NSColor(calibratedWhite: 1, alpha: 0.18).setStroke()
  basePath.lineWidth = 10
  basePath.stroke()
}

private func drawClipboard() {
  let context = NSGraphicsContext.current?.cgContext

  context?.saveGState()
  context?.setShadow(
    offset: CGSize(width: 0, height: -20),
    blur: 34,
    color: CGColor(red: 0, green: 0.05, blue: 0.10, alpha: 0.34)
  )

  let backSheet = NSBezierPath(
    roundedRect: NSRect(x: 338, y: 226, width: 382, height: 536),
    xRadius: 68,
    yRadius: 68
  )
  NSColor(calibratedRed: 0.78, green: 0.92, blue: 0.96, alpha: 0.34).setFill()
  backSheet.fill()

  let sheet = NSBezierPath(
    roundedRect: NSRect(x: 292, y: 264, width: 440, height: 552),
    xRadius: 76,
    yRadius: 76
  )
  NSColor(calibratedRed: 0.96, green: 0.98, blue: 0.98, alpha: 1).setFill()
  sheet.fill()
  context?.restoreGState()

  NSColor(calibratedRed: 0.09, green: 0.28, blue: 0.52, alpha: 0.16).setStroke()
  sheet.lineWidth = 8
  sheet.stroke()

  let clip = NSBezierPath(
    roundedRect: NSRect(x: 384, y: 704, width: 256, height: 114),
    xRadius: 46,
    yRadius: 46
  )
  NSColor(calibratedRed: 0.88, green: 0.95, blue: 0.98, alpha: 1).setFill()
  clip.fill()

  NSColor(calibratedRed: 0.06, green: 0.40, blue: 0.70, alpha: 0.22).setStroke()
  clip.lineWidth = 8
  clip.stroke()
}

private func drawMemoryMarks() {
  let blue = NSColor(calibratedRed: 0.08, green: 0.40, blue: 0.74, alpha: 1)
  let teal = NSColor(calibratedRed: 0.00, green: 0.58, blue: 0.55, alpha: 1)

  drawRoundedLine(x: 362, y: 594, width: 304, height: 34, color: blue)
  drawRoundedLine(x: 362, y: 508, width: 238, height: 34, color: blue.withAlphaComponent(0.82))
  drawRoundedLine(x: 362, y: 422, width: 286, height: 34, color: blue.withAlphaComponent(0.68))

  for (index, point) in [
    CGPoint(x: 670, y: 502),
    CGPoint(x: 716, y: 462),
    CGPoint(x: 668, y: 420)
  ].enumerated() {
    let dot = NSBezierPath(ovalIn: NSRect(x: point.x, y: point.y, width: 28, height: 28))
    (index == 1 ? teal : teal.withAlphaComponent(0.72)).setFill()
    dot.fill()
  }
}

private func drawRoundedLine(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: NSColor) {
  let path = NSBezierPath(
    roundedRect: NSRect(x: x, y: y, width: width, height: height),
    xRadius: height / 2,
    yRadius: height / 2
  )
  color.setFill()
  path.fill()
}

private enum IconGenerationError: Error {
  case bitmapCreationFailed
  case graphicsContextCreationFailed
  case iconutilFailed(Int32)
  case pngEncodingFailed
}

private extension FileManager {
  func removeItemIfPresent(at url: URL) throws {
    guard fileExists(atPath: url.path) else {
      return
    }

    try removeItem(at: url)
  }
}
