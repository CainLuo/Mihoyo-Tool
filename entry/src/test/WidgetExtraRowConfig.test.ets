/**
 * WidgetExtraRowConfig.test.ets — 优先级配置测试
 */
import { describe, it, expect } from '@ohos/hypium';
import { WidgetExtraRowConfig } from '../main/ets/widget/utils/WidgetExtraRowConfig';
import { ExtraRowType } from '../main/ets/widget/utils/WidgetExtraRowType';
import { WIDGET_GAME_ID } from '../main/ets/widget/utils/WidgetUtils';

export default function widgetExtraRowConfigTest() {
  describe('WidgetExtraRowConfig', () => {

    // ── 原神优先级验证 ────────────────────────────────────────

    it('GENSHIN_PRIORITY: 探索派遣优先级最高（1）', 0, () => {
      expect(WidgetExtraRowConfig.GENSHIN_PRIORITY[ExtraRowType.GENSHIN_EXPEDITION]).assertEqual(1);
    });

    it('GENSHIN_PRIORITY: 洞天宝钱优先级为 2', 0, () => {
      expect(WidgetExtraRowConfig.GENSHIN_PRIORITY[ExtraRowType.GENSHIN_HOME_COIN]).assertEqual(2);
    });

    it('GENSHIN_PRIORITY: 每日委托优先级为 3', 0, () => {
      expect(WidgetExtraRowConfig.GENSHIN_PRIORITY[ExtraRowType.GENSHIN_DAILY_TASK]).assertEqual(3);
    });

    it('GENSHIN_PRIORITY: 参量质变仪优先级为 4', 0, () => {
      expect(WidgetExtraRowConfig.GENSHIN_PRIORITY[ExtraRowType.GENSHIN_TRANSFORMER]).assertEqual(4);
    });

    it('GENSHIN_PRIORITY: 周活跃进度优先级为 5', 0, () => {
      expect(WidgetExtraRowConfig.GENSHIN_PRIORITY[ExtraRowType.GENSHIN_WEEK_ACTIVE]).assertEqual(5);
    });

    // ── 星铁优先级验证 ────────────────────────────────────────

    it('STARRAIL_PRIORITY: 委托派遣优先级最高（1）', 0, () => {
      expect(WidgetExtraRowConfig.STARRAIL_PRIORITY[ExtraRowType.STARRAIL_EXPEDITION]).assertEqual(1);
    });

    it('STARRAIL_PRIORITY: 每日实训优先级为 2', 0, () => {
      expect(WidgetExtraRowConfig.STARRAIL_PRIORITY[ExtraRowType.STARRAIL_TRAIN_SCORE]).assertEqual(2);
    });

    it('STARRAIL_PRIORITY: 模拟宇宙积分优先级为 3', 0, () => {
      expect(WidgetExtraRowConfig.STARRAIL_PRIORITY[ExtraRowType.STARRAIL_ROGUE_TOURN]).assertEqual(3);
    });

    // ── getPriority 方法验证 ────────────────────────────────────────

    it('getPriority: 原神返回原神优先级配置', 0, () => {
      const priority = WidgetExtraRowConfig.getPriority(WIDGET_GAME_ID.GENSHIN);
      expect(priority[ExtraRowType.GENSHIN_EXPEDITION]).assertEqual(1);
    });

    it('getPriority: 星铁返回星铁优先级配置', 0, () => {
      const priority = WidgetExtraRowConfig.getPriority(WIDGET_GAME_ID.STARRAIL);
      expect(priority[ExtraRowType.STARRAIL_EXPEDITION]).assertEqual(1);
    });

    it('getPriority: 绝区零返回空对象（不排序）', 0, () => {
      const priority = WidgetExtraRowConfig.getPriority(WIDGET_GAME_ID.ZZZ);
      // 空对象没有 expedition 键
      expect(priority['expedition'] === undefined).assertTrue();
    });

  });
}
