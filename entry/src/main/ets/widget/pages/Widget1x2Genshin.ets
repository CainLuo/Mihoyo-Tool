/**
 * Widget1x2Genshin.ets — 原神 1×2 迷你卡片
 *
 * v1.1 设计：
 * - 使用单一 @LocalStorageProp('payload') 接收完整 JSON
 * - 解析 payload 决定显示内容
 * - 游戏主题色渐变背景
 *
 * 注意：Widget Form 不支持 `??` 运算符，必须使用三元运算符
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { Widget1x2Content } from '../components/Widget1x2Content';
import { WidgetGameData, WidgetSingleGameData } from '../models/WidgetModels';
import { parsePayload, ParsedRole } from '../utils/WidgetPayloadParser';

let storageGenshin1x2 = new LocalStorage();

@Entry(storageGenshin1x2)
@Component
struct Widget1x2Genshin {
  private tm: ThemeManager = themeManager;

  // 单一 payload 字段
  @LocalStorageProp('payload') payloadJson: string = '';

  private buildData(): WidgetSingleGameData {
    const d = new WidgetSingleGameData();
    const parsed = parsePayload(this.payloadJson);

    // 获取所有角色
    const roles = parsed.getAllRoles();
    if (roles.length === 0) {
      return d;
    }

    // 查找原神角色（因为这是原神模板）
    let genshinRole: ParsedRole | null = null;
    for (let i = 0; i < roles.length; i++) {
      if (roles[i].isGenshin()) {
        genshinRole = roles[i];
        break;
      }
    }

    if (genshinRole === null) {
      // 没有原神数据，使用第一个角色作为 fallback
      genshinRole = roles[0];
    }

    // 获取账号信息
    const firstAccount = parsed.firstAccount;
    if (firstAccount !== null) {
      d.accountName = firstAccount.accountName;
    }
    // UID 显示游戏角色 UID，不是米游社账号 UID
    d.accountUid = genshinRole.roleId;

    // 填充游戏数据
    d.game = new WidgetGameData();
    d.game.gameId = 'genshin';
    d.game.currentStr = String(genshinRole.currentStamina);
    d.game.maxStr = String(genshinRole.maxStamina);
    d.game.secondsStr = String(genshinRole.recoverySeconds);

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
    .padding({
      left: this.tm.current.value12,
      right: this.tm.current.value12
    })
    .linearGradient({ angle: this.tm.current.a135, colors: [['#152030', 0], ['#1a2d42', 0.5], ['#1c3350', 1]] })
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
