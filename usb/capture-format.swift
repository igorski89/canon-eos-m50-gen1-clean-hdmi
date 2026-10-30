// Show or set the active format of the HDMI capture dongle ("USB Video").
//
// The dongle offers many 4:3 modes and scales the camera's 16:9 HDMI into
// whichever one an app picks, squeezing the picture. The active format is
// shared per device, so setting it here carries over to Zoom, QuickTime, etc.
//
//   swift capture-format.swift                  # list modes, show active
//   swift capture-format.swift 1920x1080 [FPS]  # set active format (default 30 fps)
import AVFoundation

let deviceName = ProcessInfo.processInfo.environment["CAPTURE_DEVICE"] ?? "USB Video"

let discovery = AVCaptureDevice.DiscoverySession(
    deviceTypes: [.external], mediaType: .video, position: .unspecified)
guard let device = discovery.devices.first(where: { $0.localizedName == deviceName }) else {
    FileHandle.standardError.write("No capture device named \"\(deviceName)\"\n".data(using: .utf8)!)
    exit(1)
}

func describe(_ f: AVCaptureDevice.Format) -> String {
    let d = CMVideoFormatDescriptionGetDimensions(f.formatDescription)
    let rates = f.videoSupportedFrameRateRanges.map { String(format: "%.0f", $0.maxFrameRate) }
    return "\(d.width)x\(d.height) @ \(rates.joined(separator: ","))"
}

let args = CommandLine.arguments.dropFirst()
guard let size = args.first else {
    for f in device.formats { print(describe(f)) }
    print("active: \(describe(device.activeFormat))")
    exit(0)
}

let wh = size.split(separator: "x").compactMap { Int32($0) }
let fps = Double(args.dropFirst().first ?? "30") ?? 30
guard wh.count == 2 else {
    FileHandle.standardError.write("Size must look like 1920x1080\n".data(using: .utf8)!)
    exit(2)
}

// The dongle's rates are inexact (e.g. 30.00003), so reuse the device's own
// frame-rate range rather than constructing 1/fps, which it rejects.
func rangeFor(_ f: AVCaptureDevice.Format) -> AVFrameRateRange? {
    let d = CMVideoFormatDescriptionGetDimensions(f.formatDescription)
    guard d.width == wh[0], d.height == wh[1] else { return nil }
    return f.videoSupportedFrameRateRanges.first(where: { abs($0.maxFrameRate - fps) < 0.5 })
}

// Already at the requested size *and* rate: leave it alone so a running stream
// is not disturbed (clean-hdmi.sh calls this every few seconds as a watchdog).
// Size alone is not enough: the dongle also has an uncompressed 1920x1080
// format limited to 5 fps, which QuickTime's "Maximum" quality selects.
if let r = rangeFor(device.activeFormat),
   abs(device.activeVideoMinFrameDuration.seconds - r.minFrameDuration.seconds) < 0.001 {
    print("unchanged: \(describe(device.activeFormat))")
    exit(0)
}

var match: (AVCaptureDevice.Format, AVFrameRateRange)?
for f in device.formats {
    if let r = rangeFor(f) {
        match = (f, r)
        break
    }
}
guard let (format, range) = match else {
    FileHandle.standardError.write("Device has no \(size) @ \(fps) fps mode\n".data(using: .utf8)!)
    exit(3)
}

do {
    try device.lockForConfiguration()
    device.activeFormat = format
    device.activeVideoMinFrameDuration = range.minFrameDuration
    device.unlockForConfiguration()
} catch {
    FileHandle.standardError.write("Could not configure device: \(error)\n".data(using: .utf8)!)
    exit(4)
}
print("active: \(describe(device.activeFormat))")
