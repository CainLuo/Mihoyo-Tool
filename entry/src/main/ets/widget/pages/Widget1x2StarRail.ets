/**
 * Widget1x2StarRail.ets — 星铁 1×2 迷你卡片
 *
 * v1.1 设计：
 * - 使用单一 @LocalStorageProp('payload') 接收完整 JSON
 * - 解析 payload 决定显示内容
 * - 游戏主题色渐变背景
 */

import { Logger } from 'core';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { Widget1x2StarRailContent } from '../components/Widget1x2StarRailContent';
import { WidgetGameData, WidgetSingleGameData } from '../models/WidgetModels';
import { parsePayload } from '../utils/WidgetPayloadParser';

const TAG = 'Widget1x2StarRail';

let storageStarRail1x2 = new LocalStorage();

@Entry(storageStarRail1x2)
@Component
struct Widget1x2StarRail {
  private tm: ThemeManager = themeManager;

  // 单一 payload 字段
  @LocalStorageProp('payload') payloadJson: string = '';

  private buildData(): WidgetSingleGameData {
    const d = new WidgetSingleGameData();
    const parsed = parsePayload(this.payloadJson);

    // 获取第一个角色的数据
    const roles = parsed.getAllRoles();
    if (roles.length === 0) {
      Logger.info(TAG, 'buildData: no roles found');
      return d;
    }

    const firstRole = roles[0];
    d.accountName = parsed.firstAccount?.accountName ?? '';
    d.accountUid = parsed.firstAccount?.accountId ?? '';
    d.game = new WidgetGameData();
    d.game.gameId = parsed.getUniqueGameIds()[0] ?? '';
    d.game.currentStr = firstRole.currentStamina.toString();
    d.game.maxStr = firstRole.maxStamina.toString();

    Logger.info(TAG, `buildData: gameId=${d.game.gameId} current=${d.game.currentStr}/${d.game.maxStr}`);
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
