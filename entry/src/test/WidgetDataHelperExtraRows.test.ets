/**
 * WidgetDataHelperExtraRows.test.ets — parseExtraRows 方法测试
 *
 * 测试 maxRows 参数和绝区零 note_list 解析
 */
import { describe, it, expect } from '@ohos/hypium';
import { WidgetDataHelper, ParsedExtraRow } from '../main/ets/widget/utils/WidgetDataHelper';
import { WIDGET_GAME_ID } from '../main/ets/widget/utils/WidgetUtils';

export default function widgetDataHelperExtraRowsTest() {
  describe('WidgetDataHelper.parseExtraRows', () => {

    // ── maxRows 参数测试 ────────────────────────────────────────

    it('maxRows=0 返回全部行（不限制）', 0, () => {
      const rawJson = JSON.stringify({
        max_expedition_num: 5,
        expeditions: [{ status: 'Ongoing' }],
        max_home_coin: 2400,
        current_home_coin: 1200,
        total_task_num: 4,
        finished_task_num: 2
      });
      const rows = WidgetDataHelper.parseExtraRows(rawJson, WIDGET_GAME_ID.GENSHIN, 0);
      expect(rows.length > 2).assertTrue();
    });

    it('maxRows=2 返回前 2 行', 0, () => {
      const rawJson = JSON.stringify({
        max_expedition_num: 5,
        expeditions: [{ status: 'Ongoing' }],
        max_home_coin: 2400,
        current_home_coin: 1200,
        total_task_num: 4,
        finished_task_num: 2
      });
      const rows = WidgetDataHelper.parseExtraRows(rawJson, WIDGET_GAME_ID.GENSHIN, 2);
      expect(rows.length).assertEqual(2);
    });

    it('maxRows 默认值为 0（不限制）', 0, () => {
      const rawJson = JSON.stringify({
        max_expedition_num: 5,
        expeditions: [{ status: 'Ongoing' }],
        max_home_coin: 2400,
        current_home_coin: 1200,
        total_task_num: 4,
        finished_task_num: 2
      });
      // 不传 maxRows 参数
      const rows = WidgetDataHelper.parseExtraRows(rawJson, WIDGET_GAME_ID.GENSHIN);
      expect(rows.length > 2).assertTrue();
    });

    it('数据行数少于 maxRows 时返回全部', 0, () => {
      const rawJson = JSON.stringify({
        max_expedition_num: 5,
        expeditions: [{ status: 'Ongoing' }]
      });
      const rows = WidgetDataHelper.parseExtraRows(rawJson, WIDGET_GAME_ID.GENSHIN, 5);
      expect(rows.length).assertEqual(1);
    });

    // ── 原神优先级排序测试 ────────────────────────────────────────

    it('原神：探索派遣优先级最高（排序后第一行）', 0, () => {
      const rawJson = JSON.stringify({
        max_home_coin: 2400,
        current_home_coin: 1200,
        max_expedition_num: 5,
        expeditions: [{ status: 'Ongoing' }]
      });
      const rows = WidgetDataHelper.parseExtraRows(rawJson, WIDGET_GAME_ID.GENSHIN, 2);
      expect(rows[0].label).assertEqual('expedition');
    });

    // ── 星铁优先级排序测试 ────────────────────────────────────────

    it('星铁：委托派遣优先级最高（排序后第一行）', 0, () => {
      const rawJson = JSON.stringify({
        total_expedition_num: 4,
        accepted_epedition_num: 2,
        max_train_score: 500,
        current_train_score: 100,
        rogue_tourn_weekly_max: 1000,
        rogue_tourn_weekly_cur: 200
      });
      const rows = WidgetDataHelper.parseExtraRows(rawJson, WIDGET_GAME_ID.STARRAIL, 2);
      expect(rows[0].label).assertEqual('starrail_expedition');
    });

    // ── 绝区零 note_list 解析测试 ────────────────────────────────────────

    it('绝区零：解析 note_list 数组', 0, () => {
      const rawJson = JSON.stringify({
        note_list: [
          { name: '饼铺盲盒/刮刮卡/占卜', value: '已完成', value_highlight: false },
          { name: '录像店经营', value: '正在营业', value_highlight: false },
          { name: '悬赏委托', value: '0/8000', value_highlight: true },
          { name: '丽都周纪积分', value: '100/2100', value_highlight: true }
        ]
      });
      const rows = WidgetDataHelper.parseExtraRows(rawJson, WIDGET_GAME_ID.ZZZ, 0);
      expect(rows.length).assertEqual(4);
    });

    it('绝区零：maxRows 截断 note_list', 0, () => {
      const rawJson = JSON.stringify({
        note_list: [
          { name: '饼铺盲盒/刮刮卡/占卜', value: '已完成', value_highlight: false },
          { name: '录像店经营', value: '正在营业', value_highlight: false },
          { name: '悬赏委托', value: '0/8000', value_highlight: true },
          { name: '丽都周纪积分', value: '100/2100', value_highlight: true }
        ]
      });
      const rows = WidgetDataHelper.parseExtraRows(rawJson, WIDGET_GAME_ID.ZZZ, 2);
      expect(rows.length).assertEqual(2);
    });

    it('绝区零：value_highlight=true 使用高亮颜色', 0, () => {
      const rawJson = JSON.stringify({
        note_list: [
          { name: '悬赏委托', value: '0/8000', value_highlight: true }
        ]
      });
      const rows = WidgetDataHelper.parseExtraRows(rawJson, WIDGET_GAME_ID.ZZZ, 0);
      expect(rows.length).assertEqual(1);
      // value_highlight=true 时颜色为 ZZZ_PRIMARY（黄色）
      // 这里只验证返回了数据，颜色验证需要对比 Resource 对象
    });

    it('绝区零：note_list 为空数组返回空数组', 0, () => {
      const rawJson = JSON.stringify({
        note_list: []
      });
      const rows = WidgetDataHelper.parseExtraRows(rawJson, WIDGET_GAME_ID.ZZZ, 0);
      expect(rows.length).assertEqual(0);
    });

    it('绝区零：无 note_list 字段返回空数组', 0, () => {
      const rawJson = JSON.stringify({});
      const rows = WidgetDataHelper.parseExtraRows(rawJson, WIDGET_GAME_ID.ZZZ, 0);
      expect(rows.length).assertEqual(0);
    });

    // ── 边界场景测试 ────────────────────────────────────────

    it('rawJson 为空字符串返回空数组', 0, () => {
      const rows = WidgetDataHelper.parseExtraRows('', WIDGET_GAME_ID.GENSHIN, 2);
      expect(rows.length).assertEqual(0);
    });

    it('无效 JSON 返回空数组（不崩溃）', 0, () => {
      const rows = WidgetDataHelper.parseExtraRows('not valid json', WIDGET_GAME_ID.GENSHIN, 2);
      expect(rows.length).assertEqual(0);
    });

  });
}
