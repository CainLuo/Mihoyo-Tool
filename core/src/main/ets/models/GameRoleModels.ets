/**
 * GameRoleModels.ets
 *
 * 游戏角色查询相关的数据模型。
 * 对应接口：
 *   GET /binding/api/getUserGameRolesByCookie       — 获取绑定的游戏角色列表
 *   GET /game_record/app/card/wapi/getGameRecordCard — 获取角色详情（含背景图和统计数据）
 */

// ─── getUserGameRolesByCookie ─────────────────────────────────────

/** getUserGameRolesByCookie 响应中的单个游戏角色信息 */
export interface GameRoleApiInfo {
  /** 游戏业务标识（如 'hk4e_cn'、'hkrpg_cn'） */
  game_biz: string;
  /** 服务器大区（如 'cn_gf01'、'prod_gf_cn'） */
  region: string;
  /** 游戏内 UID */
  game_uid: string;
  /** 游戏内昵称 */
  nickname: string;
  /** 游戏内等级 */
  level: number;
  /** 是否为当前选中角色 */
  is_chosen: boolean;
  /** 服务器大区名称（如 '天空岛'） */
  region_name: string;
  /** 是否为官服（非渠道服） */
  is_official: boolean;
}

/** getUserGameRolesByCookie 接口响应 */
export interface GameRolesResponse {
  retcode: number;
  message: string;
  data: GameRolesData;
}

interface GameRolesData {
  list: GameRoleApiInfo[];
}

// ─── getGameRecordCard ────────────────────────────────────────────

/** getGameRecordCard 响应中的游戏统计数据项 */
export interface GameRecordDataItem {
  /** 统计项名称（如 '活跃天数'） */
  name: string;
  /** 统计项类型 */
  type: number;
  /** 统计项值（字符串，如 '365'） */
  value: string;
}

/** getGameRecordCard 响应中的单个游戏角色信息 */
export interface GameRecordCardItem {
  /** 米游社游戏 ID（2=原神，6=星铁，8=绝区零） */
  game_id: number;
  /** 游戏内 UID */
  game_role_id: string;
  /** 游戏内昵称 */
  nickname: string;
  /** 服务器大区 */
  region: string;
  /** 游戏内等级 */
  level: number;
  /** 角色背景图 URL（v2 版本） */
  background_image_v2: string;
  /** 游戏内统计数据列表 */
  data: GameRecordDataItem[];
  /** 游戏名称 */
  game_name: string;
}

/** getGameRecordCard 接口响应 */
export interface GameRecordCardResponse {
  retcode: number;
  message: string;
  data: GameRecordCardData;
}

interface GameRecordCardData {
  list: GameRecordCardItem[];
}

// ─── 业务结果 ─────────────────────────────────────────────────────

/** 游戏角色记录（AuthRepository 返回值，供 entry 层使用） */
export class GameRoleRecord {
  /** 本地数据库 ID（0 表示未持久化） */
  id: number = 0;
  /** 所属账号 ID */
  accountId: number = 0;
  /** 游戏 ID（genshin / starrail / zzz） */
  gameId: string = '';
  /** 游戏内 UID */
  roleId: string = '';
  /** 游戏内昵称 */
  nickname: string = '';
  /** 游戏内等级 */
  level: number = 0;
  /** 服务器大区标识 */
  server: string = '';
  /** 游戏背景图 URL */
  bgImageUrl: string = '';
  /** 游戏内统计数据 JSON 字符串（来自 getGameRecordCard） */
  statsJson: string = '';
}

/** 游戏内统计数据项（从 GameRoleRecord.statsJson 解析而来） */
export class RoleStatItem {
  /** 统计项名称（如 '活跃天数'） */
  name: string = '';
  /** 统计项值（如 '365'） */
  value: string = '';

  constructor(name: string, value: string) {
    this.name = name;
    this.value = value;
  }

  /** 将 statsJson 字符串解析为 RoleStatItem 数组，解析失败返回空数组 */
  static parseAll(statsJson: string): RoleStatItem[] {
    if (!statsJson || statsJson === '') {
      return [];
    }
    try {
      interface RawStat {
        name: string;
        value: string;
      }
      const parsed = JSON.parse(statsJson) as RawStat[];
      const result: RoleStatItem[] = [];
      for (let i = 0; i < parsed.length; i++) {
        result[result.length] = new RoleStatItem(parsed[i].name, parsed[i].value);
      }
      return result;
    } catch (_) {
      return [];
    }
  }
}
