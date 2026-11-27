import Foundation

/// 一次 fixture 查询的输入。
///
/// 对应 Node `buildFixtureResponse(fixturesDir, input)` 的第二个参数。
/// 所有字段都可缺省，允许 RPC 只传 path 就能拿到账号级 fixture。
public struct FixtureQuery: Equatable, Sendable {
    /// API 路径，可带 query 或完整 URL。
    public var path: String
    /// Cookie 原文，用于提取 accountId。
    public var cookie: String
    /// 调用方显式指定的角色 ID，优先级高于 query/body。
    public var roleId: String?
    /// 调用方显式指定的 avatarId，优先级高于 `id_list[]`。
    public var avatarId: String?
    /// 请求体原文（JSON 字符串），用于兜底提取 role_id / uid。
    public var body: String?
    /// 缺失 fixture 时是否返回 `{list: []}` 形式。
    public var fallbackEmptyList: Bool

    public init(
        path: String,
        cookie: String = "",
        roleId: String? = nil,
        avatarId: String? = nil,
        body: String? = nil,
        fallbackEmptyList: Bool = false
    ) {
        self.path = path
        self.cookie = cookie
        self.roleId = roleId
        self.avatarId = avatarId
        self.body = body
        self.fallbackEmptyList = fallbackEmptyList
    }
}

/// 解析结果。保留中间量是为了日志里能看清「为什么没命中」。
public struct FixtureResolution: Equatable, Sendable {
    /// 从 Cookie 提取的账号 ID。
    public var accountId: Int
    /// 角色 ID；空串表示账号级请求。
    public var roleId: String
    /// 角色头像 / 计算用的 avatarId；空串表示不涉及。
    public var avatarId: String
    /// 实际查找的文件名（可能含 `avatar_compute/` 前缀）。
    public var fileName: String
    /// 按优先级排列的候选相对路径。
    public var candidates: [String]

    public init(accountId: Int, roleId: String, avatarId: String, fileName: String, candidates: [String]) {
        self.accountId = accountId
        self.roleId = roleId
        self.avatarId = avatarId
        self.fileName = fileName
        self.candidates = candidates
    }
}

/// 决定去哪些相对路径找 fixture。
///
/// 优先级：
/// 1. `{accountId}/{roleId}/{fileName}`
/// 2. `{accountId}/{fileName}`
///
/// 计算类接口在有 avatarId 时，文件名换成 `avatar_compute/{avatarId}.json`，
/// 因此绝区零角色详情（`id_list[]`）需要特殊处理。
public enum FixtureResolver {
    /// 从 Cookie 提取 accountId。
    public static func extractAccountId(cookie: String) -> Int {
        CookieParser.accountId(from: cookie)
    }

    /// 从 query 或 body 提取 roleId。
    ///
    /// 顺序与 Node 版一致：query 的 `role_id` → query 的 `uid` → body 的 `role_id` → body 的 `uid`。
    public static func extractRoleId(path: String, body: String?) -> String {
        let query = QueryParameters(rawQuery: QueryParameters.rawQuery(fromURL: path))
        if let roleId = query.first("role_id"), !roleId.isEmpty {
            return roleId
        }
        if let uid = query.first("uid"), !uid.isEmpty {
            return uid
        }
        guard let body, !body.isEmpty else { return "" }
        guard let parsed = try? JSONValue(parsing: body), case .object = parsed else { return "" }
        if let roleId = parsed["role_id"]?.stringValue, !roleId.isEmpty {
            return roleId
        }
        if let uid = parsed["uid"]?.stringValue, !uid.isEmpty {
            return uid
        }
        return ""
    }

    /// 绝区零角色详情：从 query 的 `id_list[]` 取第一个元素。
    public static func extractZZZAvatarId(path: String) -> String {
        let query = QueryParameters(rawQuery: QueryParameters.rawQuery(fromURL: path))
        return query.all("id_list[]").first ?? ""
    }

    /// 该路径是否是绝区零角色详情接口。
    public static func isZZZAvatarInfo(path: String) -> Bool {
        FixturePathMapper.cleanPath(path).contains("/event/game_record_zzz/api/zzz/avatar/info")
    }

    /// 完整的候选路径计算。
    public static func resolve(_ input: FixtureQuery) -> FixtureResolution {
        let requestPath = FixturePathMapper.normalizePath(input.path)
        let pathOnly = FixturePathMapper.cleanPath(requestPath)
        let accountId = extractAccountId(cookie: input.cookie)

        let explicitRole = input.roleId.map { $0.trimmingCharacters(in: .whitespaces) } ?? ""
        let roleId = explicitRole.isEmpty ? extractRoleId(path: requestPath, body: input.body) : explicitRole

        var avatarId = input.avatarId?.trimmingCharacters(in: .whitespaces) ?? ""
        if avatarId.isEmpty, isZZZAvatarInfo(path: pathOnly) {
            avatarId = extractZZZAvatarId(path: requestPath)
        }

        let fileName: String
        if !avatarId.isEmpty, pathOnly.contains("compute") || pathOnly.contains("avatar_calc") {
            // 养成计算：按角色取单份数据，路径里多一层 avatar_compute。
            fileName = "avatar_compute/\(avatarId).json"
        } else if !avatarId.isEmpty {
            // 绝区零角色详情：直接是 `{avatarId}.json`。
            fileName = "\(avatarId).json"
        } else {
            fileName = FixturePathMapper.fileName(for: requestPath)
        }

        var candidates: [String] = []
        if !roleId.isEmpty {
            candidates.append("\(accountId)/\(roleId)/\(fileName)")
        }
        candidates.append("\(accountId)/\(fileName)")

        return FixtureResolution(
            accountId: accountId,
            roleId: roleId,
            avatarId: avatarId,
            fileName: fileName,
            candidates: candidates
        )
    }
}
