import XCTest
@testable import MockServerCore

/// `SignMock` 的签到接口行为。
///
/// 仓库目前没有签到 fixture（`apihub_app_signIn.json` 与
/// `account*/event_luna_*.json` 都不存在），所以成功分支统一回落到空信封；
/// 这里同时锁定「路径规则」，将来补上 fixture 就会自动生效。
final class SignMockTests: XCTestCase {

    /// 场景：原神国服 `hk4e_cn`。
    /// 期望：host 片段为 `hk4e`。
    func testHostHk4eCn() {
        XCTAssertEqual(SignMock.host(forGameBiz: "hk4e_cn"), "hk4e")
    }

    /// 场景：原神国际服 `hk4e_global`。
    /// 期望：同样归到 `hk4e`，两个服共用一份签到数据。
    func testHostHk4eGlobal() {
        XCTAssertEqual(SignMock.host(forGameBiz: "hk4e_global"), "hk4e")
    }

    /// 场景：星穹铁道国服 `hkrpg_cn`。
    /// 期望：host 片段为 `hkrpg`。
    func testHostHkrpgCn() {
        XCTAssertEqual(SignMock.host(forGameBiz: "hkrpg_cn"), "hkrpg")
    }

    /// 场景：绝区零 `nap_cn`。
    /// 期望：归一化成 `zzz`，与 fixture 目录命名一致。
    func testHostNapCn() {
        XCTAssertEqual(SignMock.host(forGameBiz: "nap_cn"), "zzz")
    }

    /// 场景：绝区零另一种写法 `zzz_cn`。
    /// 期望：同样得到 `zzz`。
    func testHostZzzCn() {
        XCTAssertEqual(SignMock.host(forGameBiz: "zzz_cn"), "zzz")
    }

    /// 场景：未知业务但带下划线。
    /// 期望：取第一个下划线之前的部分。
    func testHostUnknownWithUnderscore() {
        XCTAssertEqual(SignMock.host(forGameBiz: "bh3_cn"), "bh3")
    }

    /// 场景：未知业务且没有下划线。
    /// 期望：原样返回。
    func testHostWithoutUnderscore() {
        XCTAssertEqual(SignMock.host(forGameBiz: "hk4e"), "hk4e")
    }

    /// 场景：空业务标识。
    /// 期望：返回空串，不崩溃。
    func testHostEmpty() {
        XCTAssertEqual(SignMock.host(forGameBiz: ""), "")
    }

    /// 场景：签到方法集合。
    /// 期望：共 4 个。
    func testSignMethodCount() {
        XCTAssertEqual(SignMethod.allCases.count, 4)
    }

    /// 场景：大别野签到。
    /// 期望：路径是账号目录下的 `apihub_app_signIn.json`。
    func testRelativePathSignBBS() {
        let path = SignMock.relativePath(
            for: SignRequest(method: "signBBS", cookie: TestFixtures.cookie182)
        )
        XCTAssertEqual(path, "182692936/apihub_app_api_signIn.json")
    }

    /// 场景：原神游戏内签到。
    /// 期望：`account{aid}/event_luna_hk4e_sign.json`。
    func testRelativePathSignGameGenshin() {
        let path = SignMock.relativePath(
            for: SignRequest(method: "signGame", cookie: TestFixtures.cookie182, gameBiz: "hk4e_cn")
        )
        XCTAssertEqual(path, "account182692936/event_luna_hk4e_sign.json")
    }

    /// 场景：星穹铁道查询签到信息。
    /// 期望：后缀是 `info`，host 是 `hkrpg`。
    func testRelativePathSignInfoHKRPG() {
        let path = SignMock.relativePath(
            for: SignRequest(method: "getSignInfo", cookie: TestFixtures.cookie348, gameBiz: "hkrpg_cn")
        )
        XCTAssertEqual(path, "account348366494/event_luna_hkrpg_info.json")
    }

    /// 场景：绝区零查询签到奖励。
    /// 期望：后缀是 `home`，host 归一化成 `zzz`。
    func testRelativePathSignRewardNap() {
        let path = SignMock.relativePath(
            for: SignRequest(method: "getSignReward", cookie: TestFixtures.cookie182, gameBiz: "nap_cn")
        )
        XCTAssertEqual(path, "account182692936/event_luna_zzz_home.json")
    }

    /// 场景：未知签到方法。
    /// 期望：`relativePath` 返回 nil，调用方据此报 400。
    func testRelativePathUnknownMethod() {
        XCTAssertNil(SignMock.relativePath(for: SignRequest(method: "signMars")))
    }

    /// 场景：Cookie 里没有账号字段。
    /// 期望：账号目录回退到默认 `1`。
    func testRelativePathUsesFallbackAccount() {
        let path = SignMock.relativePath(for: SignRequest(method: "signBBS", cookie: ""))
        XCTAssertEqual(path, "1/apihub_app_api_signIn.json")
    }

    /// 场景：大别野签到但仓库没有对应 fixture。
    /// 期望：返回空成功信封，`message=success`、`data={}`。
    func testSignBBSFallsBackToEmptyEnvelope() throws {
        let result = SignMock.result(
            for: SignRequest(method: "signBBS", cookie: TestFixtures.cookie182),
            store: TestFixtures.store
        )
        let payload = try XCTUnwrap(try result.get())
        XCTAssertEqual(payload, .envelope(.empty(fallbackEmptyList: false)))
        let json = try XCTUnwrap(payload.body.isEmpty ? nil : JSONValue(parsing: payload.body))
        XCTAssertEqual(json["retcode"]?.intValue, 0)
        XCTAssertEqual(json["message"]?.stringValue, "success")
    }

    /// 场景：游戏内签到但仓库没有对应 fixture。
    /// 期望：同样回落到空信封，而不是 404。
    func testSignGameFallsBackToEmptyEnvelope() throws {
        let result = SignMock.result(
            for: SignRequest(method: "signGame", cookie: TestFixtures.cookie348, gameBiz: "hkrpg_cn"),
            store: TestFixtures.store
        )
        XCTAssertEqual(try result.get(), .envelope(.empty(fallbackEmptyList: false)))
    }

    /// 场景：未知签到方法。
    /// 期望：返回 `.unknownMethod` 错误，HTTP 层转 400。
    func testResultUnknownMethod() {
        let result = SignMock.result(
            for: SignRequest(method: "signMars", cookie: TestFixtures.cookie182),
            store: TestFixtures.store
        )
        guard case let .failure(error) = result else {
            return XCTFail("expected failure, got \(result)")
        }
        XCTAssertEqual(error, .unknownMethod("unknown sign method: signMars"))
        XCTAssertEqual(error.message, "unknown sign method: signMars")
    }
}
