import XCTest
@testable import MockServerCore

/// `FixturePathMapper` 的路径映射行为。
///
/// 这一层决定了「API 路径 → fixtures 目录下的文件名」，
/// 任何一条映射错了，线上表现都是静默返回空响应，因此逐条覆盖。
final class FixturePathMapperTests: XCTestCase {

    /// 场景：App 传来带协议和域名的绝对 URL。
    /// 期望：只保留 path + query，域名被丢弃。
    func testNormalizePathRemovesSchemeAndHost() {
        let url = "https://api-takumi-record.mihoyo.com/game_record/app/genshin/api/dailyNote"
        XCTAssertEqual(
            FixturePathMapper.normalizePath(url),
            "/game_record/app/genshin/api/dailyNote"
        )
    }

    /// 场景：绝对 URL 上带 query。
    /// 期望：query 原样保留，因为 role_id 要从里面提取。
    func testNormalizePathKeepsQuery() {
        let url = "https://host.example/a/b?role_id=1&server=cn_gf01"
        XCTAssertEqual(FixturePathMapper.normalizePath(url), "/a/b?role_id=1&server=cn_gf01")
    }

    /// 场景：只有域名没有路径（`https://host`）。
    /// 期望：归一化成根路径 `/`，避免出现空字符串。
    func testNormalizePathBareHostBecomesRoot() {
        XCTAssertEqual(FixturePathMapper.normalizePath("https://api.example.com"), "/")
    }

    /// 场景：传入的本来就是相对路径。
    /// 期望：原样返回，不做任何拼接。
    func testNormalizePathRelativePathUnchanged() {
        XCTAssertEqual(
            FixturePathMapper.normalizePath("/game_record/app/x"),
            "/game_record/app/x"
        )
    }

    /// 场景：使用 http（非 https）协议。
    /// 期望：同样只按 `://` 切分，行为与 https 一致。
    func testNormalizePathHandlesHTTP() {
        XCTAssertEqual(FixturePathMapper.normalizePath("http://h/p/q"), "/p/q")
    }

    /// 场景：路径带 query。
    /// 期望：`cleanPath` 砍掉 `?` 之后的所有内容。
    func testCleanPathRemovesQuery() {
        XCTAssertEqual(
            FixturePathMapper.cleanPath("/game_record/x?role_id=1&server=cn_gf01"),
            "/game_record/x"
        )
    }

    /// 场景：路径带 fragment。
    /// 期望：`cleanPath` 砍掉 `#` 之后的所有内容。
    func testCleanPathRemovesFragment() {
        XCTAssertEqual(FixturePathMapper.cleanPath("/game_record/x#section"), "/game_record/x")
    }

    /// 场景：query 与 fragment 同时出现。
    /// 期望：两者都被去掉，只剩纯路径。
    func testCleanPathRemovesQueryAndFragment() {
        XCTAssertEqual(FixturePathMapper.cleanPath("/a/b?x=1#y"), "/a/b")
    }

    /// 场景：输入就是根路径 `/`。
    /// 期望：保持 `/`，不做空串归一化。
    func testCleanPathRootStaysRoot() {
        XCTAssertEqual(FixturePathMapper.cleanPath("/"), "/")
    }

    /// 场景：完整 URL 带域名与 query。
    /// 期望：先去掉域名再去掉 query，一步到位。
    func testCleanPathFullURL() {
        XCTAssertEqual(
            FixturePathMapper.cleanPath("https://h/game_record/app/genshin/api/dailyNote?role_id=1"),
            "/game_record/app/genshin/api/dailyNote"
        )
    }

    /// 场景：根路径 `/` 走通用规则。
    /// 期望：去掉开头斜杠后为空串，再拼 `.json`，得到 `.json`（沿用 Node 版行为）。
    func testFileNameForRoot() {
        XCTAssertEqual(FixturePathMapper.fileName(for: "/"), ".json")
    }

    /// 场景：单段路径。
    /// 期望：斜杠被去掉并追加 `.json`。
    func testFileNameForSimplePath() {
        XCTAssertEqual(FixturePathMapper.fileName(for: "/health"), "health.json")
    }

    /// 场景：多段路径。
    /// 期望：所有 `/` 替换成 `_`，再追加 `.json`。
    func testFileNameForNestedPath() {
        XCTAssertEqual(
            FixturePathMapper.fileName(for: "/game_record/app/genshin/api/dailyNote"),
            "game_record_app_genshin_api_dailyNote.json"
        )
    }

    /// 场景：同一路径带不同的 query。
    /// 期望：query 不参与文件名，结果与不带 query 时完全相同。
    func testFileNameIgnoresQuery() {
        XCTAssertEqual(
            FixturePathMapper.fileName(for: "/game_record/app/x?role_id=1&server=cn_gf01"),
            "game_record_app_x.json"
        )
    }

    /// 场景：完整 URL。
    /// 期望：域名与协议都被忽略，只按路径生成文件名。
    func testFileNameForFullURL() {
        XCTAssertEqual(
            FixturePathMapper.fileName(for: "https://api.example.com/game_record/app/x"),
            "game_record_app_x.json"
        )
    }

    /// 场景：大别野签到接口。
    /// 期望：命中特殊表，返回 `apihub_app_api_signIn.json` 而不是通用规则的名字。
    func testFileNameSpecialSignIn() {
        XCTAssertEqual(FixturePathMapper.fileName(for: "/app/api/signIn"), "apihub_app_api_signIn.json")
    }

    /// 场景：原神角色详情。
    /// 期望：真实接口一次返回全部角色，因此指向 `_all` 后缀的 fixture。
    func testFileNameSpecialGenshinCharacterDetail() {
        XCTAssertEqual(
            FixturePathMapper.fileName(for: "/game_record/app/genshin/api/character/detail"),
            "game_record_app_genshin_api_character_detail_all.json"
        )
    }

    /// 场景：星穹铁道角色列表。
    /// 期望：真实 fixture 名为 `avatar_list`，特殊表负责纠正。
    func testFileNameSpecialHKRPGList() {
        XCTAssertEqual(
            FixturePathMapper.fileName(for: "/game_record/app/hkrpg/api/avatar/basic"),
            "game_record_app_hkrpg_api_avatar_list.json"
        )
    }

    /// 场景：星穹铁道角色详情。
    /// 期望：指向 `avatar_detail_all.json`。
    func testFileNameSpecialHKRPGDetail() {
        XCTAssertEqual(
            FixturePathMapper.fileName(for: "/game_record/app/hkrpg/api/avatar/info"),
            "game_record_app_hkrpg_api_avatar_detail_all.json"
        )
    }

    /// 场景：绝区零角色详情。
    /// 期望：指向 `buddy_list.json`（真实埋点命名）。
    func testFileNameSpecialZZZBuddy() {
        XCTAssertEqual(
            FixturePathMapper.fileName(for: "/event/game_record_zzz/api/zzz/buddy/info"),
            "event_game_record_zzz_api_zzz_buddy_list.json"
        )
    }

    /// 场景：原神 Widget 与普通便笺共用数据。
    /// 期望：Widget 路径直接复用 `game_record_app_genshin_api_dailyNote.json`。
    func testFileNameSpecialGenshinWidget() {
        XCTAssertEqual(
            FixturePathMapper.fileName(for: "/game_record/app/genshin/aapi/widget/v2"),
            "game_record_app_genshin_api_dailyNote.json"
        )
    }

    /// 场景：星穹铁道 Widget。
    /// 期望：复用 `game_record_app_hkrpg_api_note.json`。
    func testFileNameSpecialHKRPGWidget() {
        XCTAssertEqual(
            FixturePathMapper.fileName(for: "/game_record/app/hkrpg/aapi/widget"),
            "game_record_app_hkrpg_api_note.json"
        )
    }

    /// 场景：绝区零 Widget。
    /// 期望：指向账号级的 `event_record_app_zzz_widget.json`。
    func testFileNameSpecialZZZWidget() {
        XCTAssertEqual(
            FixturePathMapper.fileName(for: "/event/game_record_zzz/api/zzz/widget"),
            "event_record_app_zzz_widget.json"
        )
    }

    /// 场景：原神养成计算（无 avatarId）。
    /// 期望：用整包 fixture `genshin_character_batch_compute.json`。
    func testFileNameSpecialGenshinCompute() {
        XCTAssertEqual(
            FixturePathMapper.fileName(for: "/event/e20200928calculate/v3/batch_compute"),
            "genshin_character_batch_compute.json"
        )
    }

    /// 场景：星穹铁道养成计算。
    /// 期望：`hkrpg_character_compute.json`。
    func testFileNameSpecialHKRPGCompute() {
        XCTAssertEqual(
            FixturePathMapper.fileName(for: "/event/rpgcalc/compute"),
            "hkrpg_character_compute.json"
        )
    }

    /// 场景：绝区零养成计算。
    /// 期望：`zzz_character_compute.json`。
    func testFileNameSpecialZZZCompute() {
        XCTAssertEqual(
            FixturePathMapper.fileName(for: "/event/nap_cultivate_tool/avatar_calc"),
            "zzz_character_compute.json"
        )
    }

    /// 场景：特殊映射表本身。
    /// 期望：固定 11 条；新增或删除都会破坏 Node/Swift 的 parity，因此锁定数量。
    func testSpecialFilesCount() {
        XCTAssertEqual(FixturePathMapper.specialFiles.count, 11)
    }

    /// 场景：带 query 的特殊路径。
    /// 期望：`isSpecial` 只看路径部分，仍判定为特殊路径。
    func testIsSpecial() {
        XCTAssertTrue(FixturePathMapper.isSpecial("/app/api/signIn?x=1"))
        XCTAssertFalse(FixturePathMapper.isSpecial("/game_record/app/genshin/api/dailyNote"))
    }

    /// 场景：大小写不同但语义相同的路径。
    /// 期望：特殊表精确匹配（区分大小写），不做模糊命中。
    func testIsSpecialCaseSensitive() {
        XCTAssertFalse(FixturePathMapper.isSpecial("/App/Api/SignIn"))
        XCTAssertEqual(
            FixturePathMapper.fileName(for: "/App/Api/SignIn"),
            "App_Api_SignIn.json"
        )
    }

    /// 场景：`relativeFileName` 与 `fileName` 的关系。
    /// 期望：两者完全等价，只是为解析层提供更明确的语义名。
    func testRelativeFileNameMatchesFileName() {
        for path in ["/app/api/signIn", "/game_record/app/genshin/api/dailyNote", "/"] {
            XCTAssertEqual(
                FixturePathMapper.relativeFileName(for: path),
                FixturePathMapper.fileName(for: path)
            )
        }
    }
}
