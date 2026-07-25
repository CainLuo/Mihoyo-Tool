/**
 * MaterialBagDao.test.ets
 *
 * 测试三个游戏材料背包 DAO 的数据库操作。
 * 需要真实 RDB，必须在设备端运行。
 */

import { describe, it, expect, beforeAll, afterAll } from '@ohos/hypium';
import { GenshinMaterialBagDao, StarRailMaterialBagDao, ZZZMaterialBagDao } from '../../../main/ets/database/MaterialBagDao';
import { MaterialBagRow } from '../../../main/ets/models/MaterialBagRow';
import { RdbManager } from '../../../main/ets/database/RdbManager';
import { AccountDao } from '../../../main/ets/database/BBSDao';
import { AccountRow } from '../../../main/ets/models/AccountRow';
import { GameId } from '../../../main/ets/constants/GameId';
import UIAbility from '@ohos.app.ability.UIAbility';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';

let genshinDao: GenshinMaterialBagDao;
let starrailDao: StarRailMaterialBagDao;
let zzzDao: ZZZMaterialBagDao;
let accountDao: AccountDao;
const TEST_ACCOUNT_ID = 'test_material_bag_account';

export default function materialBagDaoTest() {
  describe('MaterialBagDao', () => {

    beforeAll(async () => {
      // 确保 RDB 已初始化
      const context = getContext(this) as UIAbilityContext;
      await RdbManager.init(context);
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

      await genshinDao.upsertAll(TEST_ACCOUNT_ID, [row1, row2]);

      const result = await genshinDao.findByAccount(TEST_ACCOUNT_ID);
      expect(result.length).assertEqual(2);
    });

    it('genshin_findOne_exists_returnsRow', 0, async () => {
      const row = await genshinDao.findOne(TEST_ACCOUNT_ID, 'mat_001');
      expect(row).not.assertNull();
      if (row !== null) {
        expect(row.materialName).assertEqual('测试材料1');
        expect(row.count).assertEqual(100);
      }
    });

    it('genshin_updateCount_updatesCount', 0, async () => {
      await genshinDao.updateCount(TEST_ACCOUNT_ID, 'mat_001', 200);

      const row = await genshinDao.findOne(TEST_ACCOUNT_ID, 'mat_001');
      expect(row).not.assertNull();
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

      await starrailDao.upsertAll(TEST_ACCOUNT_ID, [row]);

      const result = await starrailDao.findByAccount(TEST_ACCOUNT_ID);
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

      await zzzDao.upsertAll(TEST_ACCOUNT_ID, [row]);

      const result = await zzzDao.findByAccount(TEST_ACCOUNT_ID);
      expect(result.length).assertEqual(1);
    });

    // ── 数据隔离测试 ────────────────────────────────────────────────

    it('dataIsolation_differentGames_notCrossPolluted', 0, async () => {
      // 确认三个游戏的材料是隔离的
      const genshinMaterials = await genshinDao.findByAccount(TEST_ACCOUNT_ID);
      const starrailMaterials = await starrailDao.findByAccount(TEST_ACCOUNT_ID);
      const zzzMaterials = await zzzDao.findByAccount(TEST_ACCOUNT_ID);

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

      expect((await genshinDao.findByAccount(TEST_ACCOUNT_ID)).length).assertEqual(0);
      expect((await starrailDao.findByAccount(TEST_ACCOUNT_ID)).length).assertEqual(0);
      expect((await zzzDao.findByAccount(TEST_ACCOUNT_ID)).length).assertEqual(0);
    });

  });
}
