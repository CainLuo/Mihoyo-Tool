import Foundation

/// 米游社 API 的统一响应信封：`{ "retcode": 0, "message": "OK", "data": {...} }`。
///
/// 字段含义：
/// - `retcode`：业务码，0 表示成功；负数与真实 API 的错误码对应（例如 -3001 验证码错误）。
/// - `message`：人类可读结果。注意 Node 版有 `OK` 与 `success` 两种历史约定，见 `empty(fallbackEmptyList:)`。
/// - `data`：业务数据；空响应时为 `{}` 或 `{ "list": [] }`。
public struct MockEnvelope: Equatable, Sendable {
    public var retcode: Int
    public var message: String
    public var data: JSONValue

    public init(retcode: Int, message: String, data: JSONValue = .object([:])) {
        self.retcode = retcode
        self.message = message
        self.data = data
    }
}

public extension MockEnvelope {
    /// 成功响应，`message` 固定为 `OK`（与原 Node 版 `okResponse` 一致）。
    static func ok(_ data: JSONValue = .object([:])) -> MockEnvelope {
        MockEnvelope(retcode: 0, message: "OK", data: data)
    }

    /// 失败响应，`data` 保持空对象，便于 App 侧统一处理。
    static func error(retcode: Int, message: String) -> MockEnvelope {
        MockEnvelope(retcode: retcode, message: message, data: .object([:]))
    }

    /// fixture 缺失时的兜底响应。
    ///
    /// - Parameter fallbackEmptyList: 为 `false` 时是通用空响应（`message=success`, `data={}`）；
    ///   为 `true` 时用于同步列表类接口（`message=OK`, `data={"list":[]}`），
    ///   否则 App 侧解析列表会拿到 nil。
    static func empty(fallbackEmptyList: Bool = false) -> MockEnvelope {
        MockEnvelope(
            retcode: 0,
            message: fallbackEmptyList ? "OK" : "success",
            data: fallbackEmptyList ? .object(["list": .array([])]) : .object([:])
        )
    }

    /// 转成可直接编码的 JSON 对象。
    var jsonValue: JSONValue {
        .object([
            "retcode": .int(retcode),
            "message": .string(message),
            "data": data,
        ])
    }

    /// 编码后的响应字节。
    func encoded() throws -> Data {
        try jsonValue.encoded()
    }
}

/// 一个已经准备好写回 HTTP 的响应。
///
/// 单独抽出来是为了让路由/夹具逻辑可单测，不必启动 Vapor。
public struct MockHTTPResponse: Sendable, Equatable {
    /// HTTP 状态码。
    public var status: Int
    /// 响应头；`Content-Type` 固定 JSON，CORS 允许本机调试页面跨域。
    public var headers: [String: String]
    /// 响应体原始字节。fixture 命中时是文件原始字节，不做重新编码。
    public var body: Data

    public init(status: Int, headers: [String: String], body: Data) {
        self.status = status
        self.headers = headers
        self.body = body
    }
}

public extension MockHTTPResponse {
    /// 统一响应头，与 Node 版 `sendJson` 对齐。
    static var defaultJSONHeaders: [String: String] {
        [
            "Content-Type": "application/json; charset=utf-8",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "content-type",
            "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
            "Cache-Control": "no-store",
        ]
    }

    /// 由信封构造 JSON 响应。
    static func envelope(_ envelope: MockEnvelope, status: Int = 200) -> MockHTTPResponse {
        let data = (try? envelope.encoded()) ?? Data("{\"retcode\":0,\"message\":\"success\",\"data\":{}}".utf8)
        return MockHTTPResponse(status: status, headers: defaultJSONHeaders, body: data)
    }

    /// 把一个 JSON 值作为响应体。
    static func json(_ value: JSONValue, status: Int = 200) -> MockHTTPResponse {
        let data = (try? value.encoded()) ?? Data("{}".utf8)
        return MockHTTPResponse(status: status, headers: defaultJSONHeaders, body: data)
    }

    /// 原始字节响应（fixture 命中）。
    static func raw(_ data: Data, status: Int = 200) -> MockHTTPResponse {
        MockHTTPResponse(status: status, headers: defaultJSONHeaders, body: data)
    }

    /// 错误响应，供 404 / 400 使用。
    static func failure(status: Int, message: String) -> MockHTTPResponse {
        MockHTTPResponse.json(.object(["error": .string(message)]), status: status)
    }

    /// 解析响应体，主要给测试与日志使用。
    var decodedJSON: JSONValue? {
        try? JSONValue(parsing: body)
    }
}
