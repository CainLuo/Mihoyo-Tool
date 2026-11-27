import XCTest
@testable import MockServerCore

/// `MockEnvelope` 与 `MockHTTPResponse` 的响应构造行为。
///
/// 这些字节最终会直接写回 App，字段名、message 文案、响应头
/// 都必须与 Node 版一致，否则 App 的解析层会失效。
final class MockResponseTests: XCTestCase {

    /// 场景：无参数构造成功信封。
    /// 期望：`retcode=0`、`message=OK`、`data={}`。
    func testOkDefaults() {
        let envelope = MockEnvelope.ok()
        XCTAssertEqual(envelope.retcode, 0)
        XCTAssertEqual(envelope.message, "OK")
        XCTAssertEqual(envelope.data, .object([:]))
    }

    /// 场景：带数据的成功信封。
    /// 期望：`data` 原样保留。
    func testOkWithData() {
        let envelope = MockEnvelope.ok(.object(["current_resin": .int(152)]))
        XCTAssertEqual(envelope.data["current_resin"]?.intValue, 152)
    }

    /// 场景：错误信封。
    /// 期望：业务码与消息保留，`data` 固定为空对象。
    func testErrorEnvelope() {
        let envelope = MockEnvelope.error(retcode: -3001, message: "验证码错误")
        XCTAssertEqual(envelope.retcode, -3001)
        XCTAssertEqual(envelope.message, "验证码错误")
        XCTAssertEqual(envelope.data, .object([:]))
    }

    /// 场景：通用空响应（fixture 缺失）。
    /// 期望：`message=success`、`data={}`，与 Node 版一致。
    func testEmptyDefault() {
        let envelope = MockEnvelope.empty()
        XCTAssertEqual(envelope.retcode, 0)
        XCTAssertEqual(envelope.message, "success")
        XCTAssertEqual(envelope.data, .object([:]))
    }

    /// 场景：列表类接口的空响应。
    /// 期望：`message=OK`、`data={"list": []}`，否则 App 解析列表会拿到 nil。
    func testEmptyFallbackList() {
        let envelope = MockEnvelope.empty(fallbackEmptyList: true)
        XCTAssertEqual(envelope.message, "OK")
        XCTAssertEqual(envelope.data["list"]?.arrayValue, [])
    }

    /// 场景：信封转 JSON 值。
    /// 期望：只包含 `retcode` / `message` / `data` 三个键。
    func testJsonValueShape() {
        let json = MockEnvelope.ok(.object(["a": .int(1)])).jsonValue
        XCTAssertEqual(json.objectValue?.keys.sorted(), ["data", "message", "retcode"])
        XCTAssertEqual(json["retcode"]?.intValue, 0)
    }

    /// 场景：编码后再解析。
    /// 期望：内容等价，整数字段仍是整数（不会变成 0.0）。
    func testEncodedRoundTrip() throws {
        let envelope = MockEnvelope.ok(.object(["count": .int(3)]))
        let decoded = try JSONValue(parsing: envelope.encoded())
        XCTAssertEqual(decoded["retcode"]?.intValue, 0)
        XCTAssertEqual(decoded["data"]?["count"]?.intValue, 3)
    }

    /// 场景：同一信封编码两次。
    /// 期望：`sortedKeys` 让字节完全稳定，便于日志 diff 与测试断言。
    func testEncodedSortedKeysStable() throws {
        let envelope = MockEnvelope.ok(.object(["b": .int(2), "a": .int(1)]))
        XCTAssertEqual(try envelope.encoded(), try envelope.encoded())
    }

    /// 场景：默认响应头。
    /// 期望：`Content-Type` 是 UTF-8 JSON，与 Node `sendJson` 一致。
    func testDefaultHeadersContentType() {
        XCTAssertEqual(
            MockHTTPResponse.defaultJSONHeaders["Content-Type"],
            "application/json; charset=utf-8"
        )
    }

    /// 场景：默认响应头里的 CORS 与缓存策略。
    /// 期望：允许任意来源、允许 content-type、禁止缓存（避免 App 拿到旧数据）。
    func testDefaultHeadersCORS() {
        let headers = MockHTTPResponse.defaultJSONHeaders
        XCTAssertEqual(headers["Access-Control-Allow-Origin"], "*")
        XCTAssertEqual(headers["Access-Control-Allow-Headers"], "content-type")
        XCTAssertEqual(headers["Access-Control-Allow-Methods"], "GET,POST,OPTIONS")
        XCTAssertEqual(headers["Cache-Control"], "no-store")
    }

    /// 场景：由信封构造 HTTP 响应。
    /// 期望：状态 200，响应头为默认 JSON 头，body 可解析。
    func testEnvelopeResponse() {
        let response = MockHTTPResponse.envelope(.ok())
        XCTAssertEqual(response.status, 200)
        XCTAssertEqual(response.headers, MockHTTPResponse.defaultJSONHeaders)
        XCTAssertEqual(response.decodedJSON?["message"]?.stringValue, "OK")
    }

    /// 场景：把任意 JSON 值作为响应体。
    /// 期望：内容与 `JSONValue` 等价。
    func testJSONResponse() {
        let response = MockHTTPResponse.json(.object(["ok": .bool(true)]))
        XCTAssertEqual(response.status, 200)
        XCTAssertEqual(response.decodedJSON?["ok"]?.boolValue, true)
    }

    /// 场景：fixture 原始字节响应。
    /// 期望：字节完全不被重写（字段顺序、缩进都保留）。
    func testRawPreservesBytes() {
        let data = Data("{\n  \"z\": 1,\n  \"a\": 2\n}".utf8)
        let response = MockHTTPResponse.raw(data)
        XCTAssertEqual(response.body, data)
        XCTAssertEqual(response.status, 200)
    }

    /// 场景：错误响应。
    /// 期望：状态码保留，body 是 `{"error": "..."}`。
    func testFailureResponse() {
        let response = MockHTTPResponse.failure(status: 404, message: "not found")
        XCTAssertEqual(response.status, 404)
        XCTAssertEqual(response.decodedJSON?["error"]?.stringValue, "not found")
    }

    /// 场景：响应体不是合法 JSON。
    /// 期望：`decodedJSON` 返回 nil 而不是崩溃。
    func testDecodedJSONNilOnInvalidBody() {
        let response = MockHTTPResponse(status: 200, headers: [:], body: Data("not json".utf8))
        XCTAssertNil(response.decodedJSON)
    }

    /// 场景：状态码与 headers 的默认组合。
    /// 期望：`raw` 也带默认 JSON 头，`envelope` 可指定非 200 状态。
    func testHeadersApplyToAllFactories() {
        XCTAssertEqual(MockHTTPResponse.raw(Data()).headers, MockHTTPResponse.defaultJSONHeaders)
        XCTAssertEqual(MockHTTPResponse.envelope(.ok(), status: 201).status, 201)
        XCTAssertEqual(MockHTTPResponse.json(.null, status: 202).status, 202)
    }
}
