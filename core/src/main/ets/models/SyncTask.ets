/**
 * SyncTask.ets
 *
 * 同步任务描述，供 SyncQueueRunner 使用。
 */
export class SyncTask {
  /** 所属账号 ID */
  accountId: string = '';
  /** 游戏角色 UID */
  roleUid: string = '';
  /** 服务器大区标识 */
  server: string = '';
  /** 账号 Cookie */
  cookie: string = '';
  /** 数据类型（对应 SyncDataType 枚举值） */
  dataType: string = '';
  /** 绝区零单个角色详情时使用的代理人 ID */
  avatarId: string = '';
}
