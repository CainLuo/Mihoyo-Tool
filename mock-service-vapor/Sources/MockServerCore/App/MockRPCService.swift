import Foundation

/// RPC 调用的产物。
///
/// fixture 命中时保留原始字节（`rawJSON`），合成响应走 `envelope`，
/// 与 Node 版「命中返回文件内容、未命中返回信封」的行为一致。
public enum MockRPCResult: Sendable, Equatable {
    case envelope(MockEnvelope)
    case rawJSON(Data)

    /// 实际写回的响应体。
    public var body: Data {
        switch self {
        case let .envelope(envelope):
            return (try? envelope.encoded()) ?? Data("{}".utf8)
        case let .rawJSON(data):
            return data
        }
    }
}

/// RPC 错误，HTTP 层统一转 400。
public enum MockRPCError: Error, Equatable, Sendable {
    /// 请求体不是 JSON 对象。
    case invalidBody(String)
    /// `kind` 不在 fixture / account / sign 内。
    case unknownKind(String)
    /// 方法名未知（账号或签到）。
    case unknownMethod(String)
    /// 缺少必填字段。
    case missingField(String)

    /// 给客户端看的错误消息。
    public var message: String {
        switch self {
        case let .invalidBody(detail): return detail
        case let .unknownKind(kind): return "unknown rpc kind: \(kind)"
        case let .unknownMethod(method): return method
        case let .missingField(field): return "missing field: \(field)"
        }
    }
}

/// 调试用 RPC：`POST /__mock/rpc`。
///
/// 请求体字段：
/// - `kind`：`fixture` / `account` / `sign`；
/// - fixture：`path`、`cookie`、`roleId`、`avatarId`、`body`、`fallbackEmptyList`；
/// - account：`method`、`mobile`、`captcha`、`stoken`；
/// - sign：`method`、`cookie`、`gameBiz`。
public enum MockRPCService {
    /// 处理一个 RPC 请求体。
    public static func handle(body: Data, store: FixtureStore) -> Result<MockRPCResult, MockRPCError> {
        guard !body.isEmpty else {
            return .failure(.invalidBody("request body must be a JSON object"))
        }
        guard let parsed = try? JSONValue(parsing: body), case .object = parsed else {
            return .failure(.invalidBody("request body must be a JSON object"))
        }

        let kind = parsed["kind"]?.stringValue ?? ""

        switch kind {
        case "fixture":
            guard let path = parsed["path"]?.stringValue else {
                return .failure(.missingField("path"))
            }
            let query = FixtureQuery(
                path: path,
                cookie: parsed["cookie"]?.stringValue ?? "",
                roleId: parsed["roleId"]?.stringValue,
                avatarId: parsed["avatarId"]?.stringValue,
                body: parsed["body"]?.stringValue,
                fallbackEmptyList: parsed["fallbackEmptyList"]?.boolValue ?? false
            )
            let lookup = store.lookup(query)
            if let fixture = lookup.fixture {
                return .success(.rawJSON(fixture.data))
            }
            return .success(.envelope(.empty(fallbackEmptyList: query.fallbackEmptyList)))

        case "account":
            let request = AccountRequest(
                method: parsed["method"]?.stringValue ?? "",
                mobile: parsed["mobile"]?.stringValue ?? "",
                captcha: parsed["captcha"]?.stringValue ?? "",
                stoken: parsed["stoken"]?.stringValue ?? ""
            )
            return .success(.envelope(AccountMock.handle(request)))

        case "sign":
            let request = SignRequest(
                method: parsed["method"]?.stringValue ?? "",
                cookie: parsed["cookie"]?.stringValue ?? "",
                gameBiz: parsed["gameBiz"]?.stringValue ?? ""
            )
            return SignMock.result(for: request, store: store)

        default:
            return .failure(.unknownKind(kind))
        }
    }
}
