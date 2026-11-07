import { describe, it, expect } from '@ohos/hypium';
import { StarRailPropertyType } from 'core';
import { getStarRailPropertyResource } from '../main/ets/utils/StarRailPropertyUtil';

export default function starRailPropertyUtilTest() {
  describe('StarRailPropertyUtil', () => {

    it('生命值百分比与固定值映射到同一资源', 0, () => {
      const flat = getStarRailPropertyResource(StarRailPropertyType.HP_FLAT);
      const pct = getStarRailPropertyResource(StarRailPropertyType.HP_PCT);
      expect(flat !== null).assertTrue();
      expect(pct !== null).assertTrue();
      expect(pct !== flat).assertTrue();
      expect(getStarRailPropertyResource(StarRailPropertyType.HP)?.id)
        .assertEqual(getStarRailPropertyResource(StarRailPropertyType.HP_FLAT)?.id);
    });

    it('攻击百分比与能量恢复的装饰品变体映射一致', 0, () => {
      expect(getStarRailPropertyResource(StarRailPropertyType.ATK_PCT) !== null).assertTrue();
      expect(getStarRailPropertyResource(StarRailPropertyType.ENERGY_REGEN)?.id)
        .assertEqual(getStarRailPropertyResource(StarRailPropertyType.ENERGY_REGEN_ORNAMENT)?.id);
      expect(getStarRailPropertyResource(StarRailPropertyType.DEF_FLAT)?.id)
        .assertEqual(getStarRailPropertyResource(StarRailPropertyType.DEF)?.id);
    });

    it('基础属性与伤害加成返回非 null', 0, () => {
      expect(getStarRailPropertyResource(StarRailPropertyType.SPD) !== null).assertTrue();
      expect(getStarRailPropertyResource(StarRailPropertyType.CRIT_RATE) !== null).assertTrue();
      expect(getStarRailPropertyResource(StarRailPropertyType.CRIT_DMG) !== null).assertTrue();
      expect(getStarRailPropertyResource(StarRailPropertyType.BREAK_DMG) !== null).assertTrue();
      expect(getStarRailPropertyResource(StarRailPropertyType.PHYSICAL_DMG_BONUS) !== null).assertTrue();
      expect(getStarRailPropertyResource(StarRailPropertyType.WIND_DMG_BONUS) !== null).assertTrue();
    });

    it('未知属性类型返回 null', 0, () => {
      expect(getStarRailPropertyResource(9999)).assertNull();
      expect(getStarRailPropertyResource(-1)).assertNull();
    });

  });
}
