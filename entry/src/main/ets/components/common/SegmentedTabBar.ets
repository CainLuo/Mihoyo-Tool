/**
 * SegmentedTabBar — 通用分段 Tab 选择器
 *
 * 用于需要横向切换的场景（如游戏选择、视图模式切换等）。
 * 显示内容由调用方 VM 构建，传入 TabItem 数组。
 *
 * 使用场景：
 * - Characters 页面的游戏选择
 * - MaterialList 页面的视图模式切换
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { ThemeFonts } from '../../theme/ThemeFonts';

/** Tab 项数据模型 */
export class SegmentedTabItem {
  /** 唯一标识 */
  key: string = '';
  /** 显示文本 */
  label: ResourceStr = '';

  constructor(key: string, label: ResourceStr) {
    this.key = key;
    this.label = label;
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct SegmentedTabBarPreview {
  @Local private selectedIdx: number = 0;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.font20 }) {
      // 示例 1：游戏选择
      SegmentedTabBar({
        tabs: [
          new SegmentedTabItem('genshin', $r('app.string.game_name_genshin')),
          new SegmentedTabItem('starrail', $r('app.string.game_name_starrail')),
          new SegmentedTabItem('zzz', $r('app.string.game_name_zzz')),
        ],
        selectedIdx: this.selectedIdx,
        onSelect: (idx: number) => { this.selectedIdx = idx; }
      })

      // 示例 2：视图模式切换
      SegmentedTabBar({
        tabs: [
          new SegmentedTabItem('character', $r('app.string.material_view_by_character')),
          new SegmentedTabItem('material', $r('app.string.material_view_by_material')),
        ],
        selectedIdx: 0,
        onSelect: (_idx: number) => {}
      })
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.font16)
    .backgroundColor(this.tm.current.colorPageBg)
  }
}

// ─── Component ───────────────────────────────────────────────────

@ComponentV2
export struct SegmentedTabBar {
  /** Tab 列表 */
  @Param tabs: SegmentedTabItem[] = [];
  /** 当前选中的索引 */
  @Param selectedIdx: number = 0;
  /** 选中回调 */
  @Param onSelect: (idx: number) => void = (_i: number) => {};
  /** 主题管理器 */
  @Local private tm: ThemeManager = themeManager;

  build() {
    Scroll() {
      Row({ space: this.tm.current.value8 }) {
        ForEach(this.tabs, (tab: SegmentedTabItem, idx: number) => {
          Text(tab.label)
            .font(idx === this.selectedIdx ? ThemeFonts.fontMedium17 : ThemeFonts.font17)
            .fontColor(idx === this.selectedIdx
              ? this.tm.current.colorPrimary
              : this.tm.current.colorTextSecondary)
            .padding({
              left: this.tm.current.font16,
              right: this.tm.current.font16,
              top: this.tm.current.value8,
              bottom: this.tm.current.value8
            })
            .borderRadius(this.tm.current.radius8)
            .backgroundColor(idx === this.selectedIdx
              ? $r('app.color.color_primary_bg')
              : Color.Transparent)
            .onClick(() => {
              // 只有点击不同的 Tab 才触发回调
              if (idx !== this.selectedIdx) {
                this.onSelect(idx);
              }
            })
        }, (tab: SegmentedTabItem) => tab.key)
      }
      .padding({ left: this.tm.current.font16, right: this.tm.current.font16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width(this.tm.current.full)
    .height(this.tm.current.value40)
  }
}
