/**
 * GameToolCardHeader — 游戏战绩卡片头部（Logo + 游戏名/服务器/昵称 + 同步时间）
 *
 * 仅在 GameToolCard 中使用。
 */
import { GameId } from 'core';
import { ThemeFonts } from '../../theme/ThemeFonts'
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { GameRoleCardVM } from '../../models/HomeModels';
import { gameIdToName } from '../../utils/GameIdUtil';

@ComponentV2
export struct GameToolCardHeader {
  @Param card: GameRoleCardVM = new GameRoleCardVM(GameId.GENSHIN, '', '', '', '', '', null, '');
  @Local private tm: ThemeManager = themeManager;

  private syncDescResource(key: string): ResourceStr {
    if (key === 'sync_just_now') { return $r('app.string.sync_just_now'); }
    if (key === 'sync_long_ago') { return $r('app.string.sync_long_ago'); }
    if (key.startsWith('sync_minutes_ago:')) {
      const n = parseInt(key.split(':')[1]);
      return $r('app.string.sync_minutes_ago', n);
    }
    if (key.startsWith('sync_hours_ago:')) {
      const n = parseInt(key.split(':')[1]);
      return $r('app.string.sync_hours_ago', n);
    }
    return $r('app.string.sync_not_synced');
  }

  build() {
    Row({ space: this.tm.current.value8 }) {
      Image(this.card.logoResource)
        .width(this.tm.current.value32)
        .height(this.tm.current.value32)
        .borderRadius(this.tm.current.value8)
        .border({ width: this.tm.current.value1, color: this.tm.current.colorDivider })
        .objectFit(ImageFit.Cover)

      Column({ space: this.tm.current.value2 }) {
        Text(gameIdToName(this.card.gameId))
          .font(ThemeFonts.fontMedium17)
          .fontColor(this.tm.current.colorTextPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: this.tm.current.value8 }) {
          Text(this.card.server)
            .font(ThemeFonts.font14)
            .fontColor(this.tm.current.colorTextSecondary)
            .maxLines(1)
            .flexShrink(0)

          Text(this.card.nickname)
            .font(ThemeFonts.font14)
            .fontColor(this.tm.current.colorTextSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(this.syncDescResource(this.card.lastSyncDesc))
        .font(ThemeFonts.font14)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .width(this.tm.current.full)
    .padding({
      left: this.tm.current.value12,
      right: this.tm.current.value12,
      top: this.tm.current.value12,
      bottom: this.tm.current.value8
    })
    .alignItems(VerticalAlign.Center)
  }
}
