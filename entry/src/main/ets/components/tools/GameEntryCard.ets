/**
 * GameEntryCard.ets — 游戏入口卡片组件
 *
 * 显示游戏名称、图标、角色数量和计算状态。
 * 无数据时置灰，点击弹出提示。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { GameEntryVM } from '../../models/ToolsModels';
import { GameId } from 'core';

@ComponentV2
export struct GameEntryCard {
  @Param entry: GameEntryVM = new GameEntryVM();
  @Param onTap: () => void = () => {};

  @Local private tm: ThemeManager = themeManager;

  build() {
    Row({ space: this.tm.current.value12 }) {
      // 游戏图标
      Image(this.entry.gameIcon)
        .width(this.tm.current.value48)
        .height(this.tm.current.value48)
        .borderRadius(this.tm.current.radius12)
        .clip(true)
        .objectFit(ImageFit.Cover)

      // 内容
      Column({ space: this.tm.current.value4 }) {
        // 游戏名称
        Text(this.entry.gameName)
          .fontSize(this.tm.current.fontBold16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.colorTextPrimary)

        // 状态文字
        Text(this.statusText)
          .fontSize(this.tm.current.font12)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 箭头（有数据时显示）
      if (this.entry.hasData) {
        Text('›')
          .fontSize(this.tm.current.font16)
          .fontColor(this.tm.current.colorTextSecondary)
      }
    }
    .width(this.tm.current.full)
    .padding({
      top: this.tm.current.value12,
      bottom: this.tm.current.value12,
      left: this.tm.current.value16,
      right: this.tm.current.value16
    })
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .border({ width: 1, color: this.tm.current.colorDivider })
    .opacity(this.entry.hasData ? 1 : 0.5)
    .onClick(() => {
      if (this.entry.hasData) {
        this.onTap();
      }
    })
  }

  /**
   * 状态文字
   */
  private get statusText(): ResourceStr {
    if (!this.entry.hasData) {
      return $r('app.string.tools_game_no_data');
    }
    if (this.entry.computedCount === 0) {
      return $r('app.string.tools_game_status_not_computed', this.entry.characterCount);
    }
    if (this.entry.computedCount < this.entry.characterCount) {
      return $r('app.string.tools_game_status_partial', this.entry.characterCount, this.entry.computedCount);
    }
    return $r('app.string.tools_game_status_done', this.entry.characterCount);
  }
}

@Preview
@ComponentV2
export struct GameEntryCardPreview {
  @Local entry1: GameEntryVM = new GameEntryVM();
  @Local entry2: GameEntryVM = new GameEntryVM();
  @Local entry3: GameEntryVM = new GameEntryVM();

  aboutToAppear(): void {
    this.entry1.gameId = GameId.GENSHIN;
    this.entry1.gameName = $r('app.string.game_name_genshin_material');
    this.entry1.gameIcon = $r('app.media.logo_genshin');
    this.entry1.gameColor = $r('app.color.blue_400');
    this.entry1.characterCount = 12;
    this.entry1.computedCount = 8;
    this.entry1.hasData = true;

    this.entry2.gameId = GameId.STARRAIL;
    this.entry2.gameName = $r('app.string.game_name_starrail_material');
    this.entry2.gameIcon = $r('app.media.logo_starrail');
    this.entry2.gameColor = $r('app.color.purple');
    this.entry2.characterCount = 15;
    this.entry2.computedCount = 15;
    this.entry2.hasData = true;

    this.entry3.gameId = GameId.ZZZ;
    this.entry3.gameName = $r('app.string.game_name_zzz_material');
    this.entry3.gameIcon = $r('app.media.logo_zzz');
    this.entry3.gameColor = $r('app.color.zzz_amber');
    this.entry3.characterCount = 0;
    this.entry3.computedCount = 0;
    this.entry3.hasData = false;
  }

  build() {
    Column({ space: this.tm.current.value12 }) {
      GameEntryCard({ entry: this.entry1, onTap: () => {} })

      GameEntryCard({ entry: this.entry2, onTap: () => {} })

      GameEntryCard({ entry: this.entry3, onTap: () => {} })
    }
    .width('100%')
    .padding(this.tm.current.value16)
    .backgroundColor($r('app.color.dark_400'))
  }

  @Local private tm: ThemeManager = themeManager;
}
