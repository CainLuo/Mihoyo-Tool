import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { RequestParams, RequestOptions } from '../../APIs';
import { MockServiceBase } from './MockServiceBase';
import { SignApiPath } from '../SignApiPath';

/** 从 gameBiz 提取签到 host */
function gameBizToHost(gameBiz: string): string {
  if (gameBiz.startsWith('hk4e')) {
    return 'hk4e';
  }
  if (gameBiz.startsWith('hkrpg')) {
    return 'hkrpg';
  }
  if (gameBiz.startsWith('nap') || gameBiz.startsWith('zzz')) {
    return 'zzz';
  }
  const idx = gameBiz.indexOf('_');
  return idx > 0 ? gameBiz.substring(0, idx) : gameBiz;
}

export class SignMockService extends MockServiceBase {
  constructor(context: common.UIAbilityContext) {
    super(context);
  }

  async get(path: string, params?: RequestParams, options?: RequestOptions): Promise<object> {
    return this.readMockFile(path, this.extractCookie(options));
  }

  async post(path: string, data?: string | RequestParams, options?: RequestOptions): Promise<object> {
    return this.readMockFile(path, this.extractCookie(options));
  }

  /** 大别野签到 — 读 apihub_app_api_signIn.json（特殊映射表处理） */
  async signBBS(cookie: string, challenge?: string): Promise<object> {
    return this.readMockFile(SignApiPath.SIGN_BBS, cookie);
  }

  /** 游戏每日签到 — 动态映射文件名 event_luna_{host}_sign.json */
  async signGame(
    gameBiz: string,
    roleId: string,
    server: string,
    cookie: string,
    challenge?: string,
  ): Promise<object> {
    const host = gameBizToHost(gameBiz);
    const fileName = `event_luna_${host}_sign.json`;
    return this.readMockFileByName(fileName, cookie);
  }

  /** 获取签到状态 — event_luna_{host}_info.json */
  async getSignInfo(gameBiz: string, roleId: string, server: string, cookie: string): Promise<object> {
    const host = gameBizToHost(gameBiz);
    const fileName = `event_luna_${host}_info.json`;
    return this.readMockFileByName(fileName, cookie);
  }

  /** 获取今日签到奖励 — event_luna_{host}_home.json */
  async getSignReward(gameBiz: string, cookie: string): Promise<object> {
    const host = gameBizToHost(gameBiz);
    const fileName = `event_luna_${host}_home.json`;
    return this.readMockFileByName(fileName, cookie);
  }

  /** 直接按文件名读取（不走 pathToFileName 映射） */
  private async readMockFileByName(fileName: string, cookie: string): Promise<object> {
    await this.delay();
    const accountId = MockServiceBase.extractAccountId(cookie);
    const rm = this.context.resourceManager;
    let fileContent: Uint8Array;
    try {
      fileContent = await rm.getRawFileContent(`mock/account${accountId}/${fileName}`);
    } catch (_) {
      const empty = new Object() as Record<string, Object>;
      empty['retcode'] = 0;
      empty['message'] = 'success';
      empty['data'] = new Object();
      return empty;
    }
    const decoder = new util.TextDecoder('utf-8');
    const jsonStr = decoder.decodeToString(new Uint8Array(fileContent.buffer));
    let raw: Record<string, Object>;
    try {
      raw = JSON.parse(jsonStr) as Record<string, Object>;
    } catch (_) {
      const empty = new Object() as Record<string, Object>;
      empty['retcode'] = 0;
      empty['message'] = 'success';
      empty['data'] = new Object();
      return empty;
    }
    const retcode = raw['retcode'] as number;
    if (retcode !== 0) {
      const message = raw['message'] as string;
      throw new Error(`retcode=${retcode}: ${message}`);
    }
    return raw;
  }

  private extractCookie(options?: RequestOptions): string {
    return options?.extraHeaders.get('Cookie') ?? '';
  }
}
