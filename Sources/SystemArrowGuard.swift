import Cocoa
import Darwin

/// Keep the restore owner outside Tappy: closing the control pipe (including a
/// Tappy crash) restores the exact arrow images that were present on activation.
final class SystemArrowGuard {
    private let helper: URL
    private let timeout: Int32
    private var process: Process?
    private var control: Pipe?
    private var response: Pipe?
    private var retryAfter = -Double.infinity
    var isActive: Bool { process?.isRunning == true }

    init(helper: URL = Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/TappyCursorGuard"), timeout: Int32 = 2000) {
        self.helper = helper; self.timeout = timeout
    }

    static func recoverIfNeeded() {
        let journal = FileManager.default.temporaryDirectory.appendingPathComponent("com.example.tappy.arrow-restore.json")
        guard FileManager.default.fileExists(atPath: journal.path) else { return }
        let helper = Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/TappyCursorGuard")
        guard FileManager.default.isExecutableFile(atPath: helper.path) else { return }
        let recovery = Process(), output = Pipe()
        recovery.executableURL = helper; recovery.arguments = ["--restore-only"]
        recovery.standardInput = FileHandle.nullDevice; recovery.standardOutput = output
        recovery.standardError = FileHandle.nullDevice
        guard (try? recovery.run()) != nil else { return }
        output.fileHandleForWriting.closeFile()
        _ = readReply(from: output, timeout: 2000)
        output.fileHandleForReading.closeFile()
    }

    @discardableResult func start() -> Bool {
        if isActive { return true }
        guard ProcessInfo.processInfo.systemUptime >= retryAfter else { return false }
        stop()
        guard FileManager.default.isExecutableFile(atPath: helper.path) else { return false }
        let process = Process(), control = Pipe(), response = Pipe()
        process.executableURL = helper
        process.standardInput = control
        process.standardOutput = response
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return false }
        // Only the child may hold a reader. EOF must arrive when Tappy dies.
        control.fileHandleForReading.closeFile()
        response.fileHandleForWriting.closeFile()
        self.process = process; self.control = control; self.response = response
        guard Self.readReply(from: response, timeout: timeout) == 49 else {
            stop(); retryAfter = ProcessInfo.processInfo.systemUptime + 5
            return false
        }
        return true
    }
    @discardableResult func stop() -> Bool {
        guard process != nil else { return true }
        control?.fileHandleForWriting.closeFile()
        // Wait for the restore acknowledgement, not for an arbitrary timer.
        var restored = false
        if let response {
            restored = Self.readReply(from: response, timeout: timeout) == 50
            response.fileHandleForReading.closeFile()
        }
        control = nil; response = nil; process = nil
        if !restored { Self.recoverIfNeeded() }
        return restored
    }
    private static func readReply(from response: Pipe, timeout: Int32) -> UInt8? {
        var descriptor = pollfd(fd: response.fileHandleForReading.fileDescriptor, events: Int16(POLLIN | POLLHUP), revents: 0)
        guard poll(&descriptor, 1, timeout) > 0 else { return nil }
        return response.fileHandleForReading.readData(ofLength: 1).first
    }
    deinit { stop() }
}

#if TAPPY_CURSOR_GUARD
/// Uses the cursor registration ABI documented by Mousecape's CGSCursor.h.
/// No preference, theme or on-disk system cursor resource is modified.
private final class ArrowRegistration {
    private typealias Connection = @convention(c) () -> Int32
    private typealias CopyImages = @convention(c) (Int32, UnsafePointer<CChar>, UnsafeMutablePointer<CGSize>, UnsafeMutablePointer<CGPoint>, UnsafeMutablePointer<Int>, UnsafeMutablePointer<Double>, UnsafeMutablePointer<Unmanaged<CFArray>?>) -> Int32
    private typealias RegisterImages = @convention(c) (Int32, UnsafePointer<CChar>, Bool, Bool, CGSize, CGPoint, Int, Double, CFArray, UnsafeMutablePointer<Int32>) -> Int32
    private let library: UnsafeMutableRawPointer
    private let connection: Int32
    private let copyImages: CopyImages
    private let registerImages: RegisterImages
    private let name = "com.apple.coregraphics.Arrow"

    init?() {
        guard let h = dlopen("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics", RTLD_LAZY | RTLD_LOCAL),
              let c = dlsym(h, "CGSMainConnectionID"),
              let copy = dlsym(h, "CGSCopyRegisteredCursorImages"),
              let register = dlsym(h, "CGSRegisterCursorWithImages") else { return nil }
        library = h
        connection = unsafeBitCast(c, to: Connection.self)()
        copyImages = unsafeBitCast(copy, to: CopyImages.self)
        registerImages = unsafeBitCast(register, to: RegisterImages.self)
    }
    deinit { dlclose(library) }
    func snapshot() -> ArrowSnapshot? {
        _ = NSCursor.arrow // Ensure the default image has been registered.
        var size = CGSize.zero, hotSpot = CGPoint.zero, frames = 0, duration = 0.0
        var images: Unmanaged<CFArray>?
        let status = name.withCString { copyImages(connection, $0, &size, &hotSpot, &frames, &duration, &images) }
        guard status == 0, let images else { return nil }
        let array = images.takeRetainedValue() as NSArray
        guard array.count > 0, size.width > 0, size.height > 0, (1...24).contains(frames) else { return nil }
        var pngs: [Data] = []
        for object in array {
            guard CFGetTypeID(object as CFTypeRef) == CGImage.typeID else { return nil }
            let image = object as! CGImage
            guard let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { return nil }
            pngs.append(png)
        }
        return ArrowSnapshot(width: size.width, height: size.height, x: hotSpot.x, y: hotSpot.y, frames: frames, duration: duration, images: pngs)
    }
    func apply(_ snapshot: ArrowSnapshot) -> Bool {
        let images = snapshot.images.compactMap { NSBitmapImageRep(data: $0)?.cgImage }
        guard images.count == snapshot.images.count, !images.isEmpty else { return false }
        var seed: Int32 = 0
        return name.withCString {
            registerImages(connection, $0, true, true,
                CGSize(width: snapshot.width, height: snapshot.height), CGPoint(x: snapshot.x, y: snapshot.y),
                snapshot.frames, snapshot.duration, images as CFArray, &seed) == 0
        }
    }
    func makeTransparent() -> Bool {
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 16, pixelsHigh: 16,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 64, bitsPerPixel: 32), let bytes = bitmap.bitmapData else { return false }
        memset(bytes, 0, 1024)
        guard let png = bitmap.representation(using: .png, properties: [:]) else { return false }
        return apply(ArrowSnapshot(width: 16, height: 16, x: 0, y: 0, frames: 1, duration: 0, images: [png]))
    }
}

private struct ArrowSnapshot: Codable {
    let width: Double, height: Double, x: Double, y: Double
    let frames: Int
    let duration: Double
    let images: [Data]
}

@main private enum CursorGuardMain {
    static func main() {
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.prohibited)
        let root = FileManager.default.temporaryDirectory
        let lockPath = root.appendingPathComponent("com.example.tappy.arrow-guard.lock").path
        let journal = root.appendingPathComponent("com.example.tappy.arrow-restore.json")
        let lock = open(lockPath, O_CREAT | O_RDWR | O_CLOEXEC, S_IRUSR | S_IWUSR)
        let recoveryOnly = CommandLine.arguments.contains("--restore-only")
        guard lock >= 0, flock(lock, recoveryOnly ? LOCK_EX : LOCK_EX | LOCK_NB) == 0 else { return }
        defer { close(lock) }
        guard let registration = ArrowRegistration() else { return }
        // Recover a journal left by a killed helper before taking a new backup.
        if FileManager.default.fileExists(atPath: journal.path) {
            guard let data = try? Data(contentsOf: journal),
                  let previous = try? JSONDecoder().decode(ArrowSnapshot.self, from: data),
                  registration.apply(previous) else { return }
            try? FileManager.default.removeItem(at: journal)
        }
        if recoveryOnly {
            flock(lock, LOCK_UN)
            FileHandle.standardOutput.write(Data([50]))
            return
        }
        guard let original = registration.snapshot(),
              let data = try? JSONEncoder().encode(original) else { return }
        do {
            try data.write(to: journal, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: journal.path)
        } catch { return }
        defer {
            let restored = registration.apply(original)
            if restored { try? FileManager.default.removeItem(at: journal) }
            // A new activation may follow the acknowledgement immediately.
            flock(lock, LOCK_UN)
            FileHandle.standardOutput.write(Data([restored ? 50 : 51]))
        }
        guard registration.makeTransparent() else { return }
        FileHandle.standardOutput.write(Data([49])) // installed, backup safely stored
        // No run loop, input interception or permissions: the parent's pipe is
        // the lifetime. Its last writer closes on disable, quit or crash.
        while !FileHandle.standardInput.readData(ofLength: 1).isEmpty {}
    }
}
#endif
