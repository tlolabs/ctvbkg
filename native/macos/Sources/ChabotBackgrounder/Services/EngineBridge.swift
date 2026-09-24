import CBackgrounder
import Foundation

// The Rust engine synchronizes snapshot and build access internally.
final class EngineBridge: @unchecked Sendable {
    private let handle: UnsafeMutableRawPointer

    init(folder: URL) throws {
        guard backgrounder_api_version() == 1 else { throw BridgeError.message("Incompatible Rust engine") }
        let ffprobe = ProcessInfo.processInfo.environment["BACKGROUNDER_FFPROBE"]
            ?? Bundle.main.path(forResource: "ffprobe", ofType: nil)
            ?? "ffprobe"
        let pointer = folder.path.withCString { folderCString in
            ffprobe.withCString { probeCString in backgrounder_create(folderCString, probeCString) }
        }
        guard let pointer else { throw BridgeError.message(Self.takeString(backgrounder_last_error())) }
        handle = pointer
    }

    deinit { backgrounder_destroy(handle) }

    func snapshot() throws -> EngineSnapshot {
        guard let raw = backgrounder_snapshot(handle) else { throw BridgeError.message(Self.takeString(backgrounder_last_error())) }
        return try JSONDecoder().decode(EngineSnapshot.self, from: Self.takeString(raw).data(using: .utf8)!)
    }

    func build() throws -> BuildResponse.Result {
        guard let raw = backgrounder_build(handle) else { throw BridgeError.message(Self.takeString(backgrounder_last_error())) }
        let response = try JSONDecoder().decode(BuildResponse.self, from: Self.takeString(raw).data(using: .utf8)!)
        guard response.ok, let result = response.result else { throw BridgeError.message(response.error ?? "Build failed") }
        return result
    }

    func refresh() { backgrounder_refresh(handle) }

    private static func takeString(_ value: UnsafeMutablePointer<CChar>?) -> String {
        guard let value else { return "Unknown engine error" }
        let text = String(cString: value)
        backgrounder_free_string(value)
        return text
    }
}

enum BridgeError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        if case .message(let message) = self { return message }
        return nil
    }
}
