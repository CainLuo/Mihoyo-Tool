import Foundation

/// 一份已读取的 fixture。
public struct Fixture: Sendable, Equatable {
    /// 相对 fixtures 根目录的路径，例如 `182692936/109050292/game_record_app_genshin_api_dailyNote.json`。
    public let relativePath: String
    /// 文件原始字节。HTTP 层直接回写，避免重新编码改变字段顺序或数值类型。
    public let data: Data

    public init(relativePath: String, data: Data) {
        self.relativePath = relativePath
        self.data = data
    }

    /// 解析后的 JSON；解析失败为 nil。
    public var json: JSONValue? {
        try? JSONValue(parsing: data)
    }

    /// 文件大小（字节），用于健康检查与日志。
    public var byteCount: Int {
        data.count
    }
}

/// 一次查询的结果：候选路径 + 命中的文件。
public struct FixtureLookup: Sendable {
    /// 解析出的账号 / 角色 / 文件名。
    public let resolution: FixtureResolution
    /// 命中的 fixture；全部候选都缺失时为 nil。
    public let fixture: Fixture?

    public init(resolution: FixtureResolution, fixture: Fixture?) {
        self.resolution = resolution
        self.fixture = fixture
    }

    /// 命中的相对路径，缺失时为 nil。日志与测试都用它。
    public var file: String? {
        fixture?.relativePath
    }
}

/// 只读的 fixture 仓库。
///
/// 复用仓库里已有的 `mock-service/fixtures`，不复制、不打包进 App。
/// 所有读取都限制在根目录内，防止 `../` 路径穿越读到仓库其他文件。
public struct FixtureStore: Sendable {
    /// fixtures 根目录（绝对路径）。
    public let root: URL

    public init(root: URL) {
        self.root = root.standardizedFileURL
    }

    /// 读取指定相对路径的 fixture。
    ///
    /// - 相对路径不在根目录内 → nil；
    /// - 文件不存在 / 不可读 → nil（调用方回退到空响应）。
    public func load(relativePath: String) -> Fixture? {
        let trimmed = relativePath.hasPrefix("/") ? String(relativePath.dropFirst()) : relativePath
        guard !trimmed.isEmpty else { return nil }

        let fullURL = root.appendingPathComponent(trimmed).standardizedFileURL
        let rootPath = root.path.hasSuffix("/") ? root.path : root.path + "/"
        guard fullURL.path == root.path || fullURL.path.hasPrefix(rootPath) else {
            return nil
        }
        guard let data = try? Data(contentsOf: fullURL) else {
            return nil
        }
        return Fixture(relativePath: trimmed, data: data)
    }

    /// 按候选顺序查找，返回第一个存在的 fixture。
    public func find(candidates: [String]) -> Fixture? {
        for candidate in candidates {
            if let fixture = load(relativePath: candidate) {
                return fixture
            }
        }
        return nil
    }

    /// 解析查询并查找 fixture。
    public func lookup(_ query: FixtureQuery) -> FixtureLookup {
        let resolution = FixtureResolver.resolve(query)
        let fixture = find(candidates: resolution.candidates)
        return FixtureLookup(resolution: resolution, fixture: fixture)
    }

    /// 递归统计 `.json` fixture 数量（健康检查里的 `fixtures` 字段）。
    public func count() -> Int {
        allRelativePaths().count
    }

    /// 列出全部 fixture 的相对路径，按字典序排序，便于测试与排查缺口。
    public func allRelativePaths() -> [String] {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var paths: [String] = []
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "json" else { continue }
            let relative = fileURL.path.replacingOccurrences(of: root.path + "/", with: "")
            paths.append(relative)
        }
        return paths.sorted()
    }

    /// fixtures 根目录是否真实存在。
    public var exists: Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}
