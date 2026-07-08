/**
 * GameToolCard — 游戏战绩工具卡片（首页）
 *
 * 卡片头部 + 分割线 + 游戏专属内容区（原神/星铁/绝区零/通用）。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { ThemeFonts } from '../../theme/ThemeFonts'
import { GameRoleCardVM } from '../../models/HomeModels';
import { GameId } from 'core';
import { GameToolCardContent } from './GameToolCardContent';
import { GameToolCardHeader } from './GameToolCardHeader';

@ComponentV2
export struct GameToolCard {
  @Param card: GameRoleCardVM = new GameRoleCardVM(GameId.GENSHIN, '', '', '', '', '', null, '');
  @Param onTap: (card: GameRoleCardVM) => void = (_c: GameRoleCardVM) => {};
  @Local private tm: ThemeManager = themeManager;

  private progressRatio(): number {
    const snap = this.card.snapshot;
    if (snap === null || snap.primaryMax === 0) { return 0; }
    return Math.min(snap.primaryCurrent / snap.primaryMax, 1);
  }

  build() {
    Column() {
      GameToolCardHeader({ card: this.card })

      Divider()
        .color(this.tm.current.colorDivider)
        .margin({ left: this.tm.current.value12, right: this.tm.current.value12 })

      // 内容区
      if (this.card.snapshot !== null) {
        GameToolCardContent({
          snap: this.card.snapshot,
          primaryColor: this.card.snapshot.primaryColor,
          progressRatio: this.progressRatio()
        })
      } else {
        Row() {
          Text($r('app.string.home_no_data_hint'))
            .font(ThemeFonts.font14)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .width(this.tm.current.full)
        .justifyContent(FlexAlign.Center)
        .padding({ top: this.tm.current.font16, bottom: this.tm.current.font16 })
      }
    }
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius16)
    .border({ width: this.tm.current.value1, color: this.tm.current.colorDivider })
    .shadow({
      radius: this.tm.current.shadowRadius,
      color: this.tm.current.shadowColor,
      offsetX: 0,
      offsetY: this.tm.current.shadowOffsetY
    })
    .clip(true)
    .accessibilityText($r('app.string.a11y_game_card', this.card.gameName))
    .onClick(() => { this.onTap(this.card) })
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct GameToolCardPreview {
  @Local private card1: GameRoleCardVM = new GameRoleCardVM(
    GameId.GENSHIN, GameId.GENSHIN, $r('app.color.game_color_genshin'),
    '123456789', '旅行者', '天空岛', null, 'sync_just_now',
    $r('app.media.logo_genshin')
  );
  @Local private card2: GameRoleCardVM = new GameRoleCardVM(
    GameId.STARRAIL, GameId.STARRAIL, $r('app.color.game_color_starrail'),
    '987654321', '开拓者', '星穹列车', null, 'sync_not_synced',
    $r('app.media.logo_starrail')
  );

  build() {
    Column({ space: 12 }) {
      GameToolCard({ card: this.card1 })

      GameToolCard({ card: this.card2 })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
