/**
 * GameTabBar — 游戏横向 Tab 选择器
 *
 * 展示当前账号下有角色数据的游戏列表，支持横向滚动切换。
 * 仅在 Characters 页面使用。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { GameTabItem } from '../../models/GameTabItem';

// ── Preview：多游戏 Tab，第一个选中 ──
@Preview
@ComponentV2
export struct GameTabBarPreview {
  build() {
    GameTabBar({
      tabs: [
        new GameTabItem('genshin', '100000001', $r('app.string.game_name_genshin')),
        new GameTabItem('starrail', '200000001', $r('app.string.game_name_starrail')),
        new GameTabItem('zzz', '300000001', $r('app.string.game_name_zzz')),
      ],
      selectedIdx: 0,
      onSelect: (_i: number) => {}
    })
    .backgroundColor(themeManager.current.colorPageBg)
  }
}

@ComponentV2
export struct GameTabBar {
  @Param tabs: GameTabItem[] = [];
  @Param selectedIdx: number = 0;
  @Param onSelect: (idx: number) => void = (_i: number) => {};
  @Local private tm: ThemeManager = themeManager;

  build() {
    Scroll() {
      Row({ space: this.tm.current.value8 }) {
        ForEach(this.tabs, (tab: GameTabItem, idx: number) => {
          Text(tab.gameName)
            .font(idx === this.selectedIdx ? this.tm.current.body16Medium : this.tm.current.body16)
            .fontColor(idx === this.selectedIdx
              ? this.tm.current.colorPrimary
              : this.tm.current.colorTextSecondary)
            .padding({
              left: this.tm.current.value16,
              right: this.tm.current.value16,
              top: this.tm.current.value8,
              bottom: this.tm.current.value8
            })
            .borderRadius(this.tm.current.radius8)
            .backgroundColor(idx === this.selectedIdx
              ? $r('app.color.color_primary_bg')
              : this.tm.current.colorTransparent)
            .onClick(() => { this.onSelect(idx); })
        }, (tab: GameTabItem) => tab.gameId + tab.roleUid)
      }
      .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width(this.tm.current.full)
    .height(this.tm.current.value40)
  }
}
