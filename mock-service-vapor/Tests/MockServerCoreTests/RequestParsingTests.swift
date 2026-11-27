import XCTest
@testable import MockServerCore

/// `QueryParameters`、`CookieParser` 与 `MockRequest` 的解析行为。
///
/// 这些是路由与夹具逻辑的输入层：签名、角色 ID、账号都从这里取，
/// 解析错误会直接表现为「找不到 fixture」，所以逐条覆盖。
final class RequestParsingTests: XCTestCase {

    /// 场景：空 query 字符串。
    /// 期望：`items` 为空，所有查询方法返回 nil。
    func testEmptyQuery() {
        let query = QueryParameters(rawQuery: "")
        XCTAssertTrue(query.items.isEmpty)
        XCTAssertEqual(query.first("a"), nil)
    }

    /// 场景：标准 `a=1&b=2`。
    /// 期望：按出现顺序解析出两个参数。
    func testParsesPairs() {
        let query = QueryParameters(rawQuery: "a=1&b=2")
        XCTAssertEqual(query.items, [
            .init(name: "a", value: "1"),
            .init(name: "b", value: "2"),
        ])
    }

    /// 场景：query 以 `?` 开头。
    /// 期望：前导 `?` 被去掉，参数正常解析。
    func testStripsLeadingQuestionMark() {
        let query = QueryParameters(rawQuery: "?a=1")
        XCTAssertEqual(query.first("a"), "1")
        XCTAssertEqual(query.items.count, 1)
    }

    /// 场景：同名参数重复出现。
    /// 期望：全部保留且顺序不变（`id_list[]` 依赖这一点）。
    func testKeepsDuplicateKeys() {
        let query = QueryParameters(rawQuery: "id_list[]=1171&id_list[]=1151&id_list[]=1281")
        XCTAssertEqual(query.all("id_list[]"), ["1171", "1151", "1281"])
        XCTAssertEqual(query.items.count, 3)
    }

    /// 场景：存在同名参数。
    /// 期望：`first` 返回第一个值，与 Node 的 `URLSearchParams.get` 一致。
    func testFirstReturnsFirstValue() {
        let query = QueryParameters(rawQuery: "x=1&x=2")
        XCTAssertEqual(query.first("x"), "1")
    }

    /// 场景：下标语法取参数。
    /// 期望：等价于 `first(_:)`。
    func testSubscript() {
        let query = QueryParameters(rawQuery: "role_id=109050292")
        XCTAssertEqual(query["role_id"], "109050292")
        XCTAssertNil(query["missing"])
    }

    /// 场景：判断参数是否存在（值可以为空）。
    /// 期望：只看键，`flag` 形式也返回 true。
    func testContains() {
        let query = QueryParameters(rawQuery: "flag&role_id=1")
        XCTAssertTrue(query.contains("flag"))
        XCTAssertFalse(query.contains("nope"))
    }

    /// 场景：参数值带百分号编码（含中文）。
    /// 期望：解码成原始字符。
    func testPercentDecoding() {
        let query = QueryParameters(rawQuery: "name=%E6%9F%8F%E5%A6%AE%E6%80%9D&server=cn_gf01")
        XCTAssertEqual(query.first("name"), "柏妮思")
    }

    /// 场景：参数值里的 `+`。
    /// 期望：按表单习惯解码成空格。
    func testPlusBecomesSpace() {
        let query = QueryParameters(rawQuery: "q=a+b")
        XCTAssertEqual(query.first("q"), "a b")
    }

    /// 场景：只有键没有 `=`。
    /// 期望：值为空串，而不是丢弃该参数。
    func testFlagWithoutValue() {
        let query = QueryParameters(rawQuery: "flag")
        XCTAssertEqual(query.items, [.init(name: "flag", value: "")])
    }

    /// 场景：query 后带 fragment。
    /// 期望：fragment 被截掉，不进参数。
    func testStripsFragment() {
        let query = QueryParameters(rawQuery: "a=1#frag")
        XCTAssertEqual(query.first("a"), "1")
        XCTAssertFalse(query.contains("frag"))
    }

    /// 场景：重新拼回 query 字符串。
    /// 期望：保持原始顺序，不做百分号重编码。
    func testMerged() {
        let query = QueryParameters(rawQuery: "role_id=1&server=cn_gf01")
        XCTAssertEqual(query.merged(), "role_id=1&server=cn_gf01")
    }

    /// 场景：从完整 URL 截取 query。
    /// 期望：只返回 `?` 之后的部分。
    func testRawQueryFromFullURL() {
        XCTAssertEqual(
            QueryParameters.rawQuery(fromURL: "https://host/a/b?role_id=1&server=cn_gf01"),
            "role_id=1&server=cn_gf01"
        )
    }

    /// 场景：URL 没有 query。
    /// 期望：返回空串。
    func testRawQueryMissing() {
        XCTAssertEqual(QueryParameters.rawQuery(fromURL: "/a/b"), "")
    }

    /// 场景：query 后面还有 fragment。
    /// 期望：fragment 被截掉。
    func testRawQueryStripsFragment() {
        XCTAssertEqual(
            QueryParameters.rawQuery(fromURL: "/a/b?x=1#section"),
            "x=1"
        )
    }

    /// 场景：相对路径形式的 URL。
    /// 期望：不需要域名也能取到 query。
    func testRawQueryRelativePath() {
        XCTAssertEqual(QueryParameters.rawQuery(fromURL: "/x?role_id=1"), "role_id=1")
    }

    /// 场景：`MockRequest.path`。
    /// 期望：去掉域名与 query，只留纯路径。
    func testMockRequestPath() {
        let request = MockRequest(
            method: "GET",
            url: "https://api.example.com/game_record/app/x?role_id=1"
        )
        XCTAssertEqual(request.path, "/game_record/app/x")
    }

    /// 场景：请求体是 UTF-8 文本。
    /// 期望：`bodyText` 原样返回。
    func testMockRequestBodyText() {
        let request = MockRequest(method: "POST", url: "/x", body: Data("{\"a\":1}".utf8))
        XCTAssertEqual(request.bodyText, "{\"a\":1}")
    }

    /// 场景：请求头大小写不同。
    /// 期望：`header(_:)` 大小写不敏感，都能取到值。
    func testHeaderCaseInsensitive() {
        let request = MockRequest(method: "GET", url: "/x", headers: ["Cookie": "a=1"])
        XCTAssertEqual(request.header("cookie"), "a=1")
        XCTAssertEqual(request.header("COOKIE"), "a=1")
    }

    /// 场景：`MockRequest.cookie`。
    /// 期望：返回 Cookie 请求头；缺失时为空串。
    func testMockRequestCookie() {
        XCTAssertEqual(
            MockRequest(method: "GET", url: "/x", headers: ["cookie": "account_id=1"]).cookie,
            "account_id=1"
        )
        XCTAssertEqual(MockRequest(method: "GET", url: "/x").cookie, "")
    }

    /// 场景：`MockRequest.query`。
    /// 期望：从 URL 里解析出参数。
    func testMockRequestQuery() {
        let request = MockRequest(method: "GET", url: "/x?role_id=109050292")
        XCTAssertEqual(request.query.first("role_id"), "109050292")
    }

    /// 场景：`MockRequest.dynamicSecret`。
    /// 期望：读取 `DS` 请求头（大小写不敏感）。
    func testMockRequestDynamicSecret() {
        let request = MockRequest(
            method: "GET",
            url: "/x",
            headers: ["ds": "1700000000,123456,ea56f3c12b77bcd23947635b9b4634f3"]
        )
        XCTAssertEqual(request.dynamicSecret, "1700000000,123456,ea56f3c12b77bcd23947635b9b4634f3")
    }

    /// 场景：Cookie 里带 `account_id`。
    /// 期望：解析成整数账号 ID。
    func testCookieParserAccountId() {
        XCTAssertEqual(CookieParser.accountId(from: "account_id=182692936; x=1"), 182692936)
    }

    /// 场景：Cookie 里只有 `stuid`。
    /// 期望：回退到 `stuid`。
    func testCookieParserStuid() {
        XCTAssertEqual(CookieParser.accountId(from: "stuid=348366494"), 348366494)
    }

    /// 场景：Cookie 为空或没有账号字段。
    /// 期望：回退默认账号 `1`。
    func testCookieParserFallback() {
        XCTAssertEqual(CookieParser.accountId(from: ""), 1)
        XCTAssertEqual(CookieParser.accountId(from: "ltoken=abc"), 1)
    }

    /// 场景：读取任意 Cookie 字段。
    /// 期望：字段不存在返回 nil，值为空白也返回 nil。
    func testCookieValueNamed() {
        XCTAssertEqual(CookieParser.value(named: "ltoken", in: "ltoken=abc; x=1"), "abc")
        XCTAssertNil(CookieParser.value(named: "missing", in: "ltoken=abc"))
        XCTAssertNil(CookieParser.value(named: "ltoken", in: "ltoken=  "))
    }
}
