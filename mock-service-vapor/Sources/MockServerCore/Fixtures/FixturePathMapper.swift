import Foundation

/// 把 API 路径映射成 fixtures 目录下的文件名。
///
/// 通用规则（沿用 Node `router.mjs`）：
/// 1. 去掉协议、域名、query；
/// 2. 去掉开头 `/`；
/// 3. 剩下的 `/` 替换成 `_`；
/// 4. 追加 `.json`。
///
/// 少数接口的真实 fixture 名与通用规则不一致，集中在 `specialFiles` 里做精确匹配。
public enum FixturePathMapper {
    /// 特殊映射表：API 路径 → fixture 文件名。
    ///
    /// 每一行都对应仓库里真实存在的 fixture；缺一项就会静默返回空响应，
    /// 所以这张表同时是 Node 版的 parity 契约。
    public static let specialFiles: [String: String] = [
        // 大别野签到
        "/app/api/signIn": "apihub_app_api_signIn.json",
        // 原神角色详情：真实接口一次返回全部角色
        "/game_record/app/genshin/api/character/detail": "game_record_app_genshin_api_character_detail_all.json",
        // 星穹铁道角色列表 / 详情：真实接口命名与路径不同
        "/game_record/app/hkrpg/api/avatar/basic": "game_record_app_hkrpg_api_avatar_list.json",
        "/game_record/app/hkrpg/api/avatar/info": "game_record_app_hkrpg_api_avatar_detail_all.json",
        // 绝区零角色详情
        "/event/game_record_zzz/api/zzz/buddy/info": "event_game_record_zzz_api_zzz_buddy_list.json",
        // Widget 与普通便笺共用同一份数据
        "/game_record/app/genshin/aapi/widget/v2": "game_record_app_genshin_api_dailyNote.json",
        "/game_record/app/hkrpg/aapi/widget": "game_record_app_hkrpg_api_note.json",
        "/event/game_record_zzz/api/zzz/widget": "event_record_app_zzz_widget.json",
        // 养成计算：没有 avatarId 时用整包 fixture
        "/event/e20200928calculate/v3/batch_compute": "genshin_character_batch_compute.json",
        "/event/rpgcalc/compute": "hkrpg_character_compute.json",
        "/event/nap_cultivate_tool/avatar_calc": "zzz_character_compute.json",
    ]

    /// 去掉协议 + 域名，只保留 path + query。
    ///
    /// - `https://api-takumi-record.mihoyo.com/game_record/x` → `/game_record/x`
    /// - `https://host`（没有路径）→ `/`
    /// - 本身已是相对路径时原样返回。
    public static func normalizePath(_ url: String) -> String {
        let text = String(url)
        guard let schemeRange = text.range(of: "://") else {
            return text
        }
        let afterScheme = text[schemeRange.upperBound...]
        if let slashIndex = afterScheme.firstIndex(of: "/") {
            return String(afterScheme[slashIndex...])
        }
        return "/"
    }

    /// 去掉 query（以及 fragment），只保留路径。
    public static func cleanPath(_ url: String) -> String {
        var text = normalizePath(url)
        if let hashIndex = text.firstIndex(of: "#") {
            text = String(text[text.startIndex..<hashIndex])
        }
        if let queryIndex = text.firstIndex(of: "?") {
            text = String(text[text.startIndex..<queryIndex])
        }
        return text
    }

    /// API 路径 → fixture 文件名。
    ///
    /// 先查特殊表（精确匹配，含大小写），再走通用规则。
    public static func fileName(for url: String) -> String {
        let path = cleanPath(url)
        if let special = specialFiles[path] {
            return special
        }
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return trimmed.replacingOccurrences(of: "/", with: "_") + ".json"
    }

    /// 该路径是否命中特殊映射表。
    public static func isSpecial(_ url: String) -> Bool {
        specialFiles[cleanPath(url)] != nil
    }

    /// 把 API 路径转换成 `{accountId}/{roleId}/{fileName}` 需要的文件名部分。
    ///
    /// 与 `fileName(for:)` 相同，单独暴露是为了让解析层语义更清楚。
    public static func relativeFileName(for url: String) -> String {
        fileName(for: url)
    }
}
