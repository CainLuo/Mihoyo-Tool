import Foundation

/// URL 查询参数。
///
/// 与 `URLComponents` 相比多做了两件事：
/// - 保留重复键的原始顺序（`id_list[]=1171&id_list[]=1141` 必须都能取到）；
/// - 允许直接解析裸 query 字符串（fixture RPC 里传的是不带域名的路径）。
public struct QueryParameters: Equatable, Sendable {
    /// 一个键值对。用结构体而不是元组，便于 `Equatable` 与断言。
    public struct Item: Equatable, Sendable {
        /// 已百分号解码的参数名。
        public let name: String
        /// 已百分号解码的参数值；`flag` 形式的参数值为空串。
        public let value: String

        public init(name: String, value: String) {
            self.name = name
            self.value = value
        }
    }

    /// 按 URL 中出现的顺序保存的全部参数。
    public private(set) var items: [Item]

    public init(items: [Item] = []) {
        self.items = items
    }

    /// 解析 `a=1&b=2` 或 `?a=1&b=2` 形式的 query。
    public init(rawQuery: String) {
        var text = rawQuery
        if let hashIndex = text.firstIndex(of: "#") {
            text = String(text[text.startIndex..<hashIndex])
        }
        if text.hasPrefix("?") {
            text = String(text.dropFirst())
        }

        var parsed: [Item] = []
        for pair in text.split(separator: "&", omittingEmptySubsequences: true) {
            let piece = String(pair)
            if let equalsIndex = piece.firstIndex(of: "=") {
                let name = String(piece[piece.startIndex..<equalsIndex])
                let value = String(piece[piece.index(after: equalsIndex)...])
                parsed.append(Item(name: QueryParameters.decode(name), value: QueryParameters.decode(value)))
            } else {
                parsed.append(Item(name: QueryParameters.decode(piece), value: ""))
            }
        }
        self.items = parsed
    }

    /// 取第一个同名参数；不存在返回 nil。
    public func first(_ name: String) -> String? {
        items.first { $0.name == name }?.value
    }

    /// 取同名参数的全部值，保持原始顺序。
    public func all(_ name: String) -> [String] {
        items.filter { $0.name == name }.map(\.value)
    }

    /// 下标语法等价于 `first(_:)`。
    public subscript(name: String) -> String? {
        first(name)
    }

    /// 是否包含某个参数名。
    public func contains(_ name: String) -> Bool {
        items.contains { $0.name == name }
    }

    /// 重组成 `a=1&b=2`，保持出现顺序。
    ///
    /// 用于签名输入与日志；不做百分号重编码，因为米游社的 DS 基于客户端原始 query。
    public func merged() -> String {
        items.map { "\($0.name)=\($0.value)" }.joined(separator: "&")
    }

    /// 从完整 URL / 相对路径里截取 query 部分（不含 `?`、不含 fragment）。
    public static func rawQuery(fromURL url: String) -> String {
        let normalized = FixturePathMapper.normalizePath(url)
        var text = normalized
        if let hashIndex = text.firstIndex(of: "#") {
            text = String(text[text.startIndex..<hashIndex])
        }
        guard let queryIndex = text.firstIndex(of: "?") else { return "" }
        return String(text[text.index(after: queryIndex)...])
    }

    /// 表单/query 的百分号解码：`+` 视为空格，非法转义保持原文。
    static func decode(_ text: String) -> String {
        let replaced = text.replacingOccurrences(of: "+", with: " ")
        return replaced.removingPercentEncoding ?? replaced
    }
}

/// 从 Cookie 里提取账号信息。
///
/// 规则与 Node 版一致：优先 `account_id`，其次 `stuid`，都没有则回退 `1`。
/// 数字只取连续数字前缀（`account_id=1.5` → `1`），与 JS 的 `parseInt` 行为对齐。
public enum CookieParser {
    /// 默认账号，缺失 Cookie 时使用。
    public static let fallbackAccountId = 1

    /// 提取账号 ID。
    public static func accountId(from cookie: String, fallback: Int = fallbackAccountId) -> Int {
        if let value = numericValue(named: "account_id", in: cookie) {
            return value
        }
        if let value = numericValue(named: "stuid", in: cookie) {
            return value
        }
        return fallback
    }

    /// 提取任意 Cookie 字段的字符串值，字段不存在返回 nil。
    public static func value(named name: String, in cookie: String) -> String? {
        let pattern = "\(NSRegularExpression.escapedPattern(for: name))=([^;]*)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(cookie.startIndex..<cookie.endIndex, in: cookie)
        guard let match = regex.firstMatch(in: cookie, options: [], range: range),
              match.numberOfRanges > 1,
              let valueRange = Range(match.range(at: 1), in: cookie) else {
            return nil
        }
        let value = cookie[valueRange].trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : value
    }

    /// 提取字段开头的连续数字，模拟 `parseInt`。
    static func numericValue(named name: String, in cookie: String) -> Int? {
        guard let raw = value(named: name, in: cookie) else { return nil }
        let digits = raw.prefix { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        return Int(digits)
    }
}
