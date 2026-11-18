import Cocoa
import Darwin

/// A process-scoped lock works across installed, downloaded and locally built
/// copies. The OS releases it on quit or crash; a stale lock file is harmless.
final class SingleInstance {
    private var descriptor: Int32 = -1
    private let path: String
    init(path: String = FileManager.default.temporaryDirectory.appendingPathComponent("com.example.tappy.instance.lock").path) { self.path = path }
    func acquire() -> Bool {
        guard descriptor < 0 else { return true }
        let candidate = open(path, O_CREAT | O_RDWR | O_CLOEXEC, S_IRUSR | S_IWUSR)
        guard candidate >= 0 else { return false }
        guard flock(candidate, LOCK_EX | LOCK_NB) == 0 else { close(candidate); return false }
        descriptor = candidate
        return true
    }
    func release() {
        guard descriptor >= 0 else { return }
        flock(descriptor, LOCK_UN); close(descriptor); descriptor = -1
    }
    deinit { release() }
}
