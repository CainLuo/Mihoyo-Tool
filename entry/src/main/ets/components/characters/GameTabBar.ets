/**
 * GameTabBar — 游戏横向 Tab 选择器
 *
 * 展示当前账号下有角色数据的游戏列表，支持横向滚动切换。
 * 基于 SegmentedTabBar 实现，仅传入游戏特定的数据模型。
 */

import { GameId } from 'core';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { GameTabItem } from '../../models/GameTabItem';
import { SegmentedTabBar, SegmentedTabItem } from '../common/SegmentedTabBar';

// ─── Preview：多游戏 Tab，第一个选中 ──
@Preview
@ComponentV2
export struct GameTabBarPreview {
  build() {
    GameTabBar({
      tabs: [
        new GameTabItem(GameId.GENSHIN, '100000001', $r('app.string.game_name_genshin')),
        new GameTabItem(GameId.STARRAIL, '200000001', $r('app.string.game_name_starrail')),
        new GameTabItem(GameId.ZZZ, '300000001', $r('app.string.game_name_zzz')),
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

  /**
   * 将 GameTabItem 数组转换为 SegmentedTabItem 数组
   */
  private toSegmentedItems(): SegmentedTabItem[] {
    const result: SegmentedTabItem[] = [];
    for (let i = 0; i < this.tabs.length; i++) {
      const tab = this.tabs[i];
      result[result.length] = new SegmentedTabItem(
        tab.gameId + '_' + tab.roleUid,
        tab.gameName
      );
    }
    return result;
  }

  build() {
    SegmentedTabBar({
      tabs: this.toSegmentedItems(),
      selectedIdx: this.selectedIdx,
      onSelect: this.onSelect
    })
  }
}
