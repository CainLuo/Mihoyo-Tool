/**
 * Widget4x4.ets — 4×4 大卡片入口
 *
 * v1.1 design:
 * - Use single @LocalStorageProp('payload') to receive complete JSON
 * - Parse payload to determine display content
 */

import { WidgetCardContent, WidgetCardSize } from '../components/WidgetCardContent';
import { parsePayload, ParsedRole } from '../utils/WidgetPayloadParser';

let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct Widget4x4 {
  @LocalStorageProp('payload') payloadJson: string = '';

  private getAllRoles(): ParsedRole[] {
    return parsePayload(this.payloadJson).getAllRoles();
  }

  private getGameIds(): string[] {
    return parsePayload(this.payloadJson).getUniqueGameIds();
  }

  private getIsSingleGame(): boolean {
    return parsePayload(this.payloadJson).isSingleGame;
  }

  build() {
    Column() {
      WidgetCardContent({
        cardSize: WidgetCardSize.SIZE_4x4,
        allRoles: this.getAllRoles(),
        gameIds: this.getGameIds(),
        isSingleGame: this.getIsSingleGame(),
      })
    }
    .width('100%')
    .height('100%')
    .linearGradient({ angle: 135, colors: [['#152030', 0], ['#1c3350', 1]] })
    .borderRadius(16)
    .padding(12)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { page: 'Main' }
      });
    })
  }
}

@Preview
@Component
struct Widget4x4Preview {
  build() {
    Column({ space: 12 }) {
      Widget4x4()
        .width(352)
        .height(352)
    }
    .padding(16)
    .backgroundColor($r('app.color.widget_preview_bg'))
  }
}
