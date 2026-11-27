import XCTest
@testable import MockServerCore

/// 测试共享的仓库定位与夹具常量。
///
/// `#filePath` 指向本文件：`<repo>/mock-service-vapor/Tests/MockServerCoreTests/`，
/// 向上 4 层即仓库根目录，因此测试直接复用 `mock-service/fixtures`，不复制任何数据。
enum TestFixtures {
    /// 仓库根目录。
    static var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // MockServerCoreTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // mock-service-vapor
            .deletingLastPathComponent() // repo root
    }

    /// Node 版与 Swift 版共用的 fixture 根目录。
    static var fixturesDirectory: URL {
        repositoryRoot.appendingPathComponent("mock-service/fixtures", isDirectory: true)
    }

    /// 每个用例新建一个只读仓库，避免共享可变状态。
    static var store: FixtureStore { FixtureStore(root: fixturesDirectory) }

    /// 主测试账号（原神 + 绝区零）。
    static let genshinAccountId = "182692936"
    /// 账号 182692936 下的原神角色。
    static let genshinRoleId = "109050292"
    /// 账号 182692936 下的另一个原神角色（有 avatar_compute 目录）。
    static let computeRoleId = "102731382"
    /// 账号 182692936 下的绝区零角色。
    static let zzzRoleId = "37716744"
    /// 第二个测试账号（星穹铁道）。
    static let secondAccountId = "348366494"
    /// 第二个账号下的星穹铁道角色。
    static let hkrpgRoleId = "111310091"

    /// 构造一份最小可用 Cookie。
    static func cookie(accountId: String = genshinAccountId) -> String {
        "account_id=\(accountId); cookie_token=mock_cookie; ltuid=\(accountId); ltoken=mock_ltoken"
    }

    /// 账号 182692936 的 Cookie 快捷方式。
    static var cookie182: String { cookie() }
    /// 账号 348366494 的 Cookie 快捷方式。
    static var cookie348: String { cookie(accountId: secondAccountId) }
}

/// `FixtureStore` 的只读仓库行为。
///
/// 直接针对仓库里真实的 224 份 fixture 断言，这样能同时守住
/// 「默认目录能找到」和「映射文件名真的存在」两件事。
final class FixtureStoreTests: XCTestCase {

    /// 场景：用相对路径构造仓库。
    /// 期望：root 被标准化成绝对路径，后续拼接不受 `./` 影响。
    func testRootIsStandardized() {
        let store = FixtureStore(root: TestFixtures.fixturesDirectory.appendingPathComponent("./"))
        XCTAssertEqual(store.root.standardizedFileURL.path, TestFixtures.fixturesDirectory.standardizedFileURL.path)
    }

    /// 场景：指向仓库内真实 fixtures 目录。
    /// 期望：`exists` 为 true。
    func testExistsTrue() {
        XCTAssertTrue(TestFixtures.store.exists)
    }

    /// 场景：指向一个不存在的目录。
    /// 期望：`exists` 为 false，CLI 据此拒绝启动。
    func testExistsFalseForMissingDirectory() {
        let store = FixtureStore(root: URL(fileURLWithPath: "/tmp/definitely-missing-fixtures-dir"))
        XCTAssertFalse(store.exists)
    }

    /// 场景：递归统计 fixture 数量。
    /// 期望：与仓库现有 224 份 JSON 一致。
    func testCountIs224() {
        XCTAssertEqual(TestFixtures.store.count(), 224)
    }

    /// 场景：列出全部 fixture 相对路径。
    /// 期望：按字典序排序，便于稳定断言与排查缺口。
    func testAllRelativePathsSorted() {
        let paths = TestFixtures.store.allRelativePaths()
        XCTAssertEqual(paths, paths.sorted())
        XCTAssertEqual(paths.count, 224)
    }

    /// 场景：枚举结果的后缀。
    /// 期望：只收集 `.json`，不把目录或其他文件算进来。
    func testAllRelativePathsAreJSON() {
        XCTAssertTrue(TestFixtures.store.allRelativePaths().allSatisfy { $0.hasSuffix(".json") })
    }

    /// 场景：读取一个存在的角色级 fixture。
    /// 期望：返回非空字节，且 JSON 可解析。
    func testLoadReturnsFileBytes() {
        let fixture = TestFixtures.store.load(
            relativePath: "182692936/109050292/game_record_app_genshin_api_dailyNote.json"
        )
        XCTAssertNotNil(fixture)
        XCTAssertGreaterThan(fixture?.byteCount ?? 0, 0)
        XCTAssertNotNil(fixture?.json)
    }

    /// 场景：相对路径带前导 `/`。
    /// 期望：被安全地规范化，仍能读到文件。
    func testLoadStripsLeadingSlash() {
        let fixture = TestFixtures.store.load(
            relativePath: "/182692936/binding_api_getUserGameRolesByCookie.json"
        )
        XCTAssertNotNil(fixture)
        XCTAssertEqual(fixture?.relativePath, "182692936/binding_api_getUserGameRolesByCookie.json")
    }

    /// 场景：文件不存在。
    /// 期望：返回 nil，由调用方回退到空响应，而不是抛错。
    func testLoadMissingReturnsNil() {
        XCTAssertNil(TestFixtures.store.load(relativePath: "182692936/does_not_exist.json"))
    }

    /// 场景：空相对路径。
    /// 期望：返回 nil，避免把目录本身当文件读。
    func testLoadEmptyPathReturnsNil() {
        XCTAssertNil(TestFixtures.store.load(relativePath: ""))
        XCTAssertNil(TestFixtures.store.load(relativePath: "/"))
    }

    /// 场景：相对路径包含 `..` 试图逃出 fixtures 根目录。
    /// 期望：被拒绝，返回 nil（不能读到 Package.swift）。
    func testLoadRejectsTraversal() {
        XCTAssertNil(TestFixtures.store.load(relativePath: "../../Package.swift"))
        XCTAssertNil(TestFixtures.store.load(relativePath: "182692936/../../../Package.swift"))
    }

    /// 场景：候选列表中只有第二个存在。
    /// 期望：跳过缺失项，返回第一个命中的 fixture。
    func testFindReturnsFirstExisting() {
        let fixture = TestFixtures.store.find(candidates: [
            "182692936/missing.json",
            "182692936/109050292/game_record_app_genshin_api_dailyNote.json",
        ])
        XCTAssertEqual(
            fixture?.relativePath,
            "182692936/109050292/game_record_app_genshin_api_dailyNote.json"
        )
    }

    /// 场景：全部候选都不存在。
    /// 期望：返回 nil。
    func testFindNilWhenAllMissing() {
        XCTAssertNil(TestFixtures.store.find(candidates: ["a.json", "b.json"]))
    }

    /// 场景：账号 + 角色 + 常规接口。
    /// 期望：命中角色目录下的 dailyNote，并解析出树脂数量。
    func testLookupHitsRoleLevelFixture() {
        let lookup = TestFixtures.store.lookup(
            FixtureQuery(
                path: "/game_record/app/genshin/api/dailyNote?role_id=\(TestFixtures.genshinRoleId)",
                cookie: TestFixtures.cookie182
            )
        )
        XCTAssertEqual(
            lookup.file,
            "182692936/109050292/game_record_app_genshin_api_dailyNote.json"
        )
        XCTAssertEqual(lookup.fixture?.json?["data"]?["current_resin"]?.intValue, 152)
    }

    /// 场景：账号级接口（没有角色 ID）。
    /// 期望：直接命中 `{accountId}/{fileName}`。
    func testLookupFallsBackToAccountLevel() {
        let lookup = TestFixtures.store.lookup(
            FixtureQuery(
                path: "/binding/api/getUserGameRolesByCookie",
                cookie: TestFixtures.cookie182
            )
        )
        XCTAssertEqual(lookup.file, "182692936/binding_api_getUserGameRolesByCookie.json")
        XCTAssertNil(lookup.resolution.roleId.isEmpty ? nil : "unexpected-role")
    }

    /// 场景：账号有、但该接口没有 fixture。
    /// 期望：fixture 为 nil，但 resolution 仍保留账号与候选，便于日志定位。
    func testLookupMissKeepsResolution() {
        let lookup = TestFixtures.store.lookup(
            FixtureQuery(
                path: "/game_record/app/genshin/api/dailyNote?role_id=\(TestFixtures.genshinRoleId)",
                cookie: "account_id=999999"
            )
        )
        XCTAssertNil(lookup.fixture)
        XCTAssertEqual(lookup.resolution.accountId, 999999)
        XCTAssertEqual(lookup.resolution.candidates.count, 2)
    }

    /// 场景：读取含中文的绝区零角色 fixture。
    /// 期望：JSON 能解析，且保留原始中文字段（UTF-8 不损坏）。
    func testFixtureJSONParses() {
        let fixture = TestFixtures.store.load(relativePath: "182692936/37716744/1171.json")
        XCTAssertEqual(fixture?.json?["retcode"]?.intValue, 0)
        XCTAssertEqual(
            fixture?.json?["data"]?["avatar_list"]?.arrayValue?.first?["name_mi18n"]?.stringValue,
            "柏妮思"
        )
    }

    /// 场景：fixture 字节大小。
    /// 期望：`byteCount` 与实际 `Data` 长度一致，健康检查与日志的数字可信。
    func testByteCountMatchesData() {
        let fixture = TestFixtures.store.load(
            relativePath: "182692936/109050292/game_record_app_genshin_api_dailyNote.json"
        )
        XCTAssertEqual(fixture?.byteCount, fixture?.data.count)
    }
}
