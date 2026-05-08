/**
 * Widget1x2ZZZ.ets — 绝区零 1×2 迷你卡片
 *
 * v1.1 设计：
 * - 使用单一 @LocalStorageProp('payload') 接收完整 JSON
 * - 解析 payload 决定显示内容
 * - 游戏主题色渐变背景
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { Widget1x2Content } from '../components/Widget1x2Content';
import { WidgetGameData, WidgetSingleGameData } from '../models/WidgetModels';
import { parsePayload, ParsedRole } from '../utils/WidgetPayloadParser';

let storageZZZ1x2 = new LocalStorage();

@Entry(storageZZZ1x2)
@Component
struct Widget1x2ZZZ {
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

    // 查找绝区零角色（因为这是绝区零模板）
    let zzzRole: ParsedRole | null = null;
    for (let i = 0; i < roles.length; i++) {
      if (roles[i].isZZZ()) {
        zzzRole = roles[i];
        break;
      }
    }

    if (zzzRole === null) {
      // 没有绝区零数据，使用第一个角色作为 fallback
      zzzRole = roles[0];
    }

    // 获取账号信息
    const firstAccount = parsed.firstAccount;
    if (firstAccount !== null) {
      d.accountName = firstAccount.accountName;
    }
    // UID 显示游戏角色 UID，不是米游社账号 UID
    d.accountUid = zzzRole.roleId;

    // 填充游戏数据
    d.game = new WidgetGameData();
    d.game.gameId = 'zzz';
    d.game.currentStr = String(zzzRole.currentStamina);
    d.game.maxStr = String(zzzRole.maxStamina);
    d.game.secondsStr = String(zzzRole.recoverySeconds);

    return d;
  }

  build() {
    Column() {
      Widget1x2Content({
        data: this.buildData(),
        gameColor: $r('app.color.game_color_zzz')
      })
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .padding({
      left: this.tm.current.value12,
      right: this.tm.current.value12
    })
    .linearGradient({ angle: this.tm.current.a135, colors: [['#1e1a0e', 0], ['#2a2010', 0.5], ['#342810', 1]] })
    .borderRadius(this.tm.current.radius16)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { page: 'ZZZDailyDetail' }
      });
    })
  }
}

@Preview
@Component
struct Widget1x2ZZZPreview {
  build() {
    Column({ space: 12 }) {
      Widget1x2ZZZ()
        .width(168)
        .height(80)
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
