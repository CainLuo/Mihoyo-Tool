/**
 * Widget1x2ZZZ.ets — 绝区零 1×2 迷你卡片
 *
 * v1.1 设计：
 * - 使用单一 @LocalStorageProp('payload') 接收完整 JSON
 * - 解析 payload 决定显示内容
 * - 游戏主题色渐变背景
 *
 * 注意：
 * - Widget Form 不支持 union 类型，使用默认对象而非 null
 * - Widget 使用 @Component（V1 体系），不能使用 @ObservedV2/@Trace
 *
 * LocalStorage 使用说明（参考官方示例 CardInfoRefresh）：
 * - Widget 必须创建 LocalStorage 实例并传给 @Entry
 * - FormExtensionAbility 通过 createFormBindingData 传递的数据会注入到此实例
 * - @LocalStorageProp('payload') 从该实例读取数据
 */

import { Widget1x2Content } from '../components/Widget1x2Content';
import { WidgetGameData, WidgetSingleGameData } from '../models/WidgetModels';
import { parsePayload, ParsedRole } from '../utils/WidgetPayloadParser';

let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct Widget1x2ZZZ {
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
    // 注意：Widget Form 不支持 union 类型，使用普通变量
    let zzzRole: ParsedRole = new ParsedRole();
    let found = false;
    for (let i = 0; i < roles.length; i++) {
      if (roles[i].isZZZ()) {
        zzzRole = roles[i];
        found = true;
        break;
      }
    }

    if (!found) {
      // 没有绝区零数据，使用第一个角色作为 fallback
      zzzRole = roles[0];
    }

    // 获取账号信息
    // 注意：Widget Form 不支持 union 类型，firstAccount 返回默认对象
    const firstAccount = parsed.firstAccount;
    if (firstAccount.accountName.length > 0) {
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
    .width('100%')
    .height('100%')
    .padding({
      left: 12,
      right: 12
    })
    .linearGradient({ angle: 135, colors: [[$r('app.color.widget_bg_zzz_dark'), 0], [$r('app.color.widget_bg_zzz_mid'), 0.5], [$r('app.color.widget_bg_zzz_light'), 1]] })
    .borderRadius(16)
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
    .backgroundColor($r('app.color.widget_preview_bg'))
  }
}

