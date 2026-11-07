/**
 * WidgetPayloadUtil.test.ets — Widget Payload 解析器测试
 */

import { describe, it, expect } from '@ohos/hypium';
import { parsePayload, ParsedPayload, ParsedRole, ParsedAccount, ParsedGame } from '../main/ets/utils/WidgetPayloadUtil';

/**
 * 测试套件：WidgetPayloadParser
 */
export default function widgetPayloadParserTest(): void {
  describe('WidgetPayloadParser', () => {
    
    // ── 正常解析 ────────────────────────────────────────────────────────
    
    it('parsePayload_emptyString_returnsDefault', 0, () => {
      const result = parsePayload('');
      expect(result.version).assertEqual(1);
      expect(result.updatedAt).assertEqual(0);
      expect(result.accounts.length).assertEqual(0);
    });
    
    it('parsePayload_validJson_parsesVersion', 0, () => {
      const json = '{"version":2,"updatedAt":1234567890,"accounts":[]}';
      const result = parsePayload(json);
      expect(result.version).assertEqual(2);
      expect(result.updatedAt).assertEqual(1234567890);
    });
    
    it('parsePayload_singleAccount_parsesAccountData', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"TestAccount","games":[]}]}';
      const result = parsePayload(json);
      expect(result.accounts.length).assertEqual(1);
      expect(result.accounts[0].accountId).assertEqual('acc1');
      expect(result.accounts[0].accountName).assertEqual('TestAccount');
    });
    
    it('parsePayload_singleGame_parsesGameData', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[]}]}]}';
      const result = parsePayload(json);
      expect(result.accounts[0].games.length).assertEqual(1);
      expect(result.accounts[0].games[0].gameId).assertEqual('genshin');
    });
    
    it('parsePayload_singleRole_parsesRoleData', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[{"roleId":"role1","nickname":"旅行者","server":"cn_gf01","rawJson":""}]}]}]}';
      const result = parsePayload(json);
      const role = result.accounts[0].games[0].roles[0];
      expect(role.roleId).assertEqual('role1');
      expect(role.nickname).assertEqual('旅行者');
      expect(role.server).assertEqual('cn_gf01');
    });
    
    // ── 体力数据解析 ──────────────────────────────────────────────────────
    
    it('parsePayload_genshinRawJson_parsesStamina', 0, () => {
      const rawJson = '{"current_resin":140,"max_resin":200,"resin_recovery_time":"3600"}';
      const json = `{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[{"roleId":"role1","nickname":"旅行者","server":"cn_gf01","rawJson":"${rawJson.replace(/"/g, '\\"')}"}]}]}]}`;
      const result = parsePayload(json);
      const role = result.accounts[0].games[0].roles[0];
      expect(role.currentStamina).assertEqual(140);
      expect(role.maxStamina).assertEqual(200);
      expect(role.recoverySeconds).assertEqual(3600);
    });
    
    it('parsePayload_starrailRawJson_parsesStamina', 0, () => {
      const rawJson = '{"current_stamina":180,"max_stamina":240,"stamina_recover_time":7200}';
      const json = `{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"starrail","roles":[{"roleId":"role1","nickname":"开拓者","server":"prod_gf_cn","rawJson":"${rawJson.replace(/"/g, '\\"')}"}]}]}]}`;
      const result = parsePayload(json);
      const role = result.accounts[0].games[0].roles[0];
      expect(role.currentStamina).assertEqual(180);
      expect(role.maxStamina).assertEqual(240);
      expect(role.recoverySeconds).assertEqual(7200);
    });
    
    it('parsePayload_zzzRawJson_parsesStamina', 0, () => {
      const rawJson = '{"energy":{"progress":{"current":120,"max":240},"restore":5400}}';
      const json = `{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"zzz","roles":[{"roleId":"role1","nickname":"代理人","server":"prod_gf_cn","rawJson":"${rawJson.replace(/"/g, '\\"')}"}]}]}]}`;
      const result = parsePayload(json);
      const role = result.accounts[0].games[0].roles[0];
      expect(role.currentStamina).assertEqual(120);
      expect(role.maxStamina).assertEqual(240);
      expect(role.recoverySeconds).assertEqual(5400);
    });
    
    // ── 容错处理 ──────────────────────────────────────────────────────────
    
    it('parsePayload_invalidJson_returnsDefault', 0, () => {
      const result = parsePayload('not valid json');
      expect(result.version).assertEqual(1);
      expect(result.accounts.length).assertEqual(0);
    });
    
    it('parsePayload_emptyObject_returnsDefault', 0, () => {
      const result = parsePayload('{}');
      expect(result.version).assertEqual(1);
      expect(result.accounts.length).assertEqual(0);
    });
    
    it('parsePayload_nullAccounts_returnsDefault', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":null}';
      const result = parsePayload(json);
      expect(result.accounts.length).assertEqual(0);
    });
    
    // ── 辅助方法 ──────────────────────────────────────────────────────────
    
    it('getAllRoles_multipleAccounts_returnsAllRoles', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test1","games":[{"gameId":"genshin","roles":[{"roleId":"role1","nickname":"A","server":"","rawJson":""}]}]},{"accountId":"acc2","accountName":"Test2","games":[{"gameId":"starrail","roles":[{"roleId":"role2","nickname":"B","server":"","rawJson":""}]}]}]}';
      const result = parsePayload(json);
      const allRoles = result.getAllRoles();
      expect(allRoles.length).assertEqual(2);
    });
    
    it('getUniqueGameIds_multipleGames_returnsUniqueIds', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[]},{"gameId":"starrail","roles":[]},{"gameId":"genshin","roles":[]}]}]}';
      const result = parsePayload(json);
      const gameIds = result.getUniqueGameIds();
      expect(gameIds.length).assertEqual(2);
    });
    
    it('isSingleGame_singleGame_returnsTrue', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[]}]}]}';
      const result = parsePayload(json);
      expect(result.isSingleGame).assertTrue();
    });
    
    it('isSingleGame_multipleGames_returnsFalse', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[]},{"gameId":"starrail","roles":[]}]}]}';
      const result = parsePayload(json);
      expect(result.isSingleGame).assertFalse();
    });
    
    it('totalRoles_noRoles_returnsZero', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":[]}';
      const result = parsePayload(json);
      expect(result.totalRoles).assertEqual(0);
    });
    
    it('totalRoles_multipleRoles_returnsCorrectCount', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[{"roleId":"role1","nickname":"A","server":"","rawJson":""},{"roleId":"role2","nickname":"B","server":"","rawJson":""}]}]}]}';
      const result = parsePayload(json);
      expect(result.totalRoles).assertEqual(2);
    });
    
    it('firstAccount_emptyPayload_returnsDefault', 0, () => {
      const result = parsePayload('');
      expect(result.firstAccount.accountId).assertEqual('');
    });
    
    it('firstAccount_hasAccounts_returnsFirst', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[]}]}';
      const result = parsePayload(json);
      expect(result.firstAccount.accountId).assertEqual('acc1');
    });
    
    it('widgetWidth_widgetHeight_parsedCorrectly', 0, () => {
      const json = '{"version":1,"updatedAt":0,"widgetWidth":360,"widgetHeight":380,"accounts":[]}';
      const result = parsePayload(json);
      expect(result.widgetWidth).assertEqual(360);
      expect(result.widgetHeight).assertEqual(380);
    });
    
    // ── gameId 检测 ──────────────────────────────────────────────────────────
    
    it('role_gameId_genshinDetected', 0, () => {
      const rawJson = '{"current_resin":100,"max_resin":160}';
      const json = `{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[{"roleId":"role1","nickname":"","server":"","rawJson":"${rawJson.replace(/"/g, '\\"')}"}]}]}]}`;
      const result = parsePayload(json);
      const role = result.accounts[0].games[0].roles[0];
      expect(role.isGenshin()).assertTrue();
      expect(role.isStarRail()).assertFalse();
      expect(role.isZZZ()).assertFalse();
    });
    
    it('role_gameId_starrailDetected', 0, () => {
      const rawJson = '{"current_stamina":100,"max_stamina":240}';
      const json = `{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"starrail","roles":[{"roleId":"role1","nickname":"","server":"","rawJson":"${rawJson.replace(/"/g, '\\"')}"}]}]}]}`;
      const result = parsePayload(json);
      const role = result.accounts[0].games[0].roles[0];
      expect(role.isGenshin()).assertFalse();
      expect(role.isStarRail()).assertTrue();
      expect(role.isZZZ()).assertFalse();
    });
    
    it('role_gameId_zzzDetected', 0, () => {
      const rawJson = '{"energy":{"progress":{"current":100,"max":240}}}';
      const json = `{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"zzz","roles":[{"roleId":"role1","nickname":"","server":"","rawJson":"${rawJson.replace(/"/g, '\\"')}"}]}]}]}`;
      const result = parsePayload(json);
      const role = result.accounts[0].games[0].roles[0];
      expect(role.isGenshin()).assertFalse();
      expect(role.isStarRail()).assertFalse();
      expect(role.isZZZ()).assertTrue();
    });
  });
}
