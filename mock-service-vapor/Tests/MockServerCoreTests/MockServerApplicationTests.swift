import XCTest
@testable import MockServerCore

/// `MockServerApplication.respond` 的 HTTP 分发行为。
///
/// 这一层不启动 Vapor，直接喂 `MockRequest`，覆盖
/// serverInfo / health / preflight / rpc / proxy / unsupported 六条分支
/// 以及请求体上限。
final class MockServerApplicationTests: XCTestCase {

    /// 测试用配置：显式指向仓库 fixtures，延迟置 0 让断言更快。
    private var configuration: ServerConfiguration {
        ServerConfiguration(
            delayMilliseconds: 0,
            fixturesDirectory: TestFixtures.fixturesDirectory
        )
    }

    /// 统一入口，避免每个用例重复写三个参数。
    private func respond(_ request: MockRequest, configuration: ServerConfiguration? = nil) -> MockHTTPResponse {
        MockServerApplication.respond(
            to: request,
            configuration: configuration ?? self.configuration,
            store: TestFixtures.store
        )
    }

    /// 场景：`GET /`。
    /// 期望：返回服务名 `mihoyo-tool-mock-service`。
    func testServerInfoName() {
        let response = respond(MockRequest(method: "GET", url: "/"))
        XCTAssertEqual(response.status, 200)
        XCTAssertEqual(response.decodedJSON?["name"]?.stringValue, "mihoyo-tool-mock-service")
    }

    /// 场景：`GET /` 的其余字段。
    /// 期望：给出 RPC / 健康检查入口，以及当前生效的延迟。
    func testServerInfoFields() {
        let json = respond(MockRequest(method: "GET", url: "/")).decodedJSON
        XCTAssertEqual(json?["rpc"]?.stringValue, "POST /__mock/rpc")
        XCTAssertEqual(json?["health"]?.stringValue, "GET /__health")
        XCTAssertEqual(json?["delayMs"]?.intValue, 0)
    }

    /// 场景：`GET /__health`。
    /// 期望：`ok=true`，`fixtures` 等于仓库里真实的 224 份 JSON。
    func testHealthPayload() {
        let json = respond(MockRequest(method: "GET", url: "/__health")).decodedJSON
        XCTAssertEqual(json?["ok"]?.boolValue, true)
        XCTAssertEqual(json?["fixtures"]?.intValue, 224)
    }

    /// 场景：健康检查的目录字段。
    /// 期望：回显实际 fixtures 根目录，方便确认没有指错地方。
    func testHealthFixturesDir() {
        let json = respond(MockRequest(method: "GET", url: "/__health")).decodedJSON
        XCTAssertEqual(
            json?["fixturesDir"]?.stringValue,
            TestFixtures.fixturesDirectory.standardizedFileURL.path
        )
    }

    /// 场景：`OPTIONS` 预检。
    /// 期望：204 + 空 body，CORS 头仍由 `defaultJSONHeaders` 提供。
    func testPreflight() {
        let response = respond(MockRequest(method: "OPTIONS", url: "/game_record/app/genshin/api/dailyNote"))
        XCTAssertEqual(response.status, 204)
        XCTAssertTrue(response.body.isEmpty)
        XCTAssertEqual(response.headers["Access-Control-Allow-Origin"], "*")
    }

    /// 场景：直连命中原神每日便笺。
    /// 期望：200，body 与磁盘上的 fixture 字节完全一致（不重新编码）。
    func testProxyHitReturnsRawFixture() throws {
        let response = respond(
            MockRequest(
                method: "GET",
                url: "/game_record/app/genshin/api/dailyNote?role_id=\(TestFixtures.genshinRoleId)&server=cn_gf01",
                headers: ["Cookie": TestFixtures.cookie182]
            )
        )
        let expected = try XCTUnwrap(
            TestFixtures.store.load(
                relativePath: "182692936/109050292/game_record_app_genshin_api_dailyNote.json"
            )
        )
        XCTAssertEqual(response.status, 200)
        XCTAssertEqual(response.body, expected.data)
    }

    /// 场景：直连但没有对应 fixture。
    /// 期望：返回 `{retcode:0,message:"success",data:{}}`，而不是 404。
    func testProxyMissReturnsEmptyEnvelope() {
        let response = respond(
            MockRequest(
                method: "GET",
                url: "/game_record/app/genshin/api/dailyNote?role_id=\(TestFixtures.genshinRoleId)",
                headers: ["Cookie": TestFixtures.cookie348]
            )
        )
        XCTAssertEqual(response.status, 200)
        XCTAssertEqual(response.decodedJSON?["retcode"]?.intValue, 0)
        XCTAssertEqual(response.decodedJSON?["message"]?.stringValue, "success")
        XCTAssertEqual(response.decodedJSON?["data"], .object([:]))
    }

    /// 场景：RPC `kind=fixture`。
    /// 期望：返回原始 fixture 字节，账号从 cookie 字段提取。
    func testRPCFixtureKind() throws {
        let body = """
        {"kind":"fixture","path":"/binding/api/getUserGameRolesByCookie","cookie":"\(TestFixtures.cookie182)"}
        """
        let response = respond(MockRequest(method: "POST", url: "/__mock/rpc", body: Data(body.utf8)))
        let expected = try XCTUnwrap(
            TestFixtures.store.load(relativePath: "182692936/binding_api_getUserGameRolesByCookie.json")
        )
        XCTAssertEqual(response.status, 200)
        XCTAssertEqual(response.body, expected.data)
    }

    /// 场景：RPC `kind=account`。
    /// 期望：走账号 Mock，手机号 + 验证码登录成功。
    func testRPCAccountKind() {
        let body = """
        {"kind":"account","method":"loginByMobileCaptcha","mobile":"13800138001","captcha":"111111"}
        """
        let response = respond(MockRequest(method: "POST", url: "/__mock/rpc", body: Data(body.utf8)))
        XCTAssertEqual(response.status, 200)
        XCTAssertEqual(response.decodedJSON?["retcode"]?.intValue, 0)
        XCTAssertEqual(
            response.decodedJSON?["data"]?["token"]?["token"]?.stringValue,
            "mock_stoken_348366494"
        )
    }

    /// 场景：RPC `kind=sign`。
    /// 期望：没有签到 fixture 时仍返回成功空信封。
    func testRPCSignKind() {
        let body = """
        {"kind":"sign","method":"signBBS","cookie":"\(TestFixtures.cookie182)"}
        """
        let response = respond(MockRequest(method: "POST", url: "/__mock/rpc", body: Data(body.utf8)))
        XCTAssertEqual(response.status, 200)
        XCTAssertEqual(response.decodedJSON?["retcode"]?.intValue, 0)
        XCTAssertEqual(response.decodedJSON?["message"]?.stringValue, "success")
    }

    /// 场景：RPC 请求体为空或不是 JSON 对象。
    /// 期望：400，错误消息说明必须是 JSON 对象。
    func testRPCInvalidBody() {
        let empty = respond(MockRequest(method: "POST", url: "/__mock/rpc"))
        XCTAssertEqual(empty.status, 400)
        XCTAssertEqual(
            empty.decodedJSON?["error"]?.stringValue,
            "request body must be a JSON object"
        )

        let array = respond(
            MockRequest(method: "POST", url: "/__mock/rpc", body: Data("[1,2]".utf8))
        )
        XCTAssertEqual(array.status, 400)
    }

    /// 场景：RPC 未知 kind 与 fixture 缺 path。
    /// 期望：都返回 400，并带上可定位的错误消息。
    func testRPCUnknownKindAndMissingPath() {
        let unknown = respond(
            MockRequest(method: "POST", url: "/__mock/rpc", body: Data("{\"kind\":\"nope\"}".utf8))
        )
        XCTAssertEqual(unknown.status, 400)
        XCTAssertEqual(unknown.decodedJSON?["error"]?.stringValue, "unknown rpc kind: nope")

        let missing = respond(
            MockRequest(method: "POST", url: "/__mock/rpc", body: Data("{\"kind\":\"fixture\"}".utf8))
        )
        XCTAssertEqual(missing.status, 400)
        XCTAssertEqual(missing.decodedJSON?["error"]?.stringValue, "missing field: path")
    }

    /// 场景：不支持的方法。
    /// 期望：404，错误消息包含方法与路径。
    func testUnsupportedMethod() {
        let response = respond(MockRequest(method: "DELETE", url: "/game_record/x"))
        XCTAssertEqual(response.status, 404)
        XCTAssertTrue(
            (response.decodedJSON?["error"]?.stringValue ?? "").contains("DELETE /game_record/x")
        )
    }

    /// 场景：请求体超过配置上限。
    /// 期望：直接 400，且在路由之前拦下（不读 fixture）。
    func testBodyLimit() {
        let limited = ServerConfiguration(
            delayMilliseconds: 0,
            fixturesDirectory: TestFixtures.fixturesDirectory,
            maxBodyBytes: 4
        )
        let response = respond(
            MockRequest(method: "POST", url: "/__mock/rpc", body: Data("12345".utf8)),
            configuration: limited
        )
        XCTAssertEqual(response.status, 400)
        XCTAssertEqual(
            response.decodedJSON?["error"]?.stringValue,
            "request body exceeds 4 bytes"
        )
    }
}
