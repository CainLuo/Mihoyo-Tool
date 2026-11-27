import XCTest
@testable import MockServerCore

/// `AccountMock` 的账号接口行为。
///
/// 与 Node 版逐字段对齐：App 侧不需要知道后端是 Node 还是 Swift，
/// 因此这里既断言成功分支的字段，也断言三个业务错误码。
final class AccountMockTests: XCTestCase {

    /// 场景：手机号 → 账号白名单。
    /// 期望：只有两个号码，多一个或少一个都会破坏登录流程。
    func testPhoneMappingCount() {
        XCTAssertEqual(AccountMock.phoneToAccountId.count, 2)
        XCTAssertEqual(AccountMock.phoneToAccountId["13800138000"], "182692936")
        XCTAssertEqual(AccountMock.phoneToAccountId["13800138001"], "348366494")
    }

    /// 场景：固定验证码。
    /// 期望：唯一有效值 `111111`。
    func testCaptchaCode() {
        XCTAssertEqual(AccountMock.captchaCode, "111111")
    }

    /// 场景：stoken 前缀。
    /// 期望：`mock_stoken_`，换取 Token 时据此解析账号。
    func testStokenPrefix() {
        XCTAssertEqual(AccountMock.stokenPrefix, "mock_stoken_")
    }

    /// 场景：两个业务错误码。
    /// 期望：与真实 API 对齐，App 侧靠它们区分「未注册」和「验证码错」。
    func testErrorRetcodes() {
        XCTAssertEqual(AccountMock.unregisteredPhoneRetcode, -3101)
        XCTAssertEqual(AccountMock.wrongCaptchaRetcode, -3001)
    }

    /// 场景：二维码固定账号。
    /// 期望：`182692936`，与 Node 版一致。
    func testQRCodeAccountId() {
        XCTAssertEqual(AccountMock.qrCodeAccountId, "182692936")
    }

    /// 场景：已识别的方法集合。
    /// 期望：共 9 个，覆盖 App 登录流程用到的全部方法。
    func testAccountMethodCount() {
        XCTAssertEqual(AccountMethod.allCases.count, 9)
    }

    /// 场景：`AccountRequest.knownMethod` 遇到未知方法。
    /// 期望：返回 nil，`handle` 据此走 `-1`。
    func testKnownMethodNilForUnknown() {
        XCTAssertNil(AccountRequest(method: "nope").knownMethod)
        XCTAssertEqual(AccountRequest(method: "fetchQRCode").knownMethod, .fetchQRCode)
    }

    /// 场景：stoken 里的账号部分是任意数字。
    /// 期望：原样透传，不做白名单校验（mock 只关心格式）。
    func testAccountIdFromStokenPassesThrough() {
        XCTAssertEqual(AccountMock.accountIdFromStoken("mock_stoken_999999"), "999999")
    }

    /// 场景：已注册手机号请求验证码。
    /// 期望：`sent_new` 为 true，App 据此展示倒计时。
    func testCreateCaptchaSentNew() {
        let envelope = AccountMock.handle(AccountRequest(method: "createLoginCaptcha", mobile: "13800138000"))
        XCTAssertEqual(envelope.retcode, 0)
        XCTAssertEqual(envelope.data["sent_new"]?.boolValue, true)
    }

    /// 场景：验证码倒计时长度。
    /// 期望：60 秒，与 Node 版硬编码值一致。
    func testCreateCaptchaCountdown() {
        let envelope = AccountMock.handle(AccountRequest(method: "createLoginCaptcha", mobile: "13800138000"))
        XCTAssertEqual(envelope.data["countdown"]?.intValue, 60)
    }

    /// 场景：验证码接口的 `action_type`。
    /// 期望：`login_by_mobile_captcha`，App 用它决定后续流程。
    func testCreateCaptchaActionType() {
        let envelope = AccountMock.handle(AccountRequest(method: "createLoginCaptcha", mobile: "13800138001"))
        XCTAssertEqual(envelope.data["action_type"]?.stringValue, "login_by_mobile_captcha")
    }

    /// 场景：请求验证码时手机号不在白名单。
    /// 期望：业务码 `-3101`，消息为「手机号未注册」。
    func testCreateCaptchaUnregisteredPhone() {
        let envelope = AccountMock.handle(AccountRequest(method: "createLoginCaptcha", mobile: "13900000000"))
        XCTAssertEqual(envelope.retcode, -3101)
        XCTAssertEqual(envelope.message, "手机号未注册")
        XCTAssertEqual(envelope.data, .object([:]))
    }

    /// 场景：请求验证码时手机号为空。
    /// 期望：同样按未注册处理，返回 `-3101`。
    func testCreateCaptchaEmptyMobile() {
        XCTAssertEqual(AccountMock.handle(AccountRequest(method: "createLoginCaptcha")).retcode, -3101)
    }

    /// 场景：手机号 + 正确验证码登录。
    /// 期望：`token_type` 为 1，代表 stoken。
    func testLoginTokenType() {
        let envelope = AccountMock.handle(
            AccountRequest(method: "loginByMobileCaptcha", mobile: "13800138000", captcha: "111111")
        )
        XCTAssertEqual(envelope.retcode, 0)
        XCTAssertEqual(envelope.data["token"]?["token_type"]?.intValue, 1)
    }

    /// 场景：登录成功返回的 stoken。
    /// 期望：`mock_stoken_{accountId}`，后续换 Token 依赖这个格式。
    func testLoginTokenValue() {
        let envelope = AccountMock.handle(
            AccountRequest(method: "loginByMobileCaptcha", mobile: "13800138001", captcha: "111111")
        )
        XCTAssertEqual(envelope.data["token"]?["token"]?.stringValue, "mock_stoken_348366494")
    }

    /// 场景：登录成功返回的 `user_info.aid`。
    /// 期望：与手机号映射的账号一致。
    func testLoginUserInfoAid() {
        let envelope = AccountMock.handle(
            AccountRequest(method: "loginByMobileCaptcha", mobile: "13800138000", captcha: "111111")
        )
        XCTAssertEqual(envelope.data["user_info"]?["aid"]?.stringValue, "182692936")
    }

    /// 场景：登录成功返回的 `user_info.mid`。
    /// 期望：`mock_mid_{accountId}`，保证两个账号不同。
    func testLoginUserInfoMid() {
        let envelope = AccountMock.handle(
            AccountRequest(method: "loginByMobileCaptcha", mobile: "13800138000", captcha: "111111")
        )
        XCTAssertEqual(envelope.data["user_info"]?["mid"]?.stringValue, "mock_mid_182692936")
    }

    /// 场景：登录成功回显手机号。
    /// 期望：`user_info.mobile` 等于请求里的号码。
    func testLoginUserInfoMobile() {
        let envelope = AccountMock.handle(
            AccountRequest(method: "loginByMobileCaptcha", mobile: "13800138001", captcha: "111111")
        )
        XCTAssertEqual(envelope.data["user_info"]?["mobile"]?.stringValue, "13800138001")
    }

    /// 场景：手机号正确但验证码错误。
    /// 期望：业务码 `-3001`，消息为「验证码错误」。
    func testLoginWrongCaptcha() {
        let envelope = AccountMock.handle(
            AccountRequest(method: "loginByMobileCaptcha", mobile: "13800138000", captcha: "000000")
        )
        XCTAssertEqual(envelope.retcode, -3001)
        XCTAssertEqual(envelope.message, "验证码错误")
    }

    /// 场景：手机号与验证码同时错误。
    /// 期望：先校验手机号，返回 `-3101`（顺序与 Node 版一致）。
    func testLoginUnregisteredPhoneWinsOverCaptcha() {
        let envelope = AccountMock.handle(
            AccountRequest(method: "loginByMobileCaptcha", mobile: "13900000000", captcha: "000000")
        )
        XCTAssertEqual(envelope.retcode, -3101)
    }

    /// 场景：验证码为空。
    /// 期望：按错误验证码处理，返回 `-3001`。
    func testLoginEmptyCaptcha() {
        let envelope = AccountMock.handle(
            AccountRequest(method: "loginByMobileCaptcha", mobile: "13800138000", captcha: "")
        )
        XCTAssertEqual(envelope.retcode, -3001)
    }

    /// 场景：用合法 stoken 换 ltoken。
    /// 期望：返回 `mock_ltoken_{accountId}`。
    func testGetLTokenBySToken() {
        let envelope = AccountMock.handle(
            AccountRequest(method: "getLTokenBySToken", stoken: "mock_stoken_182692936")
        )
        XCTAssertEqual(envelope.retcode, 0)
        XCTAssertEqual(envelope.data["ltoken"]?.stringValue, "mock_ltoken_182692936")
    }

    /// 场景：stoken 不符合 `mock_stoken_` 前缀。
    /// 期望：回退到固定账号，不返回错误（mock 服务不校验 stoken）。
    func testGetLTokenFallsBackForForeignSToken() {
        let envelope = AccountMock.handle(
            AccountRequest(method: "getLTokenBySToken", stoken: "real_stoken_from_app")
        )
        XCTAssertEqual(envelope.data["ltoken"]?.stringValue, "mock_ltoken_182692936")
    }

    /// 场景：stoken 只有前缀、没有账号部分。
    /// 期望：同样回退到固定账号。
    func testGetLTokenEmptySuffixFallsBack() {
        XCTAssertEqual(AccountMock.accountIdFromStoken("mock_stoken_"), "182692936")
        XCTAssertEqual(AccountMock.accountIdFromStoken(""), "182692936")
    }

    /// 场景：用 stoken 换 cookie_token 的 `uid`。
    /// 期望：与 stoken 中的账号一致。
    func testGetCookieTokenUid() {
        let envelope = AccountMock.handle(
            AccountRequest(method: "getCookieTokenBySToken", stoken: "mock_stoken_348366494")
        )
        XCTAssertEqual(envelope.data["uid"]?.stringValue, "348366494")
    }

    /// 场景：用 stoken 换 cookie_token 的值。
    /// 期望：`mock_cookie_token_{accountId}`。
    func testGetCookieTokenValue() {
        let envelope = AccountMock.handle(
            AccountRequest(method: "getCookieTokenBySToken", stoken: "mock_stoken_182692936")
        )
        XCTAssertEqual(
            envelope.data["cookie_token"]?.stringValue,
            "mock_cookie_token_182692936"
        )
    }

    /// 场景：申请登录二维码。
    /// 期望：ticket 与扫码 URL 使用同一个 ticket。
    func testFetchQRCode() {
        let envelope = AccountMock.handle(AccountRequest(method: "fetchQRCode"))
        let ticket = envelope.data["ticket"]?.stringValue
        XCTAssertEqual(ticket, "mock_ticket_182692936")
        XCTAssertEqual(
            envelope.data["url"]?.stringValue,
            "https://user.mihoyo.com/qr_code_in_game.html?ticket=mock_ticket_182692936"
        )
    }

    /// 场景：轮询二维码状态。
    /// 期望：固定返回 `init`，方便反复测试未确认分支。
    func testQueryQRCode() {
        let envelope = AccountMock.handle(AccountRequest(method: "queryQRCode"))
        XCTAssertEqual(envelope.retcode, 0)
        XCTAssertEqual(envelope.data["status"]?.stringValue, "init")
    }

    /// 场景：刷新 cookie_token 与 ltoken。
    /// 期望：分别返回固定的 mock 值，且都是成功响应。
    func testRefreshTokens() {
        XCTAssertEqual(
            AccountMock.handle(AccountRequest(method: "refreshCookieToken"))
                .data["cookie_token"]?.stringValue,
            "mock_cookie_token"
        )
        XCTAssertEqual(
            AccountMock.handle(AccountRequest(method: "refreshLToken"))
                .data["ltoken"]?.stringValue,
            "mock_ltoken"
        )
    }

    /// 场景：校验 ltoken 与未知方法。
    /// 期望：校验返回空 `data` 的成功响应；未知方法返回 `-1` 并带上方法名。
    func testVerifyLTokenAndUnknownMethod() {
        let verified = AccountMock.handle(AccountRequest(method: "verifyLToken"))
        XCTAssertEqual(verified.retcode, 0)
        XCTAssertEqual(verified.data, .object([:]))

        let unknown = AccountMock.handle(AccountRequest(method: "notARealMethod"))
        XCTAssertEqual(unknown.retcode, -1)
        XCTAssertTrue(unknown.message.contains("notARealMethod"))
    }
}
