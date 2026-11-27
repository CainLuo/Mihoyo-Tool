import Foundation

/// 账号接口的方法名。App 侧登录流程调用的就是这些方法。
public enum AccountMethod: String, CaseIterable, Sendable {
    /// 发送手机验证码。
    case createLoginCaptcha
    /// 手机号 + 验证码登录。
    case loginByMobileCaptcha
    /// 用 stoken 换 ltoken。
    case getLTokenBySToken
    /// 用 stoken 换 cookie_token。
    case getCookieTokenBySToken
    /// 申请二维码。
    case fetchQRCode
    /// 轮询二维码状态。
    case queryQRCode
    /// 刷新 cookie_token。
    case refreshCookieToken
    /// 刷新 ltoken。
    case refreshLToken
    /// 校验 ltoken。
    case verifyLToken
}

/// 一次账号 Mock 请求。
public struct AccountRequest: Sendable, Equatable {
    /// 方法名；未知方法返回 `-1`。
    public var method: String
    /// 手机号，仅验证码相关方法使用。
    public var mobile: String
    /// 验证码，仅 `loginByMobileCaptcha` 使用。
    public var captcha: String
    /// stoken，仅 Token 换取方法使用。
    public var stoken: String

    public init(method: String, mobile: String = "", captcha: String = "", stoken: String = "") {
        self.method = method
        self.mobile = mobile
        self.captcha = captcha
        self.stoken = stoken
    }

    /// 已识别的方法；未知方法为 nil。
    public var knownMethod: AccountMethod? {
        AccountMethod(rawValue: method)
    }
}

/// 账号 Mock 的固定数据与行为。
///
/// 所有返回值都与 Node 版逐字段对齐，App 侧不需要区分后端是 Node 还是 Swift。
public enum AccountMock {
    /// 手机号 → 账号 ID 白名单。只有这两个号码能登录成功。
    public static let phoneToAccountId: [String: String] = [
        "13800138000": "182692936",
        "13800138001": "348366494",
    ]

    /// 唯一有效验证码。
    public static let captchaCode = "111111"

    /// stoken 前缀；换取 Token 时从这里解析账号。
    public static let stokenPrefix = "mock_stoken_"

    /// 二维码固定返回的账号。
    public static let qrCodeAccountId = "182692936"

    /// 手机号未注册的业务码。
    public static let unregisteredPhoneRetcode = -3101
    /// 验证码错误的业务码。
    public static let wrongCaptchaRetcode = -3001

    /// 处理请求，返回统一信封。
    public static func handle(_ request: AccountRequest) -> MockEnvelope {
        switch AccountMethod(rawValue: request.method) {
        case .createLoginCaptcha:
            guard phoneToAccountId[request.mobile] != nil else {
                return .error(retcode: unregisteredPhoneRetcode, message: "手机号未注册")
            }
            return .ok(.object([
                "sent_new": .bool(true),
                "countdown": .int(60),
                "action_type": .string("login_by_mobile_captcha"),
            ]))

        case .loginByMobileCaptcha:
            guard let accountId = phoneToAccountId[request.mobile] else {
                return .error(retcode: unregisteredPhoneRetcode, message: "手机号未注册")
            }
            guard request.captcha == captchaCode else {
                return .error(retcode: wrongCaptchaRetcode, message: "验证码错误")
            }
            return .ok(.object([
                "token": .object([
                    // token_type = 1 表示 stoken（米游社登录态）。
                    "token_type": .int(1),
                    "token": .string(stokenPrefix + accountId),
                ]),
                "user_info": .object([
                    "aid": .string(accountId),
                    "mid": .string("mock_mid_\(accountId)"),
                    "mobile": .string(request.mobile),
                ]),
            ]))

        case .getLTokenBySToken:
            let accountId = accountIdFromStoken(request.stoken)
            return .ok(.object(["ltoken": .string("mock_ltoken_\(accountId)")]))

        case .getCookieTokenBySToken:
            let accountId = accountIdFromStoken(request.stoken)
            return .ok(.object([
                "uid": .string(accountId),
                "cookie_token": .string("mock_cookie_token_\(accountId)"),
            ]))

        case .fetchQRCode:
            let ticket = "mock_ticket_\(qrCodeAccountId)"
            return .ok(.object([
                "ticket": .string(ticket),
                "url": .string("https://user.mihoyo.com/qr_code_in_game.html?ticket=\(ticket)"),
            ]))

        case .queryQRCode:
            // 固定 init，不自动确认登录，便于反复测试轮询分支。
            return .ok(.object(["status": .string("init")]))

        case .refreshCookieToken:
            return .ok(.object(["cookie_token": .string("mock_cookie_token")]))

        case .refreshLToken:
            return .ok(.object(["ltoken": .string("mock_ltoken")]))

        case .verifyLToken:
            return .ok(.object([:]))

        case .none:
            return .error(retcode: -1, message: "unknown account method: \(request.method)")
        }
    }

    /// 从 `mock_stoken_{aid}` 解析账号；不符合前缀时回退到默认账号。
    public static func accountIdFromStoken(_ stoken: String) -> String {
        guard stoken.hasPrefix(stokenPrefix) else {
            return qrCodeAccountId
        }
        let accountId = String(stoken.dropFirst(stokenPrefix.count))
        return accountId.isEmpty ? qrCodeAccountId : accountId
    }
}

/// 签到接口的方法名。
public enum SignMethod: String, CaseIterable, Sendable {
    /// 大别野签到。
    case signBBS
    /// 游戏内签到。
    case signGame
    /// 查询签到信息。
    case getSignInfo
    /// 查询签到奖励。
    case getSignReward
}

/// 一次签到 Mock 请求。
public struct SignRequest: Sendable, Equatable {
    public var method: String
    /// Cookie，用于提取账号目录。
    public var cookie: String
    /// 游戏业务标识，例如 `hk4e_cn`、`hkrpg_cn`、`nap_cn`。
    public var gameBiz: String

    public init(method: String, cookie: String = "", gameBiz: String = "") {
        self.method = method
        self.cookie = cookie
        self.gameBiz = gameBiz
    }

    public var knownMethod: SignMethod? {
        SignMethod(rawValue: method)
    }
}
