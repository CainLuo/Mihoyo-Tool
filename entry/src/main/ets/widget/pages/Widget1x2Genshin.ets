/**
 * Widget1x2Genshin.ets — 原神 1×2 迷你卡片
 *
 * 测试版本：使用纯色背景，排查 linearGradient 和资源引用问题
 */

import { Widget1x2Content } from '../components/Widget1x2Content';
import { WidgetGameData, WidgetSingleGameData } from '../models/WidgetModels';
import { parsePayload, ParsedRole } from '../utils/WidgetPayloadParser';

let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct Widget1x2Genshin {
  @LocalStorageProp('payload') payloadJson: string = '';

  // private buildData(): WidgetSingleGameData {
  //   const d = new WidgetSingleGameData();
  //   const parsed = parsePayload(this.payloadJson);

  //   const roles = parsed.getAllRoles();
  //   if (roles.length === 0) {
  //     // 无数据时，返回默认的原神占位数据
  //     d.game = new WidgetGameData();
  //     d.game.gameId = 'genshin';
  //     return d;
  //   }

  //   let genshinRole: ParsedRole = new ParsedRole();
  //   let found = false;
  //   for (let i = 0; i < roles.length; i++) {
  //     if (roles[i].isGenshin()) {
  //       genshinRole = roles[i];
  //       found = true;
  //       break;
  //     }
  //   }

  //   // 如果找不到原神数据，使用第一个角色的数据，但保持 gameId 为 genshin
  //   // 因为这是原神卡片模板，不应该显示其他游戏的数据
  //   if (!found) {
  //     genshinRole = roles[0];
  //   }

  //   const firstAccount = parsed.firstAccount;
  //   if (firstAccount.accountName.length > 0) {
  //     d.accountName = firstAccount.accountName;
  //   }
  //   d.accountUid = genshinRole.roleId;

  //   d.game = new WidgetGameData();
  //   // 始终使用 'genshin' 作为 gameId，因为这是原神卡片模板
  //   d.game.gameId = 'genshin';
  //   d.game.currentStr = String(genshinRole.currentStamina);
  //   d.game.maxStr = String(genshinRole.maxStamina);
  //   d.game.secondsStr = String(genshinRole.recoverySeconds);

  //   return d;
  // }

  build() {
    Column() {
      Text("Hello Word")
        .fontColor(Color.Red)
      // Widget1x2Content({
      //   data: this.buildData(),
      //   gameColor: $r('app.color.game_color_genshin')
      // })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Blue)
    // .padding({ left: 12, right: 12 })
    // .linearGradient({ angle: 135, colors: [[$r('app.color.widget_bg_genshin_dark'), 0], [$r('app.color.widget_bg_genshin_mid'), 0.5], [$r('app.color.widget_bg_genshin_light'), 1]] })
    // .borderRadius(16)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { page: 'GenshinDailyDetail' }
      });
    })
  }
}

// @Preview
// @Component
// struct Widget1x2GenshinPreview {
//   build() {
//     Column({ space: 12 }) {
//       Widget1x2Genshin()
//         .width(168)
//         .height(80)
//     }
//     .padding(16)
//     .backgroundColor($r('app.color.widget_preview_bg'))
//   }
// }
