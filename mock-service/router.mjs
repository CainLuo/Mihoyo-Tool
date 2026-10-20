/**
 * Mock 路由与响应生成（无第三方依赖，可单测）。
 *
 * 约定：
 *   - fixtures 目录结构：{accountId}/{roleId}/文件名.json
 *   - 账号级接口：{accountId}/文件名.json
 *   - 养成计算：{accountId}/{roleId}/avatar_compute/{avatarId}.json
 *   - 找不到文件返回 retcode=0 的空响应（沿用原 Mock 路由约定）
 */

import fs from 'node:fs';
import path from 'node:path';

export const MOCK_DELAY_MS = 300;

/** URL 路径 → fixture 文件名的特殊映射（沿用原 Mock 路由约定，并补齐计算接口） */
export const SPECIAL_FILES = new Map([
  ['/app/api/signIn', 'apihub_app_api_signIn.json'],
  ['/game_record/app/genshin/api/character/detail', 'game_record_app_genshin_api_character_detail_all.json'],
  ['/game_record/app/hkrpg/api/avatar/basic', 'game_record_app_hkrpg_api_avatar_list.json'],
  ['/game_record/app/hkrpg/api/avatar/info', 'game_record_app_hkrpg_api_avatar_detail_all.json'],
  ['/event/game_record_zzz/api/zzz/buddy/info', 'event_game_record_zzz_api_zzz_buddy_list.json'],
  // Widget API 与普通便笺共用一份数据
  ['/game_record/app/genshin/aapi/widget/v2', 'game_record_app_genshin_api_dailyNote.json'],
  ['/game_record/app/hkrpg/aapi/widget', 'game_record_app_hkrpg_api_note.json'],
  ['/event/game_record_zzz/api/zzz/widget', 'event_record_app_zzz_widget.json'],
  // 养成计算（有 avatarId 时会优先走 avatar_compute/{avatarId}.json）
  ['/event/e20200928calculate/v3/batch_compute', 'genshin_character_batch_compute.json'],
  ['/event/rpgcalc/compute', 'hkrpg_character_compute.json'],
  ['/event/nap_cultivate_tool/avatar_calc', 'zzz_character_compute.json'],
]);

const MOCK_PHONE_182 = '13800138000';
const MOCK_PHONE_348 = '13800138001';
const MOCK_AID_182 = '182692936';
const MOCK_AID_348 = '348366494';
const MOCK_CAPTCHA = '111111';
const MOCK_STOKEN_PREFIX = 'mock_stoken_';

/** 去掉协议 + 域名，只保留 path + query */
export function normalizePath(url) {
  const text = String(url ?? '');
  const schemeIndex = text.indexOf('://');
  if (schemeIndex < 0) {
    return text;
  }
  const slashIndex = text.indexOf('/', schemeIndex + 3);
  return slashIndex >= 0 ? text.substring(slashIndex) : '/';
}

/** 去掉 query，只保留 path */
export function cleanPath(url) {
  const text = normalizePath(url);
  const queryIndex = text.indexOf('?');
  return queryIndex >= 0 ? text.substring(0, queryIndex) : text;
}

/** URL 路径 → fixture 文件名 */
export function pathToFileName(url) {
  const cleaned = cleanPath(url);
  const special = SPECIAL_FILES.get(cleaned);
  if (special !== undefined) {
    return special;
  }
  return cleaned.replace(/^\//, '').replace(/\//g, '_') + '.json';
}

/** 从 Cookie 提取 account_id / stuid，失败返回 1 */
export function extractAccountId(cookie) {
  const text = String(cookie ?? '');
  const match = text.match(/account_id=(\d+)/);
  if (match !== null) {
    return parseInt(match[1], 10);
  }
  const stuidMatch = text.match(/stuid=(\d+)/);
  if (stuidMatch !== null) {
    return parseInt(stuidMatch[1], 10);
  }
  return 1;
}

function queryValue(url, key) {
  const text = normalizePath(url);
  const queryIndex = text.indexOf('?');
  if (queryIndex < 0) {
    return '';
  }
  const params = new URLSearchParams(text.substring(queryIndex + 1));
  return params.get(key) ?? '';
}

/** 从 URL query 或 body 中提取 role_id / uid */
export function extractRoleId(url, body) {
  const fromQuery = queryValue(url, 'role_id') || queryValue(url, 'uid');
  if (fromQuery !== '') {
    return fromQuery;
  }
  if (typeof body === 'string' && body.length > 0) {
    try {
      const parsed = JSON.parse(body);
      if (parsed !== null && typeof parsed === 'object') {
        return String(parsed.role_id ?? parsed.uid ?? '');
      }
    } catch (_) {
      return '';
    }
  }
  if (body !== null && typeof body === 'object') {
    return String(body.role_id ?? body.uid ?? '');
  }
  return '';
}

/** 绝区零角色详情：从 query 的 id_list[] 取第一个 avatarId */
export function extractZZZAvatarId(url) {
  const text = normalizePath(url);
  const queryIndex = text.indexOf('?');
  if (queryIndex < 0) {
    return '';
  }
  const params = new URLSearchParams(text.substring(queryIndex + 1));
  const values = params.getAll('id_list[]');
  return values.length > 0 ? values[0] : '';
}

function isZZZAvatarInfo(pathOnly) {
  return pathOnly.includes('/event/game_record_zzz/api/zzz/avatar/info');
}

/**
 * 生成候选文件（相对 fixtures 根目录），按优先级排列：
 *   {accountId}/{roleId}/{fileName}
 *   {accountId}/{fileName}
 */
export function resolveFixtureCandidates(input) {
  const requestPath = normalizePath(input.path ?? input.url ?? '');
  const pathOnly = cleanPath(requestPath);
  const cookie = input.cookie ?? '';
  const accountId = extractAccountId(cookie);
  const roleId = input.roleId !== undefined && input.roleId !== null && String(input.roleId).length > 0
    ? String(input.roleId)
    : extractRoleId(requestPath, input.body);

  let avatarId = input.avatarId !== undefined && input.avatarId !== null ? String(input.avatarId) : '';
  if (avatarId === '' && isZZZAvatarInfo(pathOnly)) {
    avatarId = extractZZZAvatarId(requestPath);
  }

  let fileName;
  if (avatarId !== '' && (pathOnly.includes('compute') || pathOnly.includes('avatar_calc'))) {
    fileName = `avatar_compute/${avatarId}.json`;
  } else if (avatarId !== '') {
    fileName = `${avatarId}.json`;
  } else {
    fileName = pathToFileName(requestPath);
  }

  const candidates = [];
  if (roleId !== '') {
    candidates.push(`${accountId}/${roleId}/${fileName}`);
  }
  candidates.push(`${accountId}/${fileName}`);
  return { accountId, roleId, avatarId, fileName, candidates };
}

/** 读取并解析 fixture；不存在/解析失败返回 null */
export function loadFixture(fixturesDir, relativePath) {
  const root = path.resolve(fixturesDir);
  const fullPath = path.resolve(root, relativePath);
  if (fullPath !== root && !fullPath.startsWith(root + path.sep)) {
    return null;
  }
  try {
    const text = fs.readFileSync(fullPath, 'utf8');
    return { file: relativePath, json: JSON.parse(text) };
  } catch (_) {
    return null;
  }
}

/** 按候选顺序查找 fixture */
export function findFixture(fixturesDir, candidates) {
  for (const candidate of candidates) {
    const loaded = loadFixture(fixturesDir, candidate);
    if (loaded !== null) {
      return loaded;
    }
  }
  return null;
}

export function okResponse(data) {
  return { retcode: 0, message: 'OK', data };
}

export function errorResponse(retcode, message) {
  return { retcode, message, data: {} };
}

/** 空响应：默认 data={}；fallbackEmptyList=true 时返回 data.list=[]（保持旧 sync 接口的 message='OK'） */
export function emptyResponse(fallbackEmptyList = false) {
  return {
    retcode: 0,
    message: fallbackEmptyList ? 'OK' : 'success',
    data: fallbackEmptyList ? { list: [] } : {},
  };
}

/** fixture 响应（供 HTTP 层记录命中的文件） */
export function buildFixtureResponse(fixturesDir, input) {
  const resolved = resolveFixtureCandidates(input);
  const found = findFixture(fixturesDir, resolved.candidates);
  if (found === null) {
    return {
      response: emptyResponse(input.fallbackEmptyList === true),
      file: null,
      resolved,
    };
  }
  return { response: found.json, file: found.file, resolved };
}

function extractAidFromStoken(stoken) {
  const text = String(stoken ?? '');
  if (text.startsWith(MOCK_STOKEN_PREFIX)) {
    return text.substring(MOCK_STOKEN_PREFIX.length);
  }
  return MOCK_AID_182;
}

/** 账号级硬编码 Mock（手机号 / 二维码 / Token 换取） */
export function handleAccount(input) {
  const method = String(input.method ?? '');
  switch (method) {
    case 'createLoginCaptcha': {
      const mobile = String(input.mobile ?? '');
      if (mobile !== MOCK_PHONE_182 && mobile !== MOCK_PHONE_348) {
        return errorResponse(-3101, '手机号未注册');
      }
      return okResponse({
        sent_new: true,
        countdown: 60,
        action_type: 'login_by_mobile_captcha',
      });
    }
    case 'loginByMobileCaptcha': {
      const mobile = String(input.mobile ?? '');
      let aid = '';
      if (mobile === MOCK_PHONE_182) {
        aid = MOCK_AID_182;
      } else if (mobile === MOCK_PHONE_348) {
        aid = MOCK_AID_348;
      } else {
        return errorResponse(-3101, '手机号未注册');
      }
      if (String(input.captcha ?? '') !== MOCK_CAPTCHA) {
        return errorResponse(-3001, '验证码错误');
      }
      return okResponse({
        token: {
          token_type: 1,
          token: `${MOCK_STOKEN_PREFIX}${aid}`,
        },
        user_info: {
          aid,
          mid: `mock_mid_${aid}`,
          mobile,
        },
      });
    }
    case 'getLTokenBySToken': {
      const aid = extractAidFromStoken(input.stoken);
      return okResponse({ ltoken: `mock_ltoken_${aid}` });
    }
    case 'getCookieTokenBySToken': {
      const aid = extractAidFromStoken(input.stoken);
      return okResponse({ uid: aid, cookie_token: `mock_cookie_token_${aid}` });
    }
    case 'fetchQRCode':
      return okResponse({
        ticket: `mock_ticket_${MOCK_AID_182}`,
        url: `https://user.mihoyo.com/qr_code_in_game.html?ticket=mock_ticket_${MOCK_AID_182}`,
      });
    case 'queryQRCode':
      return okResponse({ status: 'init' });
    case 'refreshCookieToken':
      return okResponse({ cookie_token: 'mock_cookie_token' });
    case 'refreshLToken':
      return okResponse({ ltoken: 'mock_ltoken' });
    case 'verifyLToken':
      return okResponse({});
    default:
      return errorResponse(-1, `unknown account method: ${method}`);
  }
}

function gameBizToSignHost(gameBiz) {
  const text = String(gameBiz ?? '');
  if (text.startsWith('hk4e')) {
    return 'hk4e';
  }
  if (text.startsWith('hkrpg')) {
    return 'hkrpg';
  }
  if (text.startsWith('nap') || text.startsWith('zzz')) {
    return 'zzz';
  }
  const index = text.indexOf('_');
  return index > 0 ? text.substring(0, index) : text;
}

/** 签到接口 Mock（原 SignMockService 的目录约定：account{accountId}/） */
export function handleSign(fixturesDir, input) {
  const method = String(input.method ?? '');
  const cookie = String(input.cookie ?? '');
  const accountId = extractAccountId(cookie);

  let relativePath;
  if (method === 'signBBS') {
    relativePath = `${accountId}/apihub_app_api_signIn.json`;
  } else {
    let suffix = '';
    if (method === 'signGame') {
      suffix = 'sign';
    } else if (method === 'getSignInfo') {
      suffix = 'info';
    } else if (method === 'getSignReward') {
      suffix = 'home';
    } else {
      return errorResponse(-1, `unknown sign method: ${method}`);
    }
    const host = gameBizToSignHost(input.gameBiz);
    relativePath = `account${accountId}/event_luna_${host}_${suffix}.json`;
  }

  const found = loadFixture(fixturesDir, relativePath);
  if (found === null) {
    return emptyResponse(false);
  }
  return found.json;
}

/** 递归统计 fixture 数量（健康检查用） */
export function countFixtures(fixturesDir) {
  let count = 0;
  const stack = [path.resolve(fixturesDir)];
  while (stack.length > 0) {
    const current = stack.pop();
    let entries;
    try {
      entries = fs.readdirSync(current, { withFileTypes: true });
    } catch (_) {
      continue;
    }
    for (const entry of entries) {
      if (entry.isDirectory()) {
        stack.push(path.join(current, entry.name));
      } else if (entry.name.endsWith('.json')) {
        count += 1;
      }
    }
  }
  return count;
}
