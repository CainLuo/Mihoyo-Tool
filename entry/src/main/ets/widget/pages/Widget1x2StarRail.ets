/**
 * Widget1x2StarRail.ets — 星铁 1×2 迷你卡片
 *
 * v1.1 设计：游戏主题色渐变背景
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { Widget1x2StarRailContent } from '../components/Widget1x2StarRailContent';
import { WidgetGameData, WidgetSingleGameData } from '../models/WidgetModels';

let storageStarRail1x2 = new LocalStorage();

@Entry(storageStarRail1x2)
@Component
struct Widget1x2StarRail {
  private tm: ThemeManager = themeManager;

  @LocalStorageProp('accountName') accountName: string = '';
  @LocalStorageProp('accountUid') accountUid: string = '';
  @LocalStorageProp('game0Json') game0Json: string = '';

  private buildData(): WidgetSingleGameData {
    const d = new WidgetSingleGameData();
    d.accountName = this.accountName;
    d.accountUid = this.accountUid;
    d.game = WidgetGameData.fromJson(this.game0Json);
    // 调试日志：检查 gameId 是否正确解析
    console.info('[Widget1x2StarRail] buildData: gameId=' + d.game.gameId + ' currentStr=' + d.game.currentStr + ' maxStr=' + d.game.maxStr);
    return d;
  }

  build() {
    Column() {
      Widget1x2StarRailContent({
        data: this.buildData(),
        gameColor: $r('app.color.game_color_starrail')
      })
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .padding({
      left: this.tm.current.value12,
      right: this.tm.current.value12
    })
    .linearGradient({ angle: this.tm.current.a135, colors: [['#181828', 0], ['#201830', 0.5], ['#261c40', 1]] })
    .borderRadius(this.tm.current.radius16)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { page: 'StarRailDailyDetail' }
      });
    })
  }
}

@Preview
@Component
struct Widget1x2StarRailPreview {
  build() {
    Column({ space: 12 }) {
      Widget1x2StarRail()
        .width(168)
        .height(80)
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
