import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { MihoyoApiService } from '../MihoyoApiService';
import { RequestParams, RequestOptions } from '../APIs';

export abstract class MockServiceBase extends MihoyoApiService {
  protected static readonly MOCK_DELAY_MS: number = 300;
  protected readonly context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    super();
    this.context = context;
  }

  /** 模拟网络延迟（静态版，供非 MockServiceBase 子类使用） */
  static async delayStatic(): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, MockServiceBase.MOCK_DELAY_MS));
  }

  /**
   * 读取 mock 文件（静态版，供非 MockServiceBase 子类使用）
   */
  static async readMockFileStatic(
    path: string,
    cookie: string,
    context: common.UIAbilityContext,
    roleId?: string,
    avatarId?: string
  ): Promise<object> {
    const accountId = MockServiceBase.extractAccountId(cookie);
    const fileName = avatarId ? `${avatarId}.json` : MockServiceBase.pathToFileName(path);
    const rm = context.resourceManager;
    let fileContent: Uint8Array;

    if (roleId) {
      try {
        fileContent = await rm.getRawFileContent(`mock/${accountId}/${roleId}/${fileName}`);
        return MockServiceBase.parseAndCheck(fileContent);
      } catch (_) {}
    }

    try {
      fileContent = await rm.getRawFileContent(`mock/${accountId}/${fileName}`);
      return MockServiceBase.parseAndCheck(fileContent);
    } catch (_) {}

    const empty = new Object() as Record<string, Object>;
    empty['retcode'] = 0;
    empty['message'] = 'success';
    empty['data'] = new Object();
    return empty;
  }

  /** 模拟网络延迟 */
  protected delay(): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, MockServiceBase.MOCK_DELAY_MS));
  }

  /**
   * 读取 mock 文件并检查 retcode
   * @param path    URL 路径（用于映射文件名）
   * @param cookie  登录 Cookie（用于提取 account_id 路由子目录）
   * @param roleId  游戏角色 UID（用于路由到 {accountId}/{roleId}/ 子目录，账号级接口不传）
   * @param avatarId 绝区零单个角色详情时使用，作为文件名
   */
  protected async readMockFile(path: string, cookie: string, roleId?: string, avatarId?: string): Promise<object> {
    await this.delay();
    const accountId = MockServiceBase.extractAccountId(cookie);
    const fileName = avatarId ? `${avatarId}.json` : MockServiceBase.pathToFileName(path);
    const rm = this.context.resourceManager;
    let fileContent: Uint8Array;

    // 优先：{accountId}/{roleId}/文件名
    if (roleId) {
      try {
        fileContent = await rm.getRawFileContent(`mock/${accountId}/${roleId}/${fileName}`);
        return MockServiceBase.parseAndCheck(fileContent);
      } catch (_) {}
    }

    // 次优：{accountId}/文件名（账号级接口）
    try {
      fileContent = await rm.getRawFileContent(`mock/${accountId}/${fileName}`);
      return MockServiceBase.parseAndCheck(fileContent);
    } catch (_) {}

    // 兜底：空响应
    const empty = new Object() as Record<string, Object>;
    empty['retcode'] = 0;
    empty['message'] = 'success';
    empty['data'] = new Object();
    return empty;
  }

  private static parseAndCheck(fileContent: Uint8Array): object {
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

  /**
   * URL 路径 → 文件名
   * 先去掉 query 参数，再检查特殊映射表，最后走通用规则
   */
  static pathToFileName(path: string): string {
    const cleanPath = path.split('?')[0];

    const specialMap = new Map<string, string>();
    specialMap.set('/event/e20200928calculate/v3/batch_compute', 'genshin_character_batch_compute.json');
    specialMap.set('/event/rpgcalc/compute', 'hkrpg_character_compute.json');
    specialMap.set('/event/nap_cultivate_tool/avatar_calc', 'zzz_character_compute.json');
    specialMap.set('/app/api/signIn', 'apihub_app_api_signIn.json');
    specialMap.set('/game_record/app/genshin/api/character/detail', 'game_record_app_genshin_api_character_detail_all.json');
    specialMap.set('/game_record/app/hkrpg/api/avatar/basic', 'game_record_app_hkrpg_api_avatar_list.json');
    specialMap.set('/game_record/app/hkrpg/api/avatar/info', 'game_record_app_hkrpg_api_avatar_detail_all.json');
    specialMap.set('/event/game_record_zzz/api/zzz/buddy/info', 'event_game_record_zzz_api_zzz_buddy_list.json');

    const special = specialMap.get(cleanPath);
    if (special !== undefined) {
      return special;
    }
    return cleanPath.replace(/^\//, '').replace(/\//g, '_') + '.json';
  }

  /**
   * 从 Cookie 字符串提取 account_id，失败时返回 1
   */
  static extractAccountId(cookie: string): number {
    const match = cookie.match(/account_id=(\d+)/);
    if (match === null || match.length < 2) {
      return 1;
    }
    const group = match[1];
    if (group === undefined) {
      return 1;
    }
    const parsed = parseInt(group);
    return isNaN(parsed) ? 1 : parsed;
  }

  abstract get(path: string, params?: RequestParams, options?: RequestOptions): Promise<object>;
  abstract post(path: string, data?: string | RequestParams, options?: RequestOptions): Promise<object>;
}
