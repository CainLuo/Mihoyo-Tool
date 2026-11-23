/**
 * WidgetPreviewPayload.test.ets — 页面级预览 payload 测试
 *
 * 预览器里 payload 解析失败会静默显示空态，这里保证示例数据始终可解析。
 */

import { describe, it, expect } from '@ohos/hypium';
import { parsePayload } from 'widgetbase';
import { buildWidgetPreviewPayload } from '../main/ets/widget/preview/WidgetPreviewPayload';

export default function widgetPreviewPayloadTest(): void {
  describe('WidgetPreviewPayload', () => {

    it('buildWidgetPreviewPayload_parsesSingleGenshinRole', 0, () => {
      const parsed = parsePayload(buildWidgetPreviewPayload());
      expect(parsed.accounts.length).assertEqual(1);
      expect(parsed.totalRoles).assertEqual(1);

      const role = parsed.getAllRoles()[0];
      expect(role.gameId).assertEqual('genshin');
      expect(role.nickname).assertEqual('旅行者');
      expect(role.currentStamina).assertEqual(140);
      expect(role.maxStamina).assertEqual(160);
      expect(role.recoverySeconds).assertEqual(16200);
    });

    it('buildWidgetPreviewPayload_updatedAtUsesOffset', 0, () => {
      const now = Math.floor(Date.now() / 1000);
      const parsed = parsePayload(buildWidgetPreviewPayload(600));
      expect(parsed.updatedAt > now - 700).assertTrue();
      expect(parsed.updatedAt <= now).assertTrue();
    });
  });
}
