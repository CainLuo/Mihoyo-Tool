/**
 * GameRoleRow.ets
 *
 * 游戏角色数据库行模型，对应 game_role_table 表。
 * 一个账号可绑定多个游戏的多个角色，每行对应一个游戏角色。
 */
import { GameId } from '../constants/GameId';
export class GameRoleRow {
  /** 本地数据库自增 ID */
  id: number = 0;
  /** 所属账号 ID（外键，关联 account_table.id） */
  accountId: string = '';
  /** 游戏 ID */
  gameId: GameId = GameId.GENSHIN;
  /** 游戏业务标识（如 'hk4e_cn'、'hkrpg_cn'、'nap_cn'） */
  gameBiz: string = '';
  /** 游戏类型数字（米游社内部字段） */
  gameType: number = 0;
  /** 游戏内 UID */
  roleId: string = '';
  /** 游戏内昵称 */
  nickname: string = '';
  /** 游戏内等级 */
  level: number = 0;
  /** 服务器大区标识（如 'cn_gf01'、'prod_gf_cn'） */
  server: string = '';
  /** 服务器大区名称（如 '天空岛'、'星穹列车'） */
  regionName: string = '';
  /** 是否为当前选中角色（0=否，1=是） */
  isChosen: number = 0;
  /** 是否公开展示战绩（0=否，1=是） */
  isPublic: number = 0;
  /** 游戏背景图 URL（来自 getGameRecordCard） */
  bgImageUrl: string = '';
  /** 游戏内统计数据 JSON 字符串（来自 getGameRecordCard） */
  statsJson: string = '';
}
