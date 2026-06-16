/**
 * WidgetPayloadParser.ets — Widget Payload 解析器
 *
 * 解析符合 design.md 规范的 payload JSON，提取账号/游戏/角色数据。
 * 用于 Widget 页面从单一 @LocalStorageProp('payload') 解析数据。
 */

import { WIDGET_GAME_ID } from './WidgetUtils';

/**
 * 解析后的角色数据
 */
export class ParsedRole {
  roleId: string = '';
  nickname: string = '';
  server: string = '';
  rawJson: string = '';

  // 当前体力（三游戏通用）
  currentStamina: number = 0;
  maxStamina: number = 160;
  recoverySeconds: number = 0;

  // 游戏类型标记（优先使用父级传入的 gameId，其次从 rawJson 推断）
  private _gameId: string = '';

  /**
   * 设置游戏 ID（由父级 ParsedGame 在解析时设置）
   */
  setGameId(gameId: string): void {
    this._gameId = gameId;
  }

  /**
   * 获取游戏 ID（优先使用父级传入值，其次从 rawJson 推断）
   */
  get gameId(): string {
    // 优先返回父级设置的游戏 ID
    if (this._gameId.length > 0) {
      return this._gameId;
    }
    // 否则从 rawJson 推断
    this.detectGameType();
    return this._gameId;
  }

  /**
   * 判断是否为原神数据
   */
  isGenshin(): boolean {
    return this.gameId === WIDGET_GAME_ID.GENSHIN;
  }

  /**
   * 判断是否为星铁数据
   */
  isStarRail(): boolean {
    return this.gameId === WIDGET_GAME_ID.STARRAIL;
  }

  /**
   * 判断是否为绝区零数据
   */
  isZZZ(): boolean {
    return this.gameId === WIDGET_GAME_ID.ZZZ;
  }

  private detectGameType(): void {
    if (this._gameId.length > 0) {
      return;
    }
    if (this.rawJson.length === 0) {
      return;
    }
    try {
      // rawJson 直接就是 data 对象
      const data: ApiDataJson = JSON.parse(this.rawJson) as ApiDataJson;
      if (data === undefined || data === null) {
        return;
      }
      if (data.current_resin !== undefined) {
        this._gameId = WIDGET_GAME_ID.GENSHIN;
      } else if (data.current_stamina !== undefined) {
        this._gameId = WIDGET_GAME_ID.STARRAIL;
      } else if (data.energy !== undefined) {
        this._gameId = WIDGET_GAME_ID.ZZZ;
      }
    } catch (_e) {
      // 忽略解析错误
    }
  }
}

/**
 * 解析后的游戏数据
 */
export class ParsedGame {
  gameId: string = '';
  roles: ParsedRole[] = [];

  /**
   * 获取第一个角色（用于单角色显示）
   * 注意：Widget Form 不支持 union 类型，返回默认对象而非 null
   */
  get firstRole(): ParsedRole {
    if (this.roles.length > 0) {
      return this.roles[0];
    }
    return new ParsedRole();
  }
}

/**
 * 解析后的账号数据
 */
export class ParsedAccount {
  accountId: string = '';
  accountName: string = '';
  games: ParsedGame[] = [];

  /**
   * 获取所有角色（扁平化）
   */
  getAllRoles(): ParsedRole[] {
    const roles: ParsedRole[] = [];
    for (let i = 0; i < this.games.length; i++) {
      const game = this.games[i];
      for (let j = 0; j < game.roles.length; j++) {
        roles.push(game.roles[j]);
      }
    }
    return roles;
  }
}

/**
 * 解析后的 Payload 数据
 */
export class ParsedPayload {
  version: number = 1;
  updatedAt: number = 0;
  /** 卡片宽度（单位：vp） */
  widgetWidth: number = 0;
  /** 卡片高度（单位：vp） */
  widgetHeight: number = 0;
  accounts: ParsedAccount[] = [];

  /**
   * 获取所有角色（扁平化）
   */
  getAllRoles(): ParsedRole[] {
    const roles: ParsedRole[] = [];
    for (let i = 0; i < this.accounts.length; i++) {
      const accRoles = this.accounts[i].getAllRoles();
      for (let j = 0; j < accRoles.length; j++) {
        roles.push(accRoles[j]);
      }
    }
    return roles;
  }

  /**
   * 获取第一个账号
   * 注意：Widget Form 不支持 union 类型，返回默认对象而非 null
   */
  get firstAccount(): ParsedAccount {
    if (this.accounts.length > 0) {
      return this.accounts[0];
    }
    return new ParsedAccount();
  }

  /**
   * 获取角色总数
   */
  get totalRoles(): number {
    return this.getAllRoles().length;
  }

  /**
   * 获取所有游戏 ID（去重）
   */
  getUniqueGameIds(): string[] {
    const gameIds: string[] = [];
    for (let i = 0; i < this.accounts.length; i++) {
      const account = this.accounts[i];
      for (let j = 0; j < account.games.length; j++) {
        const gameId = account.games[j].gameId;
        // 手动去重
        let found = false;
        for (let k = 0; k < gameIds.length; k++) {
          if (gameIds[k] === gameId) {
            found = true;
            break;
          }
        }
        if (!found) {
          gameIds.push(gameId);
        }
      }
    }
    return gameIds;
  }

  /**
   * 是否为单一游戏
   */
  get isSingleGame(): boolean {
    return this.getUniqueGameIds().length === 1;
  }
}

/**
 * Payload JSON 结构 — 用于类型安全的解析
 */
interface PayloadJson {
  version: number;
  updatedAt: number;
  widgetWidth?: number;
  widgetHeight?: number;
  accounts: AccountJson[];
}

interface AccountJson {
  accountId: string;
  accountName: string;
  games: GameJson[];
}

interface GameJson {
  gameId: string;
  roles: RoleJson[];
}

interface RoleJson {
  roleId: string;
  nickname: string;
  server: string;
  rawJson: string;
}

/**
 * API data 对象 JSON 结构（rawJson 存储的就是这个格式）
 */
interface ApiDataJson {
  current_resin?: number;
  max_resin?: number;
  resin_recovery_time?: string;
  current_stamina?: number;
  max_stamina?: number;
  stamina_recover_time?: number;
  energy?: EnergyJson;
}

interface EnergyJson {
  progress?: ProgressJson;
  restore?: number;
}

interface ProgressJson {
  current?: number;
  max?: number;
}

/**
 * 解析 payload JSON 字符串
 */
export function parsePayload(payloadJson: string): ParsedPayload {
  const result = new ParsedPayload();
  
  if (payloadJson.length === 0) {
    // 空 payload 返回默认值
    return result;
  }

  try {
    const obj: PayloadJson = JSON.parse(payloadJson) as PayloadJson;
    result.version = obj.version !== undefined ? obj.version : 1;
    result.updatedAt = obj.updatedAt !== undefined ? obj.updatedAt : 0;
    result.widgetWidth = obj.widgetWidth !== undefined ? obj.widgetWidth : 0;
    result.widgetHeight = obj.widgetHeight !== undefined ? obj.widgetHeight : 0;

    // 安全检查 accounts 字段
    if (obj.accounts === undefined || obj.accounts === null) {
      return result;
    }

    const accounts: AccountJson[] = obj.accounts;
    if (accounts !== undefined && accounts !== null) {
      for (let i = 0; i < accounts.length; i++) {
        const accObj: AccountJson = accounts[i];
        const parsedAcc = new ParsedAccount();
        parsedAcc.accountId = accObj.accountId !== undefined ? accObj.accountId : '';
        parsedAcc.accountName = accObj.accountName !== undefined ? accObj.accountName : '';

        // 注意：Widget Form 不支持 union 类型，使用显式类型检查
        const games = accObj.games;
        if (games !== undefined && games !== null) {
          for (let j = 0; j < games.length; j++) {
            const gameObj: GameJson = games[j];
            const parsedGame = new ParsedGame();
            parsedGame.gameId = gameObj.gameId !== undefined ? gameObj.gameId : '';

            // 注意：Widget Form 不支持 union 类型
            const roles = gameObj.roles;
            if (roles !== undefined && roles !== null) {
              for (let k = 0; k < roles.length; k++) {
                const roleObj: RoleJson = roles[k];
                const parsedRole = new ParsedRole();
                parsedRole.roleId = roleObj.roleId !== undefined ? roleObj.roleId : '';
                parsedRole.nickname = roleObj.nickname !== undefined ? roleObj.nickname : '';
                parsedRole.server = roleObj.server !== undefined ? roleObj.server : '';
                parsedRole.rawJson = roleObj.rawJson !== undefined ? roleObj.rawJson : '';
                
                // 关键：设置父级的 gameId，确保 gameId 始终正确
                parsedRole.setGameId(parsedGame.gameId);

                // 解析体力数据
                parseStaminaData(parsedRole);

                parsedGame.roles.push(parsedRole);
              }
            }

            parsedAcc.games.push(parsedGame);
          }
        }

        result.accounts.push(parsedAcc);
      }
    }
  } catch (_e) {
    // 解析失败返回默认值
  }

  return result;
}

/**
 * 解析体力数据
 *
 * 注意：rawJson 存储的是 API 响应中的 data 对象（不带 retcode/message 结构）
 * 例如原神：{"current_resin": 140, "max_resin": 200, ...}
 * 
 * 注意：Widget Form 不支持 union 类型，所有变量使用显式类型
 */
function parseStaminaData(role: ParsedRole): void {
  if (role.rawJson.length === 0) {
    return;
  }

  try {
    // rawJson 直接就是 data 对象，不需要从 resp.data 取
    const data: ApiDataJson = JSON.parse(role.rawJson) as ApiDataJson;

    if (data === undefined || data === null) {
      return;
    }

    // 尝试原神格式
    if (data.current_resin !== undefined) {
      role.currentStamina = data.current_resin !== undefined ? data.current_resin : 0;
      role.maxStamina = data.max_resin !== undefined ? data.max_resin : 160;
      const recoveryTime = data.resin_recovery_time;
      role.recoverySeconds = recoveryTime !== undefined ? parseInt(recoveryTime, 10) : 0;
      return;
    }

    // 尝试星铁格式
    if (data.current_stamina !== undefined) {
      role.currentStamina = data.current_stamina !== undefined ? data.current_stamina : 0;
      role.maxStamina = data.max_stamina !== undefined ? data.max_stamina : 240;
      role.recoverySeconds = data.stamina_recover_time !== undefined ? data.stamina_recover_time : 0;
      return;
    }

    // 尝试绝区零格式
    const energy = data.energy;
    if (energy !== undefined && energy !== null) {
      const progress = energy.progress;
      if (progress !== undefined && progress !== null) {
        role.currentStamina = progress.current !== undefined ? progress.current : 0;
        role.maxStamina = progress.max !== undefined ? progress.max : 240;
      }
      role.recoverySeconds = energy.restore !== undefined ? energy.restore : 0;
    }
  } catch (_e) {
    // 解析失败保持默认值
  }
}
