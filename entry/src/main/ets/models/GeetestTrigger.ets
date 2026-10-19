/**
 * GeetestTrigger — Geetest 人机验证触发数据
 *
 * 任何接口返回 retcode=1034 / 10035 时，GeetestCenter 构造此对象推入 GeetestSignal，
 * Main.ets 弹出 GeetestDialog；验证通过后 GeetestCenter 用同一 challengePath 提交验证。
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
  /** 失败接口的完整地址（x-rpc-challenge_path）；为空时使用该游戏的便笺接口 */
  challengePath: string = '';
  /** 触发验证的返回码（1034 / 10035），绝区零战绩接口据此选择验证接口 */
  retcode: number = 1034;

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
