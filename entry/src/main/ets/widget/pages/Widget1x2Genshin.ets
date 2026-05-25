/**
 * Widget1x2Genshin.ets — 原神 1×2 迷你卡片
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
 *
 * 测试：使用 AppTheme 的 DefaultTheme 获取数值（不使用 @ObservedV2/@Trace）
 */

import { Widget1x2Content } from '../components/Widget1x2Content';
import { WidgetGameData, WidgetSingleGameData } from '../models/WidgetModels';
import { parsePayload, ParsedRole } from '../utils/WidgetPayloadParser';
import { widgetSingleGameGradient, WIDGET_GAME_ID } from '../utils/WidgetUtils';
import { DefaultTheme } from '../../theme/DefaultTheme';

/** 主题常量实例（Widget 直接使用，不依赖 @ObservedV2/@Trace） */
const theme = new DefaultTheme();

let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct Widget1x2Genshin {
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
    // 注意：Widget Form 不支持 union 类型，使用普通变量
    let genshinRole: ParsedRole = new ParsedRole();
    let found = false;
    for (let i = 0; i < roles.length; i++) {
      if (roles[i].isGenshin()) {
        genshinRole = roles[i];
        found = true;
        break;
      }
    }

    if (!found) {
      // 没有原神数据，使用第一个角色作为 fallback
      genshinRole = roles[0];
    }

    // 获取账号信息
    // 注意：Widget Form 不支持 union 类型，firstAccount 返回默认对象
    const firstAccount = parsed.firstAccount;
    if (firstAccount.accountName.length > 0) {
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
    .width(theme.full)
    .height(theme.full)
    .padding({
      left: theme.value12,
      right: theme.value12
    })
    .linearGradient(widgetSingleGameGradient(WIDGET_GAME_ID.GENSHIN))
    .borderRadius(theme.radius16)
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
    .backgroundColor($r('app.color.widget_preview_bg'))
  }
}
