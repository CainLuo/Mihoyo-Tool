/**
 * WidgetRole.ets — Widget 角色数据模型
 *
 * 字段命名与 core 模块 GameRoleRow 保持一致：
 * - roleId: 游戏内 UID
 * - nickname: 游戏内昵称
 * - server: 服务器大区标识
 * - rawJson: API 原始响应 JSON 字符串
 */

/** WidgetRole JSON 结构 */
interface WidgetRoleJson {
  roleId: string;
  nickname: string;
  server: string;
  rawJson: string;
}

/**
 * Widget 角色数据（单个游戏角色）
 */
export class WidgetRole {
  /** 游戏内 UID（对应 core 的 GameRoleRow.roleId） */
  roleId: string = '';
  /** 游戏内昵称 */
  nickname: string = '';
  /** 服务器大区标识（如 cn_gf01、prod_gf_cn） */
  server: string = '';
  /** API 原始响应 JSON 字符串 */
  rawJson: string = '';

  toJson(): WidgetRoleJson {
    const obj: WidgetRoleJson = {
      roleId: this.roleId,
      nickname: this.nickname,
      server: this.server,
      rawJson: this.rawJson,
    };
    return obj;
  }

  static fromJson(obj: Record<string, Object>): WidgetRole {
    const d = new WidgetRole();
    if (obj['roleId'] !== undefined) { d.roleId = obj['roleId'] as string; }
    if (obj['nickname'] !== undefined) { d.nickname = obj['nickname'] as string; }
    if (obj['server'] !== undefined) { d.server = obj['server'] as string; }
    if (obj['rawJson'] !== undefined) { d.rawJson = obj['rawJson'] as string; }
    return d;
  }
}
