/**
 * Widget2x2.ets - 2x2 standard card entry
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
struct Widget2x2 {
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
        cardSize: WidgetCardSize.SIZE_2x2,
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
