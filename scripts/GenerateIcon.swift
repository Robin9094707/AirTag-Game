import AppKit
import CoreGraphics
import Foundation

let dimension = 1024
let space = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(data: nil, width: dimension, height: dimension,
                              bitsPerComponent: 8, bytesPerRow: 0, space: space,
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    fatalError("Could not start icon renderer")
}
func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [r, g, b, a])!
}
context.setFillColor(rgb(0.025, 0.04, 0.13))
context.fill(CGRect(x: 0, y: 0, width: dimension, height: dimension))
for index in 0..<16 {
    let inset = CGFloat(index * 35)
    context.setStrokeColor(rgb(0.10, 0.72, 0.95, 0.08))
    context.setLineWidth(3)
    context.stroke(CGRect(x: inset, y: inset, width: CGFloat(dimension)-inset*2,
                        height: CGFloat(dimension)-inset*2))
}
context.setFillColor(rgb(0.04, 0.26, 0.41))
context.fillEllipse(in: CGRect(x: 150, y: 150, width: 724, height: 724))
context.setStrokeColor(rgb(0.18, 0.91, 0.98))
context.setLineWidth(24)
context.strokeEllipse(in: CGRect(x: 145, y: 145, width: 734, height: 734))
context.setFillColor(rgb(0.91, 0.97, 1))
context.fillEllipse(in: CGRect(x: 235, y: 235, width: 554, height: 554))
context.setFillColor(rgb(0.09, 0.17, 0.27))
context.fillEllipse(in: CGRect(x: 330, y: 330, width: 364, height: 364))
context.setStrokeColor(rgb(0.23, 0.92, 0.98))
context.setLineWidth(34)
context.addArc(center: CGPoint(x: 512, y: 512), radius: 106,
               startAngle: .pi * 0.28, endAngle: .pi * 0.72, clockwise: false)
context.strokePath()
context.addArc(center: CGPoint(x: 512, y: 512), radius: 106,
               startAngle: .pi * 1.28, endAngle: .pi * 1.72, clockwise: false)
context.strokePath()
context.setFillColor(rgb(0.30, 0.94, 1))
context.fillEllipse(in: CGRect(x: 484, y: 484, width: 56, height: 56))
guard let image = context.makeImage(),
      let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
else { fatalError("Could not encode icon") }
let folder = "AirTagQuest/Assets.xcassets/AppIcon.appiconset"
try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
try data.write(to: URL(fileURLWithPath: folder + "/AppIcon.png"))
print("Generated 1024px app icon")
