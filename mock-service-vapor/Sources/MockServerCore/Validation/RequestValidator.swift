import Foundation

/// HTTP 请求的基础校验。
///
/// 这些都是纯函数，便于在路由之前逐项拒绝异常请求，
/// 也避免把 Vapor 的类型泄漏到核心层。
public enum RequestValidator {
    /// 请求体上限，与 `ServerConfiguration.defaultMaxBodyBytes` 一致。
    public static let maximumBodyBytes = ServerConfiguration.defaultMaxBodyBytes

    /// 请求体是否在限制内（含等于）。
    public static func isBodyWithinLimit(_ byteCount: Int, limit: Int = maximumBodyBytes) -> Bool {
        byteCount >= 0 && byteCount <= limit
    }

    /// 相对路径是否安全。
    ///
    /// 拒绝：空路径、绝对路径、包含 `..` 的路径段、反斜杠、NUL 字符。
    /// fixture 读取还会再做一次标准化校验，这里是第一道闸门。
    public static func isSafeRelativePath(_ path: String) -> Bool {
        guard !path.isEmpty else { return false }
        guard !path.hasPrefix("/") else { return false }
        guard !path.contains("\\") else { return false }
        guard !path.contains("\0") else { return false }
        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        for component in components where component == ".." {
            return false
        }
        return true
    }

    /// 是否声明为 JSON。
    ///
    /// 允许 `application/json` 与带参数形式 `application/json; charset=utf-8`；
    /// 大小写不敏感。body 为空时不强制要求该头。
    public static func isJSONContentType(_ value: String?) -> Bool {
        guard let value, !value.isEmpty else { return false }
        let mediaType = value.split(separator: ";").first.map(String.init) ?? value
        return mediaType.trimmingCharacters(in: .whitespaces).lowercased() == "application/json"
    }

    /// 是否是 mock 服务支持的方法。
    public static func isSupportedMethod(_ method: String) -> Bool {
        ["GET", "POST", "OPTIONS"].contains(method.uppercased())
    }

    /// 统一方法名大小写。
    public static func normalizedMethod(_ method: String) -> String {
        method.uppercased()
    }

    /// 完整校验一个请求体大小，超限返回错误消息，供 HTTP 层转 400。
    public static func bodyLimitFailure(byteCount: Int, limit: Int = maximumBodyBytes) -> String? {
        guard !isBodyWithinLimit(byteCount, limit: limit) else { return nil }
        return "request body exceeds \(limit) bytes"
    }
}
