/**
 * GeetestTrigger — Geetest 人机验证触发数据
 *
 * 当同步接口返回 retcode=10035（需要 Geetest 验证）时，
 * HomeViewModel 将此对象赋值给 @Trace geetestTrigger，
 * View 层监听到变化后弹出 GeetestDialog。
 *
 * 验证完成后，View 层调用 HomeViewModel.onGeetestResult() 传回验证结果，
 * ViewModel 用 cookie + gameId + roleId + server 重新发起同步请求。
 */
import { GeetestCreateResult, GameId } from 'core';

export class GeetestTrigger {
  /** Geetest 创建结果（含 gt、challenge 等验证参数） */
  createResult: GeetestCreateResult;
  /** 触发验证的账号 Cookie */
  cookie: string;
  /** 触发验证的游戏 ID */
  gameId: GameId;
  /** 触发验证的游戏角色 UID */
  roleId: string;
  /** 触发验证的游戏服务器 */
  server: string;
  /** 触发验证的米游社 UID */
  accountId: string;

  constructor(
    createResult: GeetestCreateResult,
    cookie: string,
    gameId: GameId,
    roleId: string,
    server: string,
    accountId: string
  ) {
    this.createResult = createResult;
    this.cookie = cookie;
    this.gameId = gameId;
    this.roleId = roleId;
    this.server = server;
    this.accountId = accountId;
  }
}
