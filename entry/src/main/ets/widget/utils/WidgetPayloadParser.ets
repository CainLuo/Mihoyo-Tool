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

  // 游戏类型标记（从 rawJson 解析得出）
  private _gameType: string = '';

  /**
   * 判断是否为原神数据
   */
  isGenshin(): boolean {
    this.detectGameType();
    return this._gameType === 'genshin';
  }

  /**
   * 判断是否为星铁数据
   */
  isStarRail(): boolean {
    this.detectGameType();
    return this._gameType === 'starrail';
  }

  /**
   * 判断是否为绝区零数据
   */
  isZZZ(): boolean {
    this.detectGameType();
    return this._gameType === 'zzz';
  }

  private detectGameType(): void {
    if (this._gameType.length > 0) {
      return;
    }
    if (this.rawJson.length === 0) {
      return;
    }
    try {
      const resp: ApiResponseJson = JSON.parse(this.rawJson) as ApiResponseJson;
      const data: ApiDataJson = resp.data;
      if (data === undefined || data === null) {
        return;
      }
      if (data.current_resin !== undefined) {
        this._gameType = 'genshin';
      } else if (data.current_stamina !== undefined) {
        this._gameType = 'starrail';
      } else if (data.energy !== undefined) {
        this._gameType = 'zzz';
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
   */
  get firstRole(): ParsedRole | null {
    return this.roles.length > 0 ? this.roles[0] : null;
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
   */
  get firstAccount(): ParsedAccount | null {
    return this.accounts.length > 0 ? this.accounts[0] : null;
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
    const gameIds: Set<string> = new Set();
    for (let i = 0; i < this.accounts.length; i++) {
      const account = this.accounts[i];
      for (let j = 0; j < account.games.length; j++) {
        gameIds.add(account.games[j].gameId);
      }
    }
    return Array.from(gameIds);
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
 * API 响应 JSON 结构
 */
interface ApiResponseJson {
  retcode: number;
  message: string;
  data: ApiDataJson;
}

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
    return result;
  }

  try {
    const obj: PayloadJson = JSON.parse(payloadJson) as PayloadJson;
    result.version = obj.version ?? 1;
    result.updatedAt = obj.updatedAt ?? 0;

    const accounts: AccountJson[] | undefined = obj.accounts;
    if (accounts !== undefined && accounts !== null) {
      for (let i = 0; i < accounts.length; i++) {
        const accObj: AccountJson = accounts[i];
        const parsedAcc = new ParsedAccount();
        parsedAcc.accountId = accObj.accountId ?? '';
        parsedAcc.accountName = accObj.accountName ?? '';

        const games: GameJson[] | undefined = accObj.games;
        if (games !== undefined && games !== null) {
          for (let j = 0; j < games.length; j++) {
            const gameObj: GameJson = games[j];
            const parsedGame = new ParsedGame();
            parsedGame.gameId = gameObj.gameId ?? '';

            const roles: RoleJson[] | undefined = gameObj.roles;
            if (roles !== undefined && roles !== null) {
              for (let k = 0; k < roles.length; k++) {
                const roleObj: RoleJson = roles[k];
                const parsedRole = new ParsedRole();
                parsedRole.roleId = roleObj.roleId ?? '';
                parsedRole.nickname = roleObj.nickname ?? '';
                parsedRole.server = roleObj.server ?? '';
                parsedRole.rawJson = roleObj.rawJson ?? '';

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
 */
function parseStaminaData(role: ParsedRole): void {
  if (role.rawJson.length === 0) {
    return;
  }

  try {
    const resp: ApiResponseJson = JSON.parse(role.rawJson) as ApiResponseJson;
    const data: ApiDataJson = resp.data;

    if (data === undefined || data === null) {
      return;
    }

    // 尝试原神格式
    if (data.current_resin !== undefined) {
      role.currentStamina = data.current_resin ?? 0;
      role.maxStamina = data.max_resin ?? 160;
      const recoveryTime: string | undefined = data.resin_recovery_time;
      role.recoverySeconds = recoveryTime !== undefined ? parseInt(recoveryTime, 10) || 0 : 0;
      return;
    }

    // 尝试星铁格式
    if (data.current_stamina !== undefined) {
      role.currentStamina = data.current_stamina ?? 0;
      role.maxStamina = data.max_stamina ?? 240;
      role.recoverySeconds = data.stamina_recover_time ?? 0;
      return;
    }

    // 尝试绝区零格式
    const energy: EnergyJson | undefined = data.energy;
    if (energy !== undefined && energy !== null) {
      const progress: ProgressJson | undefined = energy.progress;
      if (progress !== undefined && progress !== null) {
        role.currentStamina = progress.current ?? 0;
        role.maxStamina = progress.max ?? 240;
      }
      role.recoverySeconds = energy.restore ?? 0;
    }
  } catch (_e) {
    // 解析失败保持默认值
  }
}
