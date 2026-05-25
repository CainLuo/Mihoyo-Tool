/**
 * Widget2x4.ets — 2×4 宽幅卡片入口
 *
 * v1.1 design:
 * - Use single @LocalStorageProp('payload') to receive complete JSON
 * - Parse payload to determine display content
 * - Dynamic gradient color based on game type
 */

import { WidgetCardContent, WidgetCardSize } from '../components/WidgetCardContent';
import { parsePayload, ParsedRole } from '../utils/WidgetPayloadParser';
import { widgetGradient } from '../utils/WidgetUtils';
import { DefaultTheme } from '../../theme/DefaultTheme';

/** 主题常量实例（Widget 直接使用，不依赖 @ObservedV2/@Trace） */
const theme = new DefaultTheme();

let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct Widget2x4 {
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
    Stack() {
      // Background layer with gradient
      Column()
        .width(theme.full)
        .height(theme.full)
        .linearGradient(widgetGradient(this.getGameIds()))
        .borderRadius(theme.radius16)

      // Content layer
      Column() {
        WidgetCardContent({
          cardSize: WidgetCardSize.SIZE_2x4,
          allRoles: this.getAllRoles(),
          gameIds: this.getGameIds(),
          isSingleGame: this.getIsSingleGame(),
        })
      }
      .width(theme.full)
      .height(theme.full)
      .padding(theme.value12)
    }
    .width(theme.full)
    .height(theme.full)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { page: 'Main' }
      });
    })
  }
}
