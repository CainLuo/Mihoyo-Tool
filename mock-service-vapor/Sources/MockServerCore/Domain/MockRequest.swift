import Foundation

/// 与 HTTP 框架无关的请求快照。
///
/// Vapor 的 `Request` 只在 `App/MockServerApplication.swift` 里转换一次，
/// 其余路由、夹具、账号逻辑都只依赖这个结构，因此可以脱离网络单测。
public struct MockRequest: Sendable, Equatable {
    /// HTTP 方法，保持调用方原始大小写；路由判断时再统一大写。
    public var method: String
    /// 路径 + query。允许带完整 URL（真实 API 的绝对地址），解析时只取 path + query。
    public var url: String
    /// 请求头。键大小写不敏感查找，见 `header(_:)`。
    public var headers: [String: String]
    /// 请求体字节。
    public var body: Data
    /// 客户端地址，仅用于日志，不参与路由。
    public var remoteAddress: String?

    public init(
        method: String,
        url: String,
        headers: [String: String] = [:],
        body: Data = Data(),
        remoteAddress: String? = nil
    ) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.remoteAddress = remoteAddress
    }

    /// 去掉协议、域名与 query 的纯路径。
    public var path: String {
        FixturePathMapper.cleanPath(url)
    }

    /// 请求体按 UTF-8 解码；二进制体返回空串。
    public var bodyText: String {
        String(data: body, encoding: .utf8) ?? ""
    }

    /// 大小写不敏感地取请求头。
    public func header(_ name: String) -> String? {
        let target = name.lowercased()
        for (key, value) in headers where key.lowercased() == target {
            return value
        }
        return nil
    }

    /// `Cookie` 请求头内容；App 侧的账号提取都依赖它。
    public var cookie: String {
        header("Cookie") ?? ""
    }

    /// query 参数（保留重复键，例如 `id_list[]`）。
    public var query: QueryParameters {
        QueryParameters(rawQuery: QueryParameters.rawQuery(fromURL: url))
    }

    /// `DS` 请求头内容；mock 服务不校验签名，只记录并供调试接口回显。
    public var dynamicSecret: String? {
        header("DS")
    }
}
