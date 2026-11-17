/**
 * WidgetFreshness.test.ets — 数据新鲜度工具测试
 */

import { describe, it, expect } from '@ohos/hypium';
import { isWidgetDataStale, WIDGET_FRESHNESS_STALE_SECONDS } from '../main/ets/utils/WidgetUtil';

export default function widgetFreshnessTest(): void {
  describe('WidgetFreshness', () => {

    it('updatedAt 为 0（从未拉取）不算陈旧', 0, () => {
      expect(isWidgetDataStale(0, 1000000)).assertFalse();
    });

    it('未超过阈值不算陈旧', 0, () => {
      const now = 1000000;
      expect(isWidgetDataStale(now - 60, now)).assertFalse();
      expect(isWidgetDataStale(now - WIDGET_FRESHNESS_STALE_SECONDS, now)).assertFalse();
    });

    it('超过阈值算陈旧', 0, () => {
      const now = 1000000;
      expect(isWidgetDataStale(now - WIDGET_FRESHNESS_STALE_SECONDS - 1, now)).assertTrue();
      expect(isWidgetDataStale(now - 7200, now)).assertTrue();
    });

    it('陈旧阈值为 1 小时', 0, () => {
      expect(WIDGET_FRESHNESS_STALE_SECONDS).assertEqual(3600);
    });

  });
}
