import test from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  buildFixtureResponse,
  extractAccountId,
  extractRoleId,
  extractZZZAvatarId,
  handleAccount,
  handleSign,
  pathToFileName,
  resolveFixtureCandidates,
} from '../router.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const FIXTURES = path.join(HERE, '..', 'fixtures');
const COOKIE_182 = 'account_id=182692936; ltoken=mock; ltuid=182692936';
const COOKIE_348 = 'account_id=348366494; ltoken=mock; ltuid=348366494';

test('pathToFileName: 通用规则', () => {
  assert.equal(
    pathToFileName('/game_record/app/genshin/api/dailyNote'),
    'game_record_app_genshin_api_dailyNote.json',
  );
  assert.equal(
    pathToFileName('/game_record/app/genshin/api/character/list'),
    'game_record_app_genshin_api_character_list.json',
  );
  assert.equal(
    pathToFileName('https://api-takumi-record.mihoyo.com/game_record/app/hkrpg/api/note'),
    'game_record_app_hkrpg_api_note.json',
  );
  assert.equal(
    pathToFileName('/event/game_record_zzz/api/zzz/avatar/basic'),
    'event_game_record_zzz_api_zzz_avatar_basic.json',
  );
  assert.equal(
    pathToFileName('/binding/api/getUserGameRolesByCookie'),
    'binding_api_getUserGameRolesByCookie.json',
  );
});

test('pathToFileName: 特殊映射', () => {
  assert.equal(
    pathToFileName('/game_record/app/genshin/api/character/detail'),
    'game_record_app_genshin_api_character_detail_all.json',
  );
  assert.equal(
    pathToFileName('/game_record/app/hkrpg/api/avatar/basic'),
    'game_record_app_hkrpg_api_avatar_list.json',
  );
  assert.equal(
    pathToFileName('/game_record/app/hkrpg/api/avatar/info'),
    'game_record_app_hkrpg_api_avatar_detail_all.json',
  );
  assert.equal(
    pathToFileName('/event/game_record_zzz/api/zzz/buddy/info'),
    'event_game_record_zzz_api_zzz_buddy_list.json',
  );
  assert.equal(
    pathToFileName('/event/e20200928calculate/v3/batch_compute'),
    'genshin_character_batch_compute.json',
  );
  assert.equal(
    pathToFileName('/event/rpgcalc/compute'),
    'hkrpg_character_compute.json',
  );
  assert.equal(
    pathToFileName('/event/nap_cultivate_tool/avatar_calc'),
    'zzz_character_compute.json',
  );
  assert.equal(
    pathToFileName('/app/api/signIn'),
    'apihub_app_api_signIn.json',
  );
});

test('pathToFileName: query 与大小写/连字符', () => {
  assert.equal(
    pathToFileName('/game_record/app/hkrpg/api/note?role_id=123&server=prod_gf_cn'),
    'game_record_app_hkrpg_api_note.json',
  );
  assert.equal(
    pathToFileName('/event/rpgcalc/compute?game=hkrpg&uid=123'),
    'hkrpg_character_compute.json',
  );
  assert.equal(pathToFileName('/Game_Record/App'), 'Game_Record_App.json');
  assert.equal(pathToFileName('/api/v3/data'), 'api_v3_data.json');
  assert.equal(pathToFileName('/game-record/api'), 'game-record_api.json');
  assert.equal(pathToFileName('/api?a=1&b=2&c=3'), 'api.json');
});

test('extractAccountId: 常规与边界', () => {
  assert.equal(extractAccountId('account_id=1; ltoken=abc; ltuid=1'), 1);
  assert.equal(extractAccountId('account_id=2; ltoken=xyz; ltuid=2'), 2);
  assert.equal(extractAccountId('account_id=123456789; ltoken=abc'), 123456789);
  assert.equal(extractAccountId('ltoken=abc; ltuid=1'), 1);
  assert.equal(extractAccountId(''), 1);
  assert.equal(extractAccountId('ltoken=abc; account_id=5; ltuid=5'), 5);
  assert.equal(extractAccountId('account_id=0; ltoken=abc'), 0);
  assert.equal(extractAccountId('account_id=1.5; ltoken=abc'), 1);
  assert.equal(extractAccountId('account_id=1; account_id=2; ltoken=abc'), 1);
  assert.equal(extractAccountId('account_id=abc; ltoken=abc'), 1);
  assert.equal(extractAccountId('stuid=99887766; stoken=abc'), 99887766);
  assert.equal(extractAccountId('account_id=42; stuid=99'), 42);
});

test('extractRoleId: query / body / 缺失', () => {
  assert.equal(extractRoleId('/game_record/app/genshin/api/dailyNote?role_id=102731382', ''), '102731382');
  assert.equal(extractRoleId('/binding/api/getUserGameRolesByCookie?uid=182692936', ''), '182692936');
  assert.equal(extractRoleId('/event/nap_cultivate_tool/avatar_calc', '{"uid":"37716744"}'), '37716744');
  assert.equal(extractRoleId('/event/e20200928calculate/v3/batch_compute', '{"role_id":"109050292"}'), '109050292');
  assert.equal(extractRoleId('/game_record/app/genshin/api/dailyNote', ''), '');
});

test('extractZZZAvatarId: id_list[] 取第一个', () => {
  assert.equal(
    extractZZZAvatarId('/event/game_record_zzz/api/zzz/avatar/info?role_id=37716744&id_list[]=1171&id_list[]=1141'),
    '1171',
  );
  assert.equal(extractZZZAvatarId('/event/game_record_zzz/api/zzz/avatar/info?role_id=37716744'), '');
});

test('resolveFixtureCandidates: 账号/角色/计算优先级', () => {
  const daily = resolveFixtureCandidates({
    path: '/game_record/app/genshin/api/dailyNote',
    cookie: COOKIE_182,
    roleId: '102731382',
  });
  assert.deepEqual(daily.candidates, [
    '182692936/102731382/game_record_app_genshin_api_dailyNote.json',
    '182692936/game_record_app_genshin_api_dailyNote.json',
  ]);

  const account = resolveFixtureCandidates({
    path: '/binding/api/getUserGameRolesByCookie',
    cookie: COOKIE_182,
  });
  assert.deepEqual(account.candidates, [
    '182692936/binding_api_getUserGameRolesByCookie.json',
  ]);

  const compute = resolveFixtureCandidates({
    path: '/event/rpgcalc/compute',
    cookie: COOKIE_182,
    roleId: '102731382',
    avatarId: '1001',
  });
  assert.deepEqual(compute.candidates, [
    '182692936/102731382/avatar_compute/1001.json',
    '182692936/avatar_compute/1001.json',
  ]);

  const zzzInfo = resolveFixtureCandidates({
    path: '/event/game_record_zzz/api/zzz/avatar/info?role_id=37716744&id_list[]=1171',
    cookie: COOKIE_182,
  });
  assert.deepEqual(zzzInfo.candidates, [
    '182692936/37716744/1171.json',
    '182692936/1171.json',
  ]);
});

test('buildFixtureResponse: 命中真实 fixture', () => {
  const daily = buildFixtureResponse(FIXTURES, {
    path: '/game_record/app/genshin/api/dailyNote',
    cookie: COOKIE_182,
    roleId: '109050292',
  });
  assert.equal(daily.file, '182692936/109050292/game_record_app_genshin_api_dailyNote.json');
  assert.equal(daily.response.retcode, 0);

  const genshinCompute = buildFixtureResponse(FIXTURES, {
    path: '/event/e20200928calculate/v3/batch_compute',
    cookie: COOKIE_182,
    roleId: '109050292',
  });
  assert.equal(genshinCompute.file, '182692936/109050292/genshin_character_batch_compute.json');
  assert.equal(genshinCompute.response.retcode, 0);

  const starRailCompute = buildFixtureResponse(FIXTURES, {
    path: '/event/rpgcalc/compute',
    cookie: COOKIE_182,
    roleId: '102731382',
    avatarId: '1001',
  });
  assert.equal(starRailCompute.file, '182692936/102731382/avatar_compute/1001.json');
  assert.equal(starRailCompute.response.retcode, 0);

  const zzzInfo = buildFixtureResponse(FIXTURES, {
    path: '/event/game_record_zzz/api/zzz/avatar/info?role_id=37716744&id_list[]=1171',
    cookie: COOKIE_182,
  });
  assert.equal(zzzInfo.file, '182692936/37716744/1171.json');
  assert.equal(zzzInfo.response.retcode, 0);
});

test('buildFixtureResponse: 三游戏与账号路由矩阵', () => {
  const cases = [
    ['GI list', '/game_record/app/genshin/api/character/list', COOKIE_182, '109050292', undefined,
      '182692936/109050292/game_record_app_genshin_api_character_list.json'],
    ['GI detail', '/game_record/app/genshin/api/character/detail', COOKIE_182, '109050292', undefined,
      '182692936/109050292/game_record_app_genshin_api_character_detail_all.json'],
    ['SR note', '/game_record/app/hkrpg/api/note', COOKIE_182, '102731382', undefined,
      '182692936/102731382/game_record_app_hkrpg_api_note.json'],
    ['SR basic', '/game_record/app/hkrpg/api/avatar/basic', COOKIE_182, '102731382', undefined,
      '182692936/102731382/game_record_app_hkrpg_api_avatar_list.json'],
    ['SR info', '/game_record/app/hkrpg/api/avatar/info', COOKIE_182, '102731382', undefined,
      '182692936/102731382/game_record_app_hkrpg_api_avatar_detail_all.json'],
    ['ZZZ note', '/event/game_record_zzz/api/zzz/note', COOKIE_182, '37716744', undefined,
      '182692936/37716744/event_game_record_zzz_api_zzz_note.json'],
    ['ZZZ basic', '/event/game_record_zzz/api/zzz/avatar/basic', COOKIE_182, '37716744', undefined,
      '182692936/37716744/event_game_record_zzz_api_zzz_avatar_basic.json'],
    ['ZZZ buddy', '/event/game_record_zzz/api/zzz/buddy/info', COOKIE_182, '37716744', undefined,
      '182692936/37716744/event_game_record_zzz_api_zzz_buddy_list.json'],
    ['ZZZ widget', '/event/game_record_zzz/api/zzz/widget', COOKIE_182, undefined, undefined,
      '182692936/event_record_app_zzz_widget.json'],
    ['roles 182', '/binding/api/getUserGameRolesByCookie', COOKIE_182, undefined, undefined,
      '182692936/binding_api_getUserGameRolesByCookie.json'],
    ['card 182', '/game_record/app/card/wapi/getGameRecordCard?uid=182692936', COOKIE_182, undefined, undefined,
      '182692936/game_record_app_card_wapi_getGameRecordCard.json'],
    ['full 182', '/user/wapi/getUserFullInfo', COOKIE_182, undefined, undefined,
      '182692936/user_wapi_getUserFullInfo.json'],
    ['GI note 348', '/game_record/app/genshin/api/dailyNote', COOKIE_348, '250375401', undefined,
      '348366494/250375401/game_record_app_genshin_api_dailyNote.json'],
    ['SR note 348', '/game_record/app/hkrpg/api/note', COOKIE_348, '111310091', undefined,
      '348366494/111310091/game_record_app_hkrpg_api_note.json'],
    ['roles 348', '/binding/api/getUserGameRolesByCookie', COOKIE_348, undefined, undefined,
      '348366494/binding_api_getUserGameRolesByCookie.json'],
    ['card 348', '/game_record/app/card/wapi/getGameRecordCard?uid=348366494', COOKIE_348, undefined, undefined,
      '348366494/game_record_app_card_wapi_getGameRecordCard.json'],
    ['full 348', '/user/wapi/getUserFullInfo', COOKIE_348, undefined, undefined,
      '348366494/user_wapi_getUserFullInfo.json'],
  ];

  for (const [name, path, cookie, roleId, avatarId, expected] of cases) {
    const result = buildFixtureResponse(FIXTURES, { path, cookie, roleId, avatarId });
    assert.equal(result.file, expected, name);
    assert.equal(result.response.retcode, 0, name);
  }
});

test('buildFixtureResponse: 缺失与空列表兜底', () => {
  const missing = buildFixtureResponse(FIXTURES, {
    path: '/event/e20200928calculate/v1/sync/avatar/list',
    cookie: COOKIE_182,
    roleId: '102731382',
  });
  assert.equal(missing.file, null);
  assert.deepEqual(missing.response, { retcode: 0, message: 'success', data: {} });

  const emptyList = buildFixtureResponse(FIXTURES, {
    path: '/event/e20200928calculate/v1/sync/avatar/list',
    cookie: COOKIE_182,
    roleId: '102731382',
    fallbackEmptyList: true,
  });
  assert.deepEqual(emptyList.response, { retcode: 0, message: 'OK', data: { list: [] } });
});

test('handleAccount: 手机号 / 验证码 / Token / 二维码', () => {
  assert.equal(handleAccount({ method: 'createLoginCaptcha', mobile: '13800138000' }).retcode, 0);
  assert.equal(handleAccount({ method: 'createLoginCaptcha', mobile: '13800138001' }).retcode, 0);
  assert.equal(handleAccount({ method: 'createLoginCaptcha', mobile: '10000000000' }).retcode, -3101);

  const login = handleAccount({
    method: 'loginByMobileCaptcha',
    mobile: '13800138000',
    captcha: '111111',
  });
  assert.equal(login.retcode, 0);
  assert.equal(login.data.token.token, 'mock_stoken_182692936');
  assert.equal(login.data.user_info.aid, '182692936');
  assert.equal(login.data.user_info.mid, 'mock_mid_182692936');

  assert.equal(handleAccount({
    method: 'loginByMobileCaptcha',
    mobile: '13800138000',
    captcha: '000000',
  }).retcode, -3001);
  assert.equal(handleAccount({
    method: 'loginByMobileCaptcha',
    mobile: '10000000000',
    captcha: '111111',
  }).retcode, -3101);

  assert.equal(
    handleAccount({ method: 'getLTokenBySToken', stoken: 'mock_stoken_348366494' }).data.ltoken,
    'mock_ltoken_348366494',
  );
  const cookieToken = handleAccount({
    method: 'getCookieTokenBySToken',
    stoken: 'mock_stoken_182692936',
  });
  assert.equal(cookieToken.data.uid, '182692936');
  assert.equal(cookieToken.data.cookie_token, 'mock_cookie_token_182692936');

  const qr = handleAccount({ method: 'fetchQRCode' });
  assert.equal(qr.data.ticket, 'mock_ticket_182692936');
  assert.equal(handleAccount({ method: 'queryQRCode' }).data.status, 'init');
  assert.equal(handleAccount({ method: 'refreshCookieToken' }).data.cookie_token, 'mock_cookie_token');
  assert.equal(handleAccount({ method: 'refreshLToken' }).data.ltoken, 'mock_ltoken');
  assert.equal(handleAccount({ method: 'verifyLToken' }).retcode, 0);
  assert.equal(handleAccount({ method: 'unknown' }).retcode, -1);
});

test('handleSign: 无 fixture 时返回空成功响应', () => {
  for (const method of ['signBBS', 'signGame', 'getSignInfo', 'getSignReward']) {
    const response = handleSign(FIXTURES, {
      method,
      cookie: COOKIE_182,
      gameBiz: 'hk4e_cn',
    });
    assert.equal(response.retcode, 0);
    assert.deepEqual(response.data, {});
  }
  assert.equal(handleSign(FIXTURES, { method: 'unknown', cookie: COOKIE_182 }).retcode, -1);
});
