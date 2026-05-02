/**
 * Widget1x2Genshin.ets — 原神 1×2 迷你卡片
 */

import { Logger } from 'core';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { Widget1x2Content } from '../components/Widget1x2Content';
import { WidgetGameData, WidgetSingleGameData } from '../models/WidgetModels';

let storageGenshin1x2 = new LocalStorage();

@Entry(storageGenshin1x2)
@Component
struct Widget1x2Genshin {
  private tm: ThemeManager = themeManager;

  @LocalStorageProp('accountName') accountName: string = '';
  @LocalStorageProp('accountUid') accountUid: string = '';
  @LocalStorageProp('game0Json') game0Json: string = '';

  private buildData(): WidgetSingleGameData {
    const d = new WidgetSingleGameData();
    d.accountName = this.accountName;
    d.accountUid = this.accountUid;
    d.game = WidgetGameData.fromJson(this.game0Json);
    return d;
  }

  build() {
    Column() {
      Widget1x2Content({
        data: this.buildData(),
        gameColor: $r('app.color.game_color_genshin')
      })
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .padding(this.tm.current.value12)
    .backgroundColor(this.tm.current.widgetCardBg)
    .borderRadius(this.tm.current.radius16)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { page: 'GenshinDailyDetail' }
      });
    })
  }
}

@Preview
@Component
struct Widget1x2GenshinPreview {
  build() {
    Column({ space: 12 }) {
      Widget1x2Genshin()
        .width(168)
        .height(80)
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
