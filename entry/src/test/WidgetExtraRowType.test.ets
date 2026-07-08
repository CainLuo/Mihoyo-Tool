/**
 * WidgetExtraRowType.test.ets — 额外信息类型枚举测试
 */
import { describe, it, expect } from '@ohos/hypium';
import { ExtraRowType } from '../main/ets/widget/utils/WidgetExtraRowType';

export default function widgetExtraRowTypeTest() {
  describe('ExtraRowType', () => {

    // ── 原神枚举值验证 ────────────────────────────────────────

    it('GENSHIN_EXPEDITION 值正确', 0, () => {
      expect(ExtraRowType.GENSHIN_EXPEDITION).assertEqual('expedition');
    });

    it('GENSHIN_HOME_COIN 值正确', 0, () => {
      expect(ExtraRowType.GENSHIN_HOME_COIN).assertEqual('home_coin');
    });

    it('GENSHIN_DAILY_TASK 值正确', 0, () => {
      expect(ExtraRowType.GENSHIN_DAILY_TASK).assertEqual('daily_task');
    });

    it('GENSHIN_TRANSFORMER 值正确', 0, () => {
      expect(ExtraRowType.GENSHIN_TRANSFORMER).assertEqual('transformer');
    });

    it('GENSHIN_WEEK_ACTIVE 值正确', 0, () => {
      expect(ExtraRowType.GENSHIN_WEEK_ACTIVE).assertEqual('week_active');
    });

    // ── 星铁枚举值验证 ────────────────────────────────────────

    it('STARRAIL_EXPEDITION 值正确', 0, () => {
      expect(ExtraRowType.STARRAIL_EXPEDITION).assertEqual('starrail_expedition');
    });

    it('STARRAIL_TRAIN_SCORE 值正确', 0, () => {
      expect(ExtraRowType.STARRAIL_TRAIN_SCORE).assertEqual('train_score');
    });

    it('STARRAIL_ROGUE_TOURN 值正确', 0, () => {
      expect(ExtraRowType.STARRAIL_ROGUE_TOURN).assertEqual('rogue_tourn');
    });

  });
}
