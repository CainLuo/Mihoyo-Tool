import Foundation

/// 顶层路由分类。
///
/// `proxy` 表示「其余 GET/POST 都按真实 API 路径直接找 fixture」，
/// 这样 App 不需要为每个接口单独注册路由。
public enum MockRoute: Equatable, Sendable {
    /// `GET /`：服务信息。
    case serverInfo
    /// `GET /__health`：健康检查。
    case health
    /// `POST /__mock/rpc`：调试 RPC。
    case rpc
    /// `OPTIONS *`：CORS 预检，返回 204。
    case preflight
    /// 其余 GET/POST：直连 fixture 代理。
    case proxy
    /// 其他方法：404。
    case unsupported
}

/// 只做路径分类，不读文件、不解析 body，因此非常轻量。
public struct RequestRouter: Sendable {
    public init() {}

    /// 根据方法与 URL 返回路由分类。
    public func route(method: String, url: String) -> MockRoute {
        let normalizedMethod = RequestValidator.normalizedMethod(method)
        let path = FixturePathMapper.cleanPath(url)

        if normalizedMethod == "OPTIONS" {
            return .preflight
        }
        if normalizedMethod == "GET" {
            if path == "/" || path.isEmpty { return .serverInfo }
            if path == "/__health" { return .health }
            return .proxy
        }
        if normalizedMethod == "POST" {
            if path == "/__mock/rpc" { return .rpc }
            return .proxy
        }
        return .unsupported
    }
}
