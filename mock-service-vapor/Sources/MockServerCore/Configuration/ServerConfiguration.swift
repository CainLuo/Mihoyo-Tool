import Foundation

/// Mock Server 的运行期配置。
///
/// 字段来源分三类：
/// - 命令行参数（`--port` / `--host` / `--delay` / `--fixtures`），优先级最高；
/// - 环境变量（`MOCK_PORT` / `MOCK_HOST` / `MOCK_DELAY` / `MOCK_FIXTURES`），作为参数缺省值；
/// - 代码内置默认值（与 Node `mock-service/server.mjs` 保持一致）。
public struct ServerConfiguration: Sendable, Equatable {
    /// 监听地址。默认 `127.0.0.1`，只允许本机访问；传 `0.0.0.0` 才会暴露到局域网。
    public var host: String
    /// 监听端口。默认 8787，和 App 侧 `http://127.0.0.1:8787` 的约定一致。
    public var port: Int
    /// 每个响应前的人为延迟（毫秒）。默认 300ms，方便在 App 上观察 loading 态；`0` 表示关闭。
    public var delayMilliseconds: Int
    /// fixture 根目录。默认指向仓库内已被 Node 服务复用的 `mock-service/fixtures`，不做任何拷贝。
    public var fixturesDirectory: URL
    /// 请求体上限（字节）。默认 8 MiB，超过时返回 400，避免把大文件读进内存。
    public var maxBodyBytes: Int

    public init(
        host: String = ServerConfiguration.defaultHost,
        port: Int = ServerConfiguration.defaultPort,
        delayMilliseconds: Int = ServerConfiguration.defaultDelayMilliseconds,
        fixturesDirectory: URL = ServerConfiguration.defaultFixturesDirectory(),
        maxBodyBytes: Int = ServerConfiguration.defaultMaxBodyBytes
    ) {
        self.host = host
        self.port = port
        self.delayMilliseconds = delayMilliseconds
        self.fixturesDirectory = fixturesDirectory
        self.maxBodyBytes = maxBodyBytes
    }
}

public extension ServerConfiguration {
    /// 默认只监听回环地址，避免 mock 数据被局域网其他机器读到。
    static let defaultHost = "127.0.0.1"
    /// Node 版与 App 侧约定的默认端口。
    static let defaultPort = 8787
    /// Node 版的默认模拟延迟。
    static let defaultDelayMilliseconds = 300
    /// 与 Node 版 `MAX_BODY_BYTES` 一致的 8 MiB 上限。
    static let defaultMaxBodyBytes = 8 * 1024 * 1024

    /// 从当前工作目录向上查找 `mock-service/fixtures`。
    ///
    /// 这样无论从仓库根目录还是从 `mock-service-vapor/` 里启动，都能命中同一份 fixtures，
    /// 不需要复制数据，也不要求调用方额外传 `--fixtures`。
    static func defaultFixturesDirectory(
        startingAt directory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true),
        fileManager: FileManager = .default
    ) -> URL {
        var current = directory.standardizedFileURL
        for _ in 0..<6 {
            let candidate = current.appendingPathComponent("mock-service/fixtures", isDirectory: true)
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: candidate.path, isDirectory: &isDirectory), isDirectory.boolValue {
                return candidate
            }
            let parent = current.deletingLastPathComponent()
            if parent.path == current.path { break }
            current = parent
        }
        return directory.standardizedFileURL.appendingPathComponent("mock-service/fixtures", isDirectory: true)
    }

    /// 解析命令行参数。
    ///
    /// 兼容 Node 版的四种写法：`--port`、`--host`、`--delay`、`--fixtures`；
    /// 非法或缺失的数值保持默认值，避免启动直接失败。
    static func from(
        arguments: [String],
        environment: [String: String] = ProcessInfo.processInfo.environment,
        defaultFixturesDirectory: URL = ServerConfiguration.defaultFixturesDirectory()
    ) -> ServerConfiguration {
        func value(for flag: String) -> String? {
            guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else {
                return nil
            }
            return arguments[index + 1]
        }

        let portText = value(for: "--port") ?? environment["MOCK_PORT"]
        let port = portText.flatMap(Int.init) ?? defaultPort

        let host = value(for: "--host") ?? environment["MOCK_HOST"] ?? defaultHost

        let delayText = value(for: "--delay") ?? environment["MOCK_DELAY"]
        // 负延迟视为关闭，不做 sleep。
        let delay = max(0, delayText.flatMap(Int.init) ?? defaultDelayMilliseconds)

        let fixturesText = value(for: "--fixtures") ?? environment["MOCK_FIXTURES"]
        let fixtures = fixturesText.map {
            URL(fileURLWithPath: $0, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true))
                .standardizedFileURL
        } ?? defaultFixturesDirectory

        return ServerConfiguration(
            host: host,
            port: port,
            delayMilliseconds: delay,
            fixturesDirectory: fixtures
        )
    }

    /// 帮助文本，供 `mock-server --help` 使用。
    static var usage: String {
        """
        用法: mock-server [选项]

          --port <端口>       监听端口（默认 \(defaultPort)）
          --host <地址>       监听地址（默认 \(defaultHost)，仅本机）
          --delay <毫秒>      模拟延迟，0 表示关闭（默认 \(defaultDelayMilliseconds)）
          --fixtures <目录>   fixture 根目录（默认自动查找 mock-service/fixtures）
          --help             显示本帮助

        环境变量: MOCK_PORT / MOCK_HOST / MOCK_DELAY / MOCK_FIXTURES
        """
    }
}
