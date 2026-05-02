/**
 * Widget2x4.ets — 2×4 宽幅卡片入口
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { WidgetCardContent, WidgetCardSize } from '../components/WidgetCardContent';
import { dailyDetailPage } from '../utils/WidgetUtils';

let storage2x4 = new LocalStorage();

@Entry(storage2x4)
@Component
struct Widget2x4 {
  private tm: ThemeManager = themeManager;

  @LocalStorageProp('accountName') accountName: string = '';
  @LocalStorageProp('accountUid') accountUid: string = '';
  @LocalStorageProp('gameCount') gameCountStr: string = '0';
  @LocalStorageProp('game0Id') game0Id: string = '';
  @LocalStorageProp('game0Json') game0Json: string = '';
  @LocalStorageProp('game1Json') game1Json: string = '';
  @LocalStorageProp('game2Json') game2Json: string = '';

  private get gameCount(): number { return parseInt(this.gameCountStr) || 0; }

  build() {
    Column() {
      WidgetCardContent({ cardSize: WidgetCardSize.SIZE_2x4 })
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .padding(this.tm.current.value12)
    .backgroundColor(this.tm.current.widgetCardBg)
    .borderRadius(this.tm.current.radius16)
    .onClick(() => {
      const page = this.gameCount === 1 ? dailyDetailPage(this.game0Id) : 'Main';
      postCardAction(this, { action: 'router', abilityName: 'EntryAbility', params: { page: page } });
    })
  }
}

@Preview
@Component
struct Widget2x4Preview {
  build() {
    Column({ space: 12 }) {
      Widget2x4()
        .width(352)
        .height(168)
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
