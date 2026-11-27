import XCTest
@testable import MockServerCore

/// `FixtureResolver` 的账号 / 角色 / avatar 提取与候选路径计算。
///
/// 这一层决定「从哪个目录读文件」，错了同样只会得到空响应，
/// 所以每个优先级分支都单独覆盖。
final class FixtureResolverTests: XCTestCase {

    // MARK: - 账号提取

    /// 场景：Cookie 里带 `account_id`。
    /// 期望：直接取该值作为账号目录名。
    func testExtractAccountIdFromAccountId() {
        XCTAssertEqual(
            FixtureResolver.extractAccountId(cookie: "account_id=182692936; cookie_token=x"),
            182692936
        )
    }

    /// 场景：Cookie 只有 `stuid`（部分真实接口只带这个）。
    /// 期望：回退到 `stuid`。
    func testExtractAccountIdFromStuid() {
        XCTAssertEqual(FixtureResolver.extractAccountId(cookie: "stuid=348366494"), 348366494)
    }

    /// 场景：`account_id` 与 `stuid` 同时存在。
    /// 期望：`account_id` 优先，这是 Node 版的顺序。
    func testExtractAccountIdPrefersAccountId() {
        XCTAssertEqual(
            FixtureResolver.extractAccountId(cookie: "stuid=999; account_id=182692936"),
            182692936
        )
    }

    /// 场景：Cookie 为空。
    /// 期望：回退到默认账号 `1`。
    func testExtractAccountIdFallsBackToOne() {
        XCTAssertEqual(FixtureResolver.extractAccountId(cookie: ""), 1)
    }

    /// 场景：`account_id` 是浮点字符串 `1.5`。
    /// 期望：只取连续数字前缀，得到 `1`（对齐 JS `parseInt`）。
    func testExtractAccountIdTruncatesFloat() {
        XCTAssertEqual(FixtureResolver.extractAccountId(cookie: "account_id=1.5"), 1)
    }

    /// 场景：`account_id` 存在但值为空。
    /// 期望：视为缺失，回退默认账号。
    func testExtractAccountIdEmptyValueFallsBack() {
        XCTAssertEqual(FixtureResolver.extractAccountId(cookie: "account_id=;"), 1)
    }

    // MARK: - 角色提取

    /// 场景：query 里带 `role_id`。
    /// 期望：直接取到角色 ID。
    func testExtractRoleIdFromQueryRoleId() {
        XCTAssertEqual(
            FixtureResolver.extractRoleId(path: "/x?role_id=109050292&server=cn_gf01", body: nil),
            "109050292"
        )
    }

    /// 场景：query 里只有 `uid`。
    /// 期望：回退到 `uid`。
    func testExtractRoleIdFromQueryUid() {
        XCTAssertEqual(FixtureResolver.extractRoleId(path: "/x?uid=250375401", body: nil), "250375401")
    }

    /// 场景：query 同时有 `role_id` 与 `uid`。
    /// 期望：`role_id` 优先。
    func testExtractRoleIdPrefersRoleIdOverUid() {
        XCTAssertEqual(
            FixtureResolver.extractRoleId(path: "/x?uid=1&role_id=2", body: nil),
            "2"
        )
    }

    /// 场景：query 没有角色信息，body 里有 `role_id`。
    /// 期望：从 JSON body 提取。
    func testExtractRoleIdFromBodyRoleId() {
        XCTAssertEqual(
            FixtureResolver.extractRoleId(path: "/x", body: "{\"role_id\":109050292}"),
            "109050292"
        )
    }

    /// 场景：body 里只有 `uid`。
    /// 期望：从 body 的 `uid` 提取。
    func testExtractRoleIdFromBodyUid() {
        XCTAssertEqual(
            FixtureResolver.extractRoleId(path: "/x", body: "{\"uid\":\"37716744\"}"),
            "37716744"
        )
    }

    /// 场景：query 与 body 都带角色 ID。
    /// 期望：query 优先，避免 body 覆盖 URL 语义。
    func testExtractRoleIdQueryBeatsBody() {
        XCTAssertEqual(
            FixtureResolver.extractRoleId(path: "/x?role_id=111", body: "{\"role_id\":222}"),
            "111"
        )
    }

    /// 场景：没有 body。
    /// 期望：返回空串，表示账号级请求。
    func testExtractRoleIdWithoutBody() {
        XCTAssertEqual(FixtureResolver.extractRoleId(path: "/x", body: nil), "")
    }

    /// 场景：body 不是合法 JSON。
    /// 期望：静默返回空串，不抛错（不能因为请求体畸形就 500）。
    func testExtractRoleIdInvalidJSON() {
        XCTAssertEqual(FixtureResolver.extractRoleId(path: "/x", body: "not json"), "")
    }

    /// 场景：body 是 JSON 数组而非对象。
    /// 期望：返回空串，只有对象才允许取字段。
    func testExtractRoleIdNonObjectBody() {
        XCTAssertEqual(FixtureResolver.extractRoleId(path: "/x", body: "[1,2]"), "")
    }

    // MARK: - 绝区零 avatarId

    /// 场景：绝区零角色详情带多个 `id_list[]`。
    /// 期望：只取第一个，对应 Node 版 `idList[0]`。
    func testExtractZZZAvatarIdTakesFirst() {
        XCTAssertEqual(
            FixtureResolver.extractZZZAvatarId(path: "/x?id_list%5B%5D=1171&id_list%5B%5D=1151"),
            "1171"
        )
    }

    /// 场景：完全没有 `id_list[]`。
    /// 期望：返回空串。
    func testExtractZZZAvatarIdMissing() {
        XCTAssertEqual(FixtureResolver.extractZZZAvatarId(path: "/x?role_id=1"), "")
    }

    /// 场景：判断绝区零角色详情路径。
    /// 期望：命中该接口返回 true。
    func testIsZZZAvatarInfoTrue() {
        XCTAssertTrue(FixtureResolver.isZZZAvatarInfo(path: "/event/game_record_zzz/api/zzz/avatar/info"))
    }

    /// 场景：普通接口。
    /// 期望：不是绝区零角色详情，返回 false。
    func testIsZZZAvatarInfoFalse() {
        XCTAssertFalse(FixtureResolver.isZZZAvatarInfo(path: "/game_record/app/genshin/api/dailyNote"))
    }

    // MARK: - 候选路径

    /// 场景：账号级接口（无 role_id）。
    /// 期望：只有一个候选 `{accountId}/{fileName}`。
    func testResolveAccountLevelCandidates() {
        let resolution = FixtureResolver.resolve(
            FixtureQuery(
                path: "/binding/api/getUserGameRolesByCookie",
                cookie: "account_id=182692936"
            )
        )
        XCTAssertEqual(resolution.accountId, 182692936)
        XCTAssertEqual(resolution.roleId, "")
        XCTAssertEqual(
            resolution.candidates,
            ["182692936/binding_api_getUserGameRolesByCookie.json"]
        )
    }

    /// 场景：带 role_id 的接口。
    /// 期望：先试角色目录，再回退账号目录，顺序固定。
    func testResolveRoleLevelCandidates() {
        let resolution = FixtureResolver.resolve(
            FixtureQuery(
                path: "/game_record/app/genshin/api/dailyNote?role_id=109050292",
                cookie: "account_id=182692936"
            )
        )
        XCTAssertEqual(resolution.roleId, "109050292")
        XCTAssertEqual(resolution.candidates, [
            "182692936/109050292/game_record_app_genshin_api_dailyNote.json",
            "182692936/game_record_app_genshin_api_dailyNote.json",
        ])
    }

    /// 场景：调用方显式传 `roleId`，同时 query 里也有 role_id。
    /// 期望：显式参数优先。
    func testResolveExplicitRoleIdWins() {
        let resolution = FixtureResolver.resolve(
            FixtureQuery(
                path: "/game_record/app/genshin/api/dailyNote?role_id=999",
                cookie: "account_id=182692936",
                roleId: "109050292"
            )
        )
        XCTAssertEqual(resolution.roleId, "109050292")
        XCTAssertEqual(
            resolution.candidates.first,
            "182692936/109050292/game_record_app_genshin_api_dailyNote.json"
        )
    }

    /// 场景：显式 roleId 带首尾空格。
    /// 期望：先 trim，空串则回退到 query/body 提取。
    func testResolveTrimsExplicitRoleId() {
        let resolution = FixtureResolver.resolve(
            FixtureQuery(
                path: "/x?role_id=109050292",
                cookie: "account_id=182692936",
                roleId: "   "
            )
        )
        XCTAssertEqual(resolution.roleId, "109050292")
    }

    /// 场景：养成计算接口 + avatarId。
    /// 期望：文件名变成 `avatar_compute/{avatarId}.json`。
    func testResolveComputeUsesAvatarComputeDirectory() {
        let resolution = FixtureResolver.resolve(
            FixtureQuery(
                path: "/event/e20200928calculate/v3/batch_compute?role_id=102731382",
                cookie: "account_id=182692936",
                avatarId: "1001"
            )
        )
        XCTAssertEqual(resolution.fileName, "avatar_compute/1001.json")
        XCTAssertEqual(
            resolution.candidates.first,
            "182692936/102731382/avatar_compute/1001.json"
        )
    }

    /// 场景：绝区零 `avatar_calc` 接口 + avatarId。
    /// 期望：同样走 `avatar_compute/` 目录。
    func testResolveZZZCalcUsesAvatarComputeDirectory() {
        let resolution = FixtureResolver.resolve(
            FixtureQuery(
                path: "/event/nap_cultivate_tool/avatar_calc?role_id=37716744",
                cookie: "account_id=182692936",
                avatarId: "1171"
            )
        )
        XCTAssertEqual(resolution.fileName, "avatar_compute/1171.json")
    }

    /// 场景：养成计算接口但没有 avatarId。
    /// 期望：退回整包 fixture，不拼 `avatar_compute/`。
    func testResolveComputeWithoutAvatarId() {
        let resolution = FixtureResolver.resolve(
            FixtureQuery(
                path: "/event/e20200928calculate/v3/batch_compute?role_id=109050292",
                cookie: "account_id=182692936"
            )
        )
        XCTAssertEqual(resolution.avatarId, "")
        XCTAssertEqual(resolution.fileName, "genshin_character_batch_compute.json")
    }

    /// 场景：绝区零角色详情，角色由 `id_list[]` 指定。
    /// 期望：从 query 推导 avatarId，文件名是 `{avatarId}.json`（不带 avatar_compute）。
    func testResolveZZZAvatarInfoFromIdList() {
        let resolution = FixtureResolver.resolve(
            FixtureQuery(
                path: "/event/game_record_zzz/api/zzz/avatar/info?role_id=37716744&id_list[]=1171",
                cookie: "account_id=182692936"
            )
        )
        XCTAssertEqual(resolution.avatarId, "1171")
        XCTAssertEqual(resolution.fileName, "1171.json")
        XCTAssertEqual(
            resolution.candidates,
            ["182692936/37716744/1171.json", "182692936/1171.json"]
        )
    }

    /// 场景：非计算、非绝区零详情的接口显式传 avatarId。
    /// 期望：文件名退化成 `{avatarId}.json`，不做目录前缀。
    func testResolveExplicitAvatarIdOnPlainPath() {
        let resolution = FixtureResolver.resolve(
            FixtureQuery(
                path: "/game_record/app/hkrpg/api/avatar/basic?role_id=111310091",
                cookie: "account_id=348366494",
                avatarId: " 1308 "
            )
        )
        XCTAssertEqual(resolution.avatarId, "1308")
        XCTAssertEqual(resolution.fileName, "1308.json")
    }

    /// 场景：候选路径里的账号来自 Cookie。
    /// 期望：账号变更会改变全部候选路径前缀。
    func testResolveUsesCookieAccount() {
        let resolution = FixtureResolver.resolve(
            FixtureQuery(
                path: "/game_record/app/genshin/api/dailyNote?role_id=250375401",
                cookie: "account_id=348366494"
            )
        )
        XCTAssertEqual(resolution.candidates, [
            "348366494/250375401/game_record_app_genshin_api_dailyNote.json",
            "348366494/game_record_app_genshin_api_dailyNote.json",
        ])
    }

    /// 场景：完整 URL 形式的路径。
    /// 期望：域名不影响文件名与候选路径。
    func testResolveFullURLPath() {
        let resolution = FixtureResolver.resolve(
            FixtureQuery(
                path: "https://api.example.com/game_record/app/genshin/api/dailyNote?role_id=109050292",
                cookie: "account_id=182692936"
            )
        )
        XCTAssertEqual(resolution.fileName, "game_record_app_genshin_api_dailyNote.json")
        XCTAssertEqual(resolution.candidates.count, 2)
    }

    /// 场景：角色 ID 只在 body 里。
    /// 期望：resolve 会带上 body 一起提取，得到角色级候选。
    func testResolveRoleFromBody() {
        let resolution = FixtureResolver.resolve(
            FixtureQuery(
                path: "/event/e20200928calculate/v3/batch_compute",
                cookie: "account_id=182692936",
                body: "{\"role_id\":\"109050292\"}"
            )
        )
        XCTAssertEqual(resolution.roleId, "109050292")
        XCTAssertEqual(
            resolution.candidates.first,
            "182692936/109050292/genshin_character_batch_compute.json"
        )
    }

    /// 场景：特殊映射路径带 role_id。
    /// 期望：候选使用特殊表里的文件名，而不是通用规则。
    func testResolveSpecialFileKeepsSpecialName() {
        let resolution = FixtureResolver.resolve(
            FixtureQuery(
                path: "/game_record/app/genshin/api/character/detail?role_id=109050292",
                cookie: "account_id=182692936"
            )
        )
        XCTAssertEqual(resolution.fileName, "game_record_app_genshin_api_character_detail_all.json")
    }
}
