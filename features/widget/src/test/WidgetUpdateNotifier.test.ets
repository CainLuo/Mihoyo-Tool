import { describe, it, expect } from '@ohos/hypium';
import { WidgetPushResult, WidgetUpdateNotifier } from '../main/ets/model/service/WidgetUpdateNotifier';

export default function widgetUpdateNotifierTest() {
  describe('WidgetUpdateNotifier.classifyPushError', () => {

    it('401 表示卡片已被移除', 0, () => {
      expect(WidgetUpdateNotifier.classifyPushError(401)).assertEqual(WidgetPushResult.WIDGET_REMOVED);
    });

    it('16500050 表示 formId 不存在', 0, () => {
      expect(WidgetUpdateNotifier.classifyPushError(16500050)).assertEqual(WidgetPushResult.WIDGET_REMOVED);
    });

    it('网络 / 权限 / 限流错误只算失败，不清理配置', 0, () => {
      expect(WidgetUpdateNotifier.classifyPushError(1001)).assertEqual(WidgetPushResult.FAILED);
      expect(WidgetUpdateNotifier.classifyPushError(201)).assertEqual(WidgetPushResult.FAILED);
      expect(WidgetUpdateNotifier.classifyPushError(0)).assertEqual(WidgetPushResult.FAILED);
      expect(WidgetUpdateNotifier.classifyPushError(-1)).assertEqual(WidgetPushResult.FAILED);
    });

  });
}
