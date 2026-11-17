/**
 * MaterialBagDao.test.ets
 *
 * 测试三个游戏材料背包 DAO 的数据库操作。
 * 需要真实 RDB，必须在设备端运行。
 */

import { describe, it, expect, beforeAll, afterAll } from '@ohos/hypium';
import { common } from '@kit.AbilityKit';
import { GenshinMaterialBagDao } from '../../../main/ets/GenshinKit/db/MaterialBagDao';
import { StarRailMaterialBagDao } from '../../../main/ets/StarRailKit/db/MaterialBagDao';
import { ZZZMaterialBagDao } from '../../../main/ets/ZZZKit/db/MaterialBagDao';
import { MaterialBagRow } from '../../../main/ets/common/material/model/MaterialBagRow';
import { RdbManager } from '../../../main/ets/db/RdbManager';
import { SCHEMA_REGISTRY } from '../../../main/ets/SchemaRegistry';
import { AccountDao } from '../../../main/ets/MihoyoKit/db/BBSDao';
import { AccountRow } from '../../../main/ets/MihoyoKit/model/AccountRow';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

async function getContext(): Promise<common.UIAbilityContext> {
  const delegator = AbilityDelegatorRegistry.getAbilityDelegator();
  const ability = await delegator.getCurrentTopAbility();
  return ability.context as common.UIAbilityContext;
}

let genshinDao: GenshinMaterialBagDao;
let starrailDao: StarRailMaterialBagDao;
let zzzDao: ZZZMaterialBagDao;
let accountDao: AccountDao;
const TEST_ACCOUNT_ID = 'test_material_bag_account';
const TEST_ROLE_UID = 'test_material_bag_role';

export default function materialBagDaoTest() {
  describe('MaterialBagDao', () => {

    beforeAll(async () => {
      // 确保 RDB 已初始化
      await RdbManager.init(await getContext(), SCHEMA_REGISTRY);
      genshinDao = new GenshinMaterialBagDao();
      starrailDao = new StarRailMaterialBagDao();
      zzzDao = new ZZZMaterialBagDao();
      accountDao = new AccountDao();

      // 创建测试账号
      const account = new AccountRow();
      account.uid = TEST_ACCOUNT_ID;
      account.username = 'test_material_bag';
      account.cookie = 'test_cookie';
      await accountDao.upsert(account);
    });

    afterAll(async () => {
      // 清理测试数据
      await genshinDao.deleteByAccount(TEST_ACCOUNT_ID);
      await starrailDao.deleteByAccount(TEST_ACCOUNT_ID);
      await zzzDao.deleteByAccount(TEST_ACCOUNT_ID);
      await accountDao.deleteById((await accountDao.findByUsername('test_material_bag'))?.id ?? 0);
    });

    // ── 原神材料背包测试 ────────────────────────────────────────────

    it('genshin_upsertAll_writeMaterials_findReturnsData', 0, async () => {
      const row1 = new MaterialBagRow();
      row1.materialId = 'mat_001';
      row1.materialName = '测试材料1';
      row1.materialIcon = 'https://example.com/icon1.png';
      row1.rarity = '5';
      row1.count = 100;
      row1.source = 'api';

      const row2 = new MaterialBagRow();
      row2.materialId = 'mat_002';
      row2.materialName = '测试材料2';
      row2.materialIcon = 'https://example.com/icon2.png';
      row2.rarity = '4';
      row2.count = 50;
      row2.source = 'api';

      await genshinDao.upsertAll(TEST_ACCOUNT_ID, TEST_ROLE_UID, [row1, row2]);

      const result = await genshinDao.findByRole(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result.length).assertEqual(2);
    });

    it('genshin_findOne_exists_returnsRow', 0, async () => {
      const row = await genshinDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'mat_001');
      expect(row !== null).assertTrue();
      if (row !== null) {
        expect(row.materialName).assertEqual('测试材料1');
        expect(row.count).assertEqual(100);
      }
    });

    it('genshin_updateCount_updatesCount', 0, async () => {
      await genshinDao.updateCount(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'mat_001', 200);

      const row = await genshinDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'mat_001');
      expect(row !== null).assertTrue();
      if (row !== null) {
        expect(row.count).assertEqual(200);
      }
    });

    // ── 星铁材料背包测试 ──────────────────────────────────────────────

    it('starrail_upsertAll_writeMaterials_findReturnsData', 0, async () => {
      const row = new MaterialBagRow();
      row.materialId = 'starrail_mat_001';
      row.materialName = '星铁测试材料';
      row.materialIcon = 'https://example.com/icon.png';
      row.rarity = 'S';
      row.count = 30;
      row.source = 'api';

      await starrailDao.upsertAll(TEST_ACCOUNT_ID, TEST_ROLE_UID, [row]);

      const result = await starrailDao.findByRole(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result.length).assertEqual(1);
    });

    // ── 绝区零材料背包测试 ────────────────────────────────────────────

    it('zzz_upsertAll_writeMaterials_findReturnsData', 0, async () => {
      const row = new MaterialBagRow();
      row.materialId = 'zzz_mat_001';
      row.materialName = '绝区零测试材料';
      row.materialIcon = 'https://example.com/icon.png';
      row.rarity = 'A';
      row.count = 20;
      row.source = 'api';

      await zzzDao.upsertAll(TEST_ACCOUNT_ID, TEST_ROLE_UID, [row]);

      const result = await zzzDao.findByRole(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result.length).assertEqual(1);
    });

    // ── 数据隔离测试 ────────────────────────────────────────────────

    it('dataIsolation_differentGames_notCrossPolluted', 0, async () => {
      // 确认三个游戏的材料是隔离的
      const genshinMaterials = await genshinDao.findByRole(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      const starrailMaterials = await starrailDao.findByRole(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      const zzzMaterials = await zzzDao.findByRole(TEST_ACCOUNT_ID, TEST_ROLE_UID);

      // 原神应该有 2 条（测试材料1和2）
      expect(genshinMaterials.length).assertEqual(2);
      // 星铁应该有 1 条
      expect(starrailMaterials.length).assertEqual(1);
      // 绝区零应该有 1 条
      expect(zzzMaterials.length).assertEqual(1);

      // 确认材料 ID 不混淆
      if (genshinMaterials.length > 0) {
        expect(genshinMaterials[0].materialId).assertContain('mat_');
      }
      if (starrailMaterials.length > 0) {
        expect(starrailMaterials[0].materialId).assertContain('starrail_');
      }
      if (zzzMaterials.length > 0) {
        expect(zzzMaterials[0].materialId).assertContain('zzz_');
      }
    });

    // ── 清理测试 ────────────────────────────────────────────────────

    it('deleteByAccount_removesAllData', 0, async () => {
      await genshinDao.deleteByAccount(TEST_ACCOUNT_ID);
      await starrailDao.deleteByAccount(TEST_ACCOUNT_ID);
      await zzzDao.deleteByAccount(TEST_ACCOUNT_ID);

      expect((await genshinDao.findByRole(TEST_ACCOUNT_ID, TEST_ROLE_UID)).length).assertEqual(0);
      expect((await starrailDao.findByRole(TEST_ACCOUNT_ID, TEST_ROLE_UID)).length).assertEqual(0);
      expect((await zzzDao.findByRole(TEST_ACCOUNT_ID, TEST_ROLE_UID)).length).assertEqual(0);
    });

  });
}
