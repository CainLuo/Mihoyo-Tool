import Foundation

/// 直连路径代理：把 App 的真实 API 请求映射到 fixture。
///
/// 这是推荐接入方式（Mock.md 方案 A）：App 只需把 base URL 指向 `127.0.0.1:8787`，
/// 不需要恢复任何 Mock 适配器。
public struct FixtureRouter: Sendable {
    /// fixture 仓库。
    public let store: FixtureStore

    public init(store: FixtureStore) {
        self.store = store
    }

    /// 由 HTTP 请求构造 fixture 查询。
    ///
    /// 角色 ID 优先取 query/body，avatarId 由 `FixtureResolver` 从 `id_list[]` 推导。
    /// 直接代理不启用 `fallbackEmptyList`，保持「找不到就是空对象」的旧行为。
    public func query(for request: MockRequest) -> FixtureQuery {
        FixtureQuery(
            path: request.url,
            cookie: request.cookie,
            roleId: nil,
            avatarId: nil,
            body: request.bodyText.isEmpty ? nil : request.bodyText,
            fallbackEmptyList: false
        )
    }

    /// 处理直连请求。
    ///
    /// 命中时原样回写 fixture 字节；未命中时返回 `{retcode:0,message:"success",data:{}}`，
    /// 与 Node 版一致，避免 App 因为 404 走进错误分支。
    public func respond(to request: MockRequest) -> (response: MockHTTPResponse, lookup: FixtureLookup) {
        let lookup = store.lookup(query(for: request))
        if let fixture = lookup.fixture {
            return (.raw(fixture.data), lookup)
        }
        return (.envelope(.empty(fallbackEmptyList: false)), lookup)
    }
}

/// 签到 Mock。
///
/// 当前仓库没有签到 fixture，因此所有已知方法都返回空成功响应；
/// 一旦按约定补上 fixture，路径规则会让它自动生效，无需改代码。
public enum SignMock {
    /// 由 `gameBiz` 推导签到 fixture 的 host 片段。
    ///
    /// - `hk4e_cn` / `hk4e_global` → `hk4e`
    /// - `hkrpg_cn` → `hkrpg`
    /// - `nap_cn` / `zzz_cn` → `zzz`
    /// - 其他：取第一个 `_` 之前的部分；没有 `_` 时原样返回。
    public static func host(forGameBiz gameBiz: String) -> String {
        if gameBiz.hasPrefix("hk4e") { return "hk4e" }
        if gameBiz.hasPrefix("hkrpg") { return "hkrpg" }
        if gameBiz.hasPrefix("nap") || gameBiz.hasPrefix("zzz") { return "zzz" }
        if let underscore = gameBiz.firstIndex(of: "_"), underscore != gameBiz.startIndex {
            return String(gameBiz[gameBiz.startIndex..<underscore])
        }
        return gameBiz
    }

    /// 计算签到 fixture 的相对路径。
    ///
    /// - 大别野：`{accountId}/apihub_app_api_signIn.json`
    /// - 游戏签到：`account{accountId}/event_luna_{host}_{suffix}.json`
    ///
    /// 未知方法返回 nil。
    public static func relativePath(for request: SignRequest) -> String? {
        let accountId = CookieParser.accountId(from: request.cookie)

        if let method = SignMethod(rawValue: request.method) {
            switch method {
            case .signBBS:
                return "\(accountId)/apihub_app_api_signIn.json"
            case .signGame, .getSignInfo, .getSignReward:
                let suffix: String
                switch method {
                case .signGame: suffix = "sign"
                case .getSignInfo: suffix = "info"
                default: suffix = "home"
                }
                let host = host(forGameBiz: request.gameBiz)
                return "account\(accountId)/event_luna_\(host)_\(suffix).json"
            }
        }
        return nil
    }

    /// 处理签到请求。
    ///
    /// 返回原始 fixture（若存在）或空成功信封；未知方法返回 `-1`。
    public static func result(for request: SignRequest, store: FixtureStore) -> Result<MockRPCResult, MockRPCError> {
        guard let relativePath = relativePath(for: request) else {
            return .failure(.unknownMethod("unknown sign method: \(request.method)"))
        }
        if let fixture = store.load(relativePath: relativePath) {
            return .success(.rawJSON(fixture.data))
        }
        return .success(.envelope(.empty(fallbackEmptyList: false)))
    }
}
