import Cocoa
import Darwin

protocol CursorVisibilityBackend: AnyObject {
    var isVisible: Bool? { get }
    func setBackgroundControl(_ enabled: Bool) -> Bool
    func setArrowTransparent(_ transparent: Bool) -> Bool
    func setCaptureCursorTransparent(_ transparent: Bool)
    func hide() -> Bool
    func show() -> Bool
}

/// Owns exactly one balanced hide request, and repairs it when macOS restores
/// the cursor after an application, Space, menu or display transition.
final class SystemCursorController {
    private let backend: CursorVisibilityBackend
    private var requestedHidden = false
    private(set) var ownsHide = false
    private var lastCheck = -Double.infinity
    private var lastReassertion = -Double.infinity
    private var lastCapturePublish = -Double.infinity
    private var protectsArrowImage = false

    init(backend: CursorVisibilityBackend = WindowServerCursorBackend()) { self.backend = backend }

    func setHidden(_ hidden: Bool) {
        requestedHidden = hidden
        refresh(force: true)
    }

    func refresh(force: Bool = false, cursorMoved: Bool = false, at time: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        guard force || time - lastCheck >= 1.0 / 120.0 else { return }
        lastCheck = time
        guard requestedHidden else {
            if releaseHide() {
                _ = backend.setArrowTransparent(false)
                backend.setCaptureCursorTransparent(false)
                protectsArrowImage = false
                _ = backend.setBackgroundControl(false)
            }
            return
        }
        if force || !ownsHide {
            _ = backend.setBackgroundControl(true)
            protectsArrowImage = backend.setArrowTransparent(true)
        }
        let visible = backend.isVisible
        // Dock may force a visible arrow despite a hidden Quartz flag. A guarded
        // transparent system image covers that path; retain the balanced hide
        // fallback when image registration is unavailable.
        let heartbeatDue = time - lastReassertion >= 0.2
        // WebRTC captures the cursor image separately from the framebuffer and
        // does not consult the Quartz hide count. Publish a real transparent
        // current cursor, including after another app changes its cursor shape.
        if force || cursorMoved || time - lastCapturePublish >= 0.2 {
            backend.setCaptureCursorTransparent(true)
            lastCapturePublish = time
        }
        let needsFallback = !protectsArrowImage && (force || cursorMoved || heartbeatDue)
        guard !ownsHide || visible == true || needsFallback else { return }
        // Never accumulate hide calls in the tracking loop. Release our previous
        // request before reasserting it; a failed release remains owned for retry.
        guard releaseHide() else { return }
        _ = backend.setBackgroundControl(true)
        if backend.hide() { ownsHide = true; lastReassertion = time }
    }

    @discardableResult private func releaseHide() -> Bool {
        guard ownsHide else { return true }
        guard backend.show() else { return false }
        ownsHide = false
        return true
    }
    deinit {
        if releaseHide() {
            _ = backend.setArrowTransparent(false)
            backend.setCaptureCursorTransparent(false)
            _ = backend.setBackgroundControl(false)
        }
    }
}

/// A nonempty RGBA image lets capture clients replace their cached arrow with
/// transparent pixels. An absent image would leave the previous shape cached.
enum CaptureCursorImage {
    static func make() -> NSCursor? {
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 16, pixelsHigh: 16,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 64, bitsPerPixel: 32),
              let bytes = bitmap.bitmapData else { return nil }
        memset(bytes, 0, bitmap.bytesPerRow * bitmap.pixelsHigh)
        let image = NSImage(size: NSSize(width: 16, height: 16))
        image.addRepresentation(bitmap)
        return NSCursor(image: image, hotSpot: .zero)
    }
}

/// Quartz normally limits cursor control to the frontmost application. The
/// background-agent connection property allows this process to keep the cursor
/// hidden while the user continues working in another app, without taking focus.
/// Resolve the optional WindowServer symbols at runtime so missing symbols do
/// not prevent launch. CoreGraphics still provides the balanced hide/show calls.
final class WindowServerCursorBackend: CursorVisibilityBackend {
    private typealias ConnectionID = @convention(c) () -> Int32
    private typealias SetProperty = @convention(c) (Int32, Int32, CFString, CFBoolean) -> Int32
    private typealias CursorVisible = @convention(c) () -> UInt32
    private let handle: UnsafeMutableRawPointer?
    private let connection: ConnectionID?
    private let setProperty: SetProperty?
    private let cursorVisible: CursorVisible?
    private let arrowGuard = SystemArrowGuard()
    private let captureCursor = CaptureCursorImage.make()
    private var originalCursor: NSCursor?
    private var publishesCaptureCursor = false

    init() {
        let library = dlopen("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics", RTLD_LAZY | RTLD_LOCAL)
        handle = library
        if let library {
            connection = Self.resolve("CGSMainConnectionID", from: library, as: ConnectionID.self)
                ?? Self.resolve("_CGSDefaultConnection", from: library, as: ConnectionID.self)
            setProperty = Self.resolve("CGSSetConnectionProperty", from: library, as: SetProperty.self)
            cursorVisible = Self.resolve("CGCursorIsVisible", from: library, as: CursorVisible.self)
        } else { connection = nil; setProperty = nil; cursorVisible = nil }
    }
    private static func resolve<T>(_ symbol: String, from handle: UnsafeMutableRawPointer, as type: T.Type) -> T? {
        guard let address = dlsym(handle, symbol) else { return nil }
        return unsafeBitCast(address, to: T.self)
    }
    var isVisible: Bool? { cursorVisible.map { $0() != 0 } }
    func setBackgroundControl(_ enabled: Bool) -> Bool {
        guard let connection, let setProperty else { return false }
        let id = connection()
        let value: CFBoolean = enabled ? kCFBooleanTrue : kCFBooleanFalse
        return setProperty(id, id, "SetsCursorInBackground" as CFString, value) == 0
    }
    func hide() -> Bool { CGDisplayHideCursor(CGMainDisplayID()) == .success }
    func show() -> Bool { CGDisplayShowCursor(CGMainDisplayID()) == .success }
    func setArrowTransparent(_ transparent: Bool) -> Bool {
        if transparent {
            // Save before the global arrow image is replaced, once per lease.
            if originalCursor == nil { originalCursor = NSCursor.currentSystem ?? .arrow }
            return arrowGuard.start()
        }
        arrowGuard.stop()
        return true
    }
    func setCaptureCursorTransparent(_ transparent: Bool) {
        if transparent {
            guard let captureCursor else { return }
            if originalCursor == nil { originalCursor = NSCursor.currentSystem ?? .arrow }
            captureCursor.set()
            publishesCaptureCursor = true
        } else {
            if publishesCaptureCursor { (originalCursor ?? .arrow).set() }
            originalCursor = nil
            publishesCaptureCursor = false
        }
    }
    deinit { if let handle { dlclose(handle) } }
}
