import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { MihoyoApiService } from '../MihoyoApiService';
import { RequestParams, RequestOptions } from '../APIs';
import { ApiLogSystem } from '../../log/ApiLogSystem';
import { LogEventType } from '../../log/ApiLogEntry';

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
    const startTime = Date.now();

    // 记录请求日志
    try {
      ApiLogSystem.getInstance().debug(
        'MockService',
        '[MOCK] ' + path + ' → ' + fileName,
        LogEventType.API_REQUEST,
        JSON.stringify({ path, fileName, accountId, roleId: roleId ?? '' }),
      );
    } catch (_) {}

    if (roleId) {
      try {
        fileContent = await rm.getRawFileContent(`mock/${accountId}/${roleId}/${fileName}`);
        const result = MockServiceBase.parseAndCheck(fileContent);
        const durationMs = Date.now() - startTime;
        try {
          ApiLogSystem.getInstance().debug(
            'MockService',
            '[MOCK] ' + path + ' → 200 (' + durationMs + 'ms)',
            LogEventType.API_RESPONSE,
            JSON.stringify({ statusCode: 200, durationMs, mockFile: `mock/${accountId}/${roleId}/${fileName}` }),
          );
        } catch (_) {}
        return result;
      } catch (_) {}
    }

    try {
      fileContent = await rm.getRawFileContent(`mock/${accountId}/${fileName}`);
      const result = MockServiceBase.parseAndCheck(fileContent);
      const durationMs = Date.now() - startTime;
      try {
        ApiLogSystem.getInstance().debug(
          'MockService',
          '[MOCK] ' + path + ' → 200 (' + durationMs + 'ms)',
          LogEventType.API_RESPONSE,
          JSON.stringify({ statusCode: 200, durationMs, mockFile: `mock/${accountId}/${fileName}` }),
        );
      } catch (_) {}
      return result;
    } catch (_) {}

    // 文件不存在，记录警告
    try {
      ApiLogSystem.getInstance().warning(
        'MockService',
        '[MOCK] File not found: mock/' + accountId + '/' + fileName + ' → returning empty response',
        LogEventType.API_ERROR,
        JSON.stringify({ mockFile: `mock/${accountId}/${fileName}` }),
      );
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

    // 绝区零养成计算使用 avatar_compute/{avatarId}.json 路径
    let fileName: string;
    if (avatarId && path.includes('avatar_calc')) {
      fileName = `avatar_compute/${avatarId}.json`;
    } else {
      fileName = avatarId ? `${avatarId}.json` : MockServiceBase.pathToFileName(path);
    }

    const rm = this.context.resourceManager;
    let fileContent: Uint8Array;
    const startTime = Date.now();

    // 记录请求日志
    try {
      ApiLogSystem.getInstance().debug(
        'MockService',
        '[MOCK] ' + path + ' → ' + fileName,
        LogEventType.API_REQUEST,
        JSON.stringify({ path, fileName, accountId, roleId: roleId ?? '' }),
      );
    } catch (_) {}

    // 优先：{accountId}/{roleId}/文件名
    if (roleId) {
      try {
        fileContent = await rm.getRawFileContent(`mock/${accountId}/${roleId}/${fileName}`);
        const result = MockServiceBase.parseAndCheck(fileContent);
        const durationMs = Date.now() - startTime;
        try {
          ApiLogSystem.getInstance().debug(
            'MockService',
            '[MOCK] ' + path + ' → 200 (' + durationMs + 'ms)',
            LogEventType.API_RESPONSE,
            JSON.stringify({ statusCode: 200, durationMs, mockFile: `mock/${accountId}/${roleId}/${fileName}` }),
          );
        } catch (_) {}
        return result;
      } catch (_) {}
    }

    // 次优：{accountId}/文件名（账号级接口）
    try {
      fileContent = await rm.getRawFileContent(`mock/${accountId}/${fileName}`);
      const result = MockServiceBase.parseAndCheck(fileContent);
      const durationMs = Date.now() - startTime;
      try {
        ApiLogSystem.getInstance().debug(
          'MockService',
          '[MOCK] ' + path + ' → 200 (' + durationMs + 'ms)',
          LogEventType.API_RESPONSE,
          JSON.stringify({ statusCode: 200, durationMs, mockFile: `mock/${accountId}/${fileName}` }),
        );
      } catch (_) {}
      return result;
    } catch (_) {}

    // 兜底：空响应，记录文件不存在警告
    try {
      ApiLogSystem.getInstance().warning(
        'MockService',
        '[MOCK] File not found: mock/' + accountId + '/' + fileName + ' → returning empty response',
        LogEventType.API_ERROR,
        JSON.stringify({ mockFile: `mock/${accountId}/${fileName}` }),
      );
    } catch (_) {}

    const empty = new Object() as Record<string, Object>;
    empty['retcode'] = 0;
    empty['message'] = 'success';
    empty['data'] = new Object();
    return empty;
  }

  public static parseAndCheck(fileContent: Uint8Array): object {
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

    // 特殊映射表
    const specialMap = new Map<string, string>();
    specialMap.set('/event/rpgcalc/compute', 'hkrpg_character_compute.json');
    // 绝区零养成计算使用 avatarId 作为文件名，在 readMockFile 中通过 avatarId 参数传入
    // 此处不需要特殊映射，走通用规则即可
    specialMap.set('/app/api/signIn', 'apihub_app_api_signIn.json');
    specialMap.set('/game_record/app/genshin/api/character/detail', 'game_record_app_genshin_api_character_detail_all.json');
    specialMap.set('/game_record/app/hkrpg/api/avatar/basic', 'game_record_app_hkrpg_api_avatar_list.json');
    specialMap.set('/game_record/app/hkrpg/api/avatar/info', 'game_record_app_hkrpg_api_avatar_detail_all.json');
    specialMap.set('/event/game_record_zzz/api/zzz/buddy/info', 'event_game_record_zzz_api_zzz_buddy_list.json');
    // Widget API 映射到与普通便笺相同的 Mock 文件（Widget 返回字段是便笺的子集）
    specialMap.set('/game_record/app/genshin/aapi/widget/v2', 'game_record_app_genshin_api_dailyNote.json');
    specialMap.set('/game_record/app/hkrpg/aapi/widget', 'game_record_app_hkrpg_api_note.json');
    specialMap.set('/event/game_record_zzz/api/zzz/widget', 'event_record_app_zzz_widget.json');

    const special = specialMap.get(cleanPath);
    if (special !== undefined) {
      return special;
    }
    return cleanPath.replace(/^\//, '').replace(/\//g, '_') + '.json';
  }

  /**
   * 从 Cookie 字符串提取 account_id，失败时返回 1
   * 支持普通 Cookie（account_id=xxx）和 Widget Cookie（stuid=xxx）两种格式
   */
  static extractAccountId(cookie: string): number {
    // 优先从 account_id 提取
    const match = cookie.match(/account_id=(\d+)/);
    if (match !== null && match.length >= 2 && match[1] !== undefined) {
      const parsed = parseInt(match[1]);
      if (!isNaN(parsed)) { return parsed; }
    }
    // Widget Cookie 格式：从 stuid 提取
    const stuidMatch = cookie.match(/stuid=(\d+)/);
    if (stuidMatch !== null && stuidMatch.length >= 2 && stuidMatch[1] !== undefined) {
      const parsed = parseInt(stuidMatch[1]);
      if (!isNaN(parsed)) { return parsed; }
    }
    return 1;
  }

  abstract get(path: string, params?: RequestParams, options?: RequestOptions): Promise<object>;
  abstract post(path: string, data?: string | RequestParams, options?: RequestOptions): Promise<object>;
}
