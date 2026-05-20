#!/usr/bin/env swift

import AppKit
import Foundation

let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconsetURL = rootURL.appendingPathComponent(".build/icon/Clack.iconset")
let iconURL = rootURL.appendingPathComponent("Packaging/Clack.icns")
let menuBarTemplateURL = rootURL.appendingPathComponent("Packaging/ClackMenuBarTemplate.png")

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

try drawMenuBarTemplateIcon(pixels: 64, to: menuBarTemplateURL)

print(iconURL.path)
print(menuBarTemplateURL.path)

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
  drawYellowFold()
  drawDocument()

  NSGraphicsContext.restoreGraphicsState()

  guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    throw IconGenerationError.pngEncodingFailed
  }

  try pngData.write(to: url)
}

private func drawBase() {
  let rect = NSRect(x: 96, y: 96, width: 832, height: 832)
  let basePath = NSBezierPath(roundedRect: rect, xRadius: 178, yRadius: 178)
  let context = NSGraphicsContext.current?.cgContext

  context?.saveGState()
  context?.setShadow(
    offset: CGSize(width: 0, height: -22),
    blur: 48,
    color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.46)
  )
  basePath.addClip()
  NSGradient(colors: [
    NSColor(calibratedWhite: 0.17, alpha: 1),
    NSColor(calibratedWhite: 0.11, alpha: 1),
    NSColor(calibratedWhite: 0.07, alpha: 1)
  ])?.draw(in: rect, angle: -35)
  context?.restoreGState()

  NSColor(calibratedWhite: 0, alpha: 0.10).setStroke()
  basePath.lineWidth = 2
  basePath.stroke()
}

private func drawYellowFold() {
  let context = NSGraphicsContext.current?.cgContext

  context?.saveGState()
  context?.setShadow(
    offset: CGSize(width: 0, height: -14),
    blur: 28,
    color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.36)
  )

  let fold = yellowFoldPath()
  fold.addClip()
  NSGradient(colors: [
    NSColor(calibratedRed: 1.00, green: 0.77, blue: 0.17, alpha: 1),
    NSColor(calibratedRed: 1.00, green: 0.52, blue: 0.00, alpha: 1)
  ])?.draw(in: NSRect(x: 256, y: 210, width: 420, height: 470), angle: 104)
  context?.restoreGState()
}

private func drawDocument() {
  let context = NSGraphicsContext.current?.cgContext

  context?.saveGState()
  context?.setShadow(
    offset: CGSize(width: 0, height: -16),
    blur: 32,
    color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.38)
  )

  let document = documentPath()

  document.addClip()
  NSGradient(colors: [
    NSColor(calibratedWhite: 1.00, alpha: 1),
    NSColor(calibratedWhite: 0.93, alpha: 1)
  ])?.draw(in: NSRect(x: 370, y: 320, width: 390, height: 470), angle: -42)
  context?.restoreGState()
}

private func drawMenuBarTemplateIcon(pixels: Int, to url: URL) throws {
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

  let sourceBounds = NSRect(x: 250, y: 200, width: 510, height: 620)
  let padding = CGFloat(pixels) * 0.12
  let scale = (CGFloat(pixels) - (padding * 2)) / sourceBounds.height
  let horizontalInset = (CGFloat(pixels) - (sourceBounds.width * scale)) / 2

  graphicsContext.cgContext.translateBy(
    x: horizontalInset - (sourceBounds.minX * scale),
    y: padding - (sourceBounds.minY * scale)
  )
  graphicsContext.cgContext.scaleBy(x: scale, y: scale)

  NSColor.black.setFill()
  yellowFoldPath().fill()
  documentPath().fill()

  NSGraphicsContext.restoreGraphicsState()

  guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    throw IconGenerationError.pngEncodingFailed
  }

  try pngData.write(to: url)
}

private func yellowFoldPath() -> NSBezierPath {
  let fold = NSBezierPath()
  fold.move(to: NSPoint(x: 355, y: 650))
  fold.line(to: NSPoint(x: 313, y: 650))
  fold.curve(
    to: NSPoint(x: 276, y: 613),
    controlPoint1: NSPoint(x: 292, y: 650),
    controlPoint2: NSPoint(x: 276, y: 634)
  )
  fold.line(to: NSPoint(x: 276, y: 468))
  fold.curve(
    to: NSPoint(x: 319, y: 380),
    controlPoint1: NSPoint(x: 276, y: 430),
    controlPoint2: NSPoint(x: 291, y: 405)
  )
  fold.line(to: NSPoint(x: 439, y: 260))
  fold.curve(
    to: NSPoint(x: 500, y: 224),
    controlPoint1: NSPoint(x: 457, y: 242),
    controlPoint2: NSPoint(x: 476, y: 224)
  )
  fold.line(to: NSPoint(x: 610, y: 224))
  fold.curve(
    to: NSPoint(x: 652, y: 266),
    controlPoint1: NSPoint(x: 636, y: 224),
    controlPoint2: NSPoint(x: 652, y: 240)
  )
  fold.line(to: NSPoint(x: 652, y: 321))
  fold.line(to: NSPoint(x: 593, y: 321))
  fold.curve(
    to: NSPoint(x: 548, y: 339),
    controlPoint1: NSPoint(x: 576, y: 321),
    controlPoint2: NSPoint(x: 561, y: 326)
  )
  fold.line(to: NSPoint(x: 369, y: 518))
  fold.curve(
    to: NSPoint(x: 355, y: 552),
    controlPoint1: NSPoint(x: 360, y: 527),
    controlPoint2: NSPoint(x: 355, y: 538)
  )
  fold.close()
  return fold
}

private func documentPath() -> NSBezierPath {
  let document = NSBezierPath()
  document.move(to: NSPoint(x: 431, y: 772))
  document.line(to: NSPoint(x: 574, y: 772))
  document.curve(
    to: NSPoint(x: 619, y: 754),
    controlPoint1: NSPoint(x: 592, y: 772),
    controlPoint2: NSPoint(x: 608, y: 766)
  )
  document.line(to: NSPoint(x: 712, y: 661))
  document.curve(
    to: NSPoint(x: 733, y: 611),
    controlPoint1: NSPoint(x: 726, y: 647),
    controlPoint2: NSPoint(x: 733, y: 630)
  )
  document.line(to: NSPoint(x: 733, y: 382))
  document.curve(
    to: NSPoint(x: 684, y: 333),
    controlPoint1: NSPoint(x: 733, y: 354),
    controlPoint2: NSPoint(x: 712, y: 333)
  )
  document.line(to: NSPoint(x: 611, y: 333))
  document.curve(
    to: NSPoint(x: 566, y: 352),
    controlPoint1: NSPoint(x: 593, y: 333),
    controlPoint2: NSPoint(x: 578, y: 340)
  )
  document.line(to: NSPoint(x: 406, y: 512))
  document.curve(
    to: NSPoint(x: 392, y: 547),
    controlPoint1: NSPoint(x: 397, y: 521),
    controlPoint2: NSPoint(x: 392, y: 532)
  )
  document.line(to: NSPoint(x: 392, y: 731))
  document.curve(
    to: NSPoint(x: 431, y: 772),
    controlPoint1: NSPoint(x: 392, y: 755),
    controlPoint2: NSPoint(x: 407, y: 772)
  )
  document.close()
  return document
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
