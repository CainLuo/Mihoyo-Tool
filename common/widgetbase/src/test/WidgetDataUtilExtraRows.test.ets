/**
 * WidgetDataUtilExtraRows.test.ets — parseExtraRows 方法测试
 *
 * 测试 maxRows 参数和绝区零 note_list 解析
 */
import { describe, it, expect } from '@ohos/hypium';
import { WidgetDataHelper, ParsedExtraRow } from '../main/ets/utils/WidgetDataUtil';
import { WidgetGameId } from '../main/ets/utils/WidgetUtil';

/** 原神便笺原始数据（含探索派遣 / 洞天宝钱 / 委托） */
const GENSHIN_RAW: string = '{"max_expedition_num":5,"expeditions":[{"status":"Ongoing"}],' +
  '"max_home_coin":2400,"current_home_coin":1200,"total_task_num":4,"finished_task_num":2}';

/** 原神便笺原始数据（只有探索派遣） */
const GENSHIN_EXPEDITION_ONLY_RAW: string =
  '{"max_expedition_num":5,"expeditions":[{"status":"Ongoing"}]}';

/** 星铁便笺原始数据（含委托派遣 / 实训 / 模拟宇宙） */
const STARRAIL_RAW: string = '{"total_expedition_num":4,"accepted_epedition_num":2,' +
  '"max_train_score":500,"current_train_score":100,' +
  '"rogue_tourn_weekly_max":1000,"rogue_tourn_weekly_cur":200}';

/** 绝区零 Widget API 返回的 note_list */
const ZZZ_NOTE_LIST_RAW: string = '{"note_list":[' +
  '{"name":"饼铺盲盒/刮刮卡/占卜","value":"已完成","value_highlight":false},' +
  '{"name":"录像店经营","value":"正在营业","value_highlight":false},' +
  '{"name":"悬赏委托","value":"0/8000","value_highlight":true},' +
  '{"name":"丽都周纪积分","value":"100/2100","value_highlight":true}]}';

/** 绝区零 note_list（单行高亮） */
const ZZZ_NOTE_LIST_SINGLE_RAW: string = '{"note_list":[' +
  '{"name":"悬赏委托","value":"0/8000","value_highlight":true}]}';

export default function widgetDataHelperExtraRowsTest() {
  describe('WidgetDataHelper.parseExtraRows', () => {

    // ── maxRows 参数测试 ────────────────────────────────────────

    it('maxRows=0 返回全部行（不限制）', 0, () => {
      const rows = WidgetDataHelper.parseExtraRows(GENSHIN_RAW, '', WidgetGameId.GENSHIN, 0);
      expect(rows.length > 2).assertTrue();
    });

    it('maxRows=2 返回前 2 行', 0, () => {
      const rows = WidgetDataHelper.parseExtraRows(GENSHIN_RAW, '', WidgetGameId.GENSHIN, 2);
      expect(rows.length).assertEqual(2);
    });

    it('maxRows 默认值为 0（不限制）', 0, () => {
      // 不传 maxRows 参数
      const rows = WidgetDataHelper.parseExtraRows(GENSHIN_RAW, '', WidgetGameId.GENSHIN);
      expect(rows.length > 2).assertTrue();
    });

    it('缺字段时按默认上限补齐（3 行）', 0, () => {
      // 洞天宝钱 / 每日委托使用默认上限，即使原始数据缺字段也会补齐为 3 行
      const rows = WidgetDataHelper.parseExtraRows(GENSHIN_EXPEDITION_ONLY_RAW, '', WidgetGameId.GENSHIN, 5);
      expect(rows.length).assertEqual(3);
    });

    // ── 原神优先级排序测试 ────────────────────────────────────────

    it('原神：探索派遣优先级最高（排序后第一行）', 0, () => {
      const rows = WidgetDataHelper.parseExtraRows(GENSHIN_RAW, '', WidgetGameId.GENSHIN, 2);
      expect(rows[0].label).assertEqual('expedition');
    });

    // ── 星铁优先级排序测试 ────────────────────────────────────────

    it('星铁：委托派遣优先级最高（排序后第一行）', 0, () => {
      const rows = WidgetDataHelper.parseExtraRows(STARRAIL_RAW, '', WidgetGameId.STARRAIL, 2);
      expect(rows[0].label).assertEqual('starrail_expedition');
    });

    // ── 绝区零 note_list 解析测试 ────────────────────────────────────────

    it('绝区零：解析 note_list 数组', 0, () => {
      const rows = WidgetDataHelper.parseExtraRows('', ZZZ_NOTE_LIST_RAW, WidgetGameId.ZZZ, 0);
      expect(rows.length).assertEqual(4);
    });

    it('绝区零：maxRows 截断 note_list', 0, () => {
      const rows = WidgetDataHelper.parseExtraRows('', ZZZ_NOTE_LIST_RAW, WidgetGameId.ZZZ, 2);
      expect(rows.length).assertEqual(2);
    });

    it('绝区零：value_highlight=true 使用高亮颜色', 0, () => {
      const rows = WidgetDataHelper.parseExtraRows('', ZZZ_NOTE_LIST_SINGLE_RAW, WidgetGameId.ZZZ, 0);
      expect(rows.length).assertEqual(1);
      // value_highlight=true 时颜色为 ZZZ_PRIMARY（黄色）
      // 这里只验证返回了数据，颜色验证需要对比 Resource 对象
    });

    it('绝区零：note_list 为空数组返回空数组', 0, () => {
      const rows = WidgetDataHelper.parseExtraRows('', '{"note_list":[]}', WidgetGameId.ZZZ, 0);
      expect(rows.length).assertEqual(0);
    });

    it('绝区零：无 note_list 字段返回空数组', 0, () => {
      const rows = WidgetDataHelper.parseExtraRows('', '{}', WidgetGameId.ZZZ, 0);
      expect(rows.length).assertEqual(0);
    });

    // ── 边界场景测试 ────────────────────────────────────────

    it('rawJson 为空字符串返回空数组', 0, () => {
      const rows = WidgetDataHelper.parseExtraRows('', '', WidgetGameId.GENSHIN, 2);
      expect(rows.length).assertEqual(0);
    });

    it('无效 JSON 返回空数组（不崩溃）', 0, () => {
      const rows = WidgetDataHelper.parseExtraRows('not valid json', '', WidgetGameId.GENSHIN, 2);
      expect(rows.length).assertEqual(0);
    });

  });
}
