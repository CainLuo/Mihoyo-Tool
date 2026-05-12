/**
 * Widget2x2.ets — 2×2 标准卡片入口
 *
 * v1.1 设计：
 * - 使用单一 @LocalStorageProp('payload') 接收完整 JSON
 * - 解析 payload 决定显示内容
 * - 单游戏：游戏主题色渐变背景
 * - 多游戏：多色混合渐变背景
 *
 * LocalStorage 使用说明（参考官方示例 CardInfoRefresh）：
 * - Widget 必须创建 LocalStorage 实例并传给 @Entry
 * - FormExtensionAbility 通过 createFormBindingData 传递的数据会注入到此实例
 * - @LocalStorageProp('payload') 从该实例读取数据
 */

import { WidgetCardContent, WidgetCardSize } from '../components/WidgetCardContent';
import { parsePayload, ParsedPayload, ParsedRole } from '../utils/WidgetPayloadParser';
import { dailyDetailPage, WIDGET_GAME_ID } from '../utils/WidgetUtils';

/** 游戏背景色系 */
class GameColorBase {
  dark: ResourceColor = $r('app.color.widget_bg_default_dark');
  mid: ResourceColor = $r('app.color.widget_bg_default_mid');

  constructor(dark: ResourceColor, mid: ResourceColor) {
    this.dark = dark;
    this.mid = mid;
  }
}

let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct Widget2x2 {

  // 单一 payload 字段
  @LocalStorageProp('payload') payloadJson: string = '';

  /** 解析后的 payload */
  private get parsed(): ParsedPayload {
    return parsePayload(this.payloadJson);
  }

  /** 获取所有角色 */
  private get allRoles(): ParsedRole[] {
    return this.parsed.getAllRoles();
  }

  /** 获取游戏 ID 列表（用于渐变背景） */
  private get gameIds(): string[] {
    return this.parsed.getUniqueGameIds();
  }

  /** 单游戏渐变背景 */
  private get singleGameGradient(): LinearGradient {
    const gameId = this.gameIds.length > 0 ? this.gameIds[0] : '';

    if (gameId === WIDGET_GAME_ID.STARRAIL) {
      return { angle: 135, colors: [[$r('app.color.widget_bg_starrail_dark'), 0], [$r('app.color.widget_bg_starrail_mid'), 0.5], [$r('app.color.widget_bg_starrail_light'), 1]] };
    }
    if (gameId === WIDGET_GAME_ID.ZZZ) {
      return { angle: 135, colors: [[$r('app.color.widget_bg_zzz_dark'), 0], [$r('app.color.widget_bg_zzz_mid'), 0.5], [$r('app.color.widget_bg_zzz_light'), 1]] };
    }
    return { angle: 135, colors: [[$r('app.color.widget_bg_genshin_dark'), 0], [$r('app.color.widget_bg_genshin_mid'), 0.5], [$r('app.color.widget_bg_genshin_light'), 1]] };
  }

  /** 多游戏渐变背景（按要求混合各游戏色系） */
  private get multiGameGradient(): LinearGradient {
    const games = this.gameIds;

    if (games.length === 2) {
      // 双游戏：左上第一款色系，右下第二款色系
      const c0 = this.gameColorBase(games[0]);
      const c1 = this.gameColorBase(games[1]);
      return { angle: 135, colors: [[c0.dark, 0], [c0.mid, 0.4], [c1.mid, 0.6], [c1.dark, 1]] };
    }
    if (games.length >= 3) {
      // 三游戏：三段渐变
      const c0 = this.gameColorBase(games[0]);
      const c1 = this.gameColorBase(games[1]);
      const c2 = this.gameColorBase(games[2]);
      return { angle: 135, colors: [[c0.dark, 0], [c0.mid, 0.25], [c1.mid, 0.5], [c2.mid, 0.75], [c2.dark, 1]] };
    }
    return { angle: 135, colors: [[$r('app.color.widget_bg_default_dark'), 0], [$r('app.color.widget_bg_default_mid'), 1]] };
  }

  /** 获取游戏对应的深色背景色系 */
  private gameColorBase(gameId: string): GameColorBase {
    if (gameId === WIDGET_GAME_ID.GENSHIN) return new GameColorBase($r('app.color.widget_bg_genshin_dark'), $r('app.color.widget_bg_genshin_mid'));
    if (gameId === WIDGET_GAME_ID.STARRAIL) return new GameColorBase($r('app.color.widget_bg_starrail_dark'), $r('app.color.widget_bg_starrail_mid'));
    if (gameId === WIDGET_GAME_ID.ZZZ) return new GameColorBase($r('app.color.widget_bg_zzz_dark'), $r('app.color.widget_bg_zzz_mid'));
    return new GameColorBase($r('app.color.widget_bg_default_dark'), $r('app.color.widget_bg_default_mid'));
  }

  build() {
    Column() {
      WidgetCardContent({ 
        cardSize: WidgetCardSize.SIZE_2x2,
        allRoles: this.allRoles,
        gameIds: this.gameIds,
        isSingleGame: this.parsed.isSingleGame,
      })
    }
    .width('100%')
    .height('100%')
    .padding(12)
    .linearGradient(this.parsed.isSingleGame ? this.singleGameGradient : this.multiGameGradient)
    .borderRadius(16)
    .onClick(() => {
      const page = this.parsed.isSingleGame && this.gameIds.length > 0 ?
        dailyDetailPage(this.gameIds[0]) : 'Main';
      postCardAction(this, { action: 'router', abilityName: 'EntryAbility', params: { page: page } });
    })
  }
}

@Preview
@Component
struct Widget2x2Preview {
  build() {
    Column({ space: 12 }) {
      Widget2x2()
        .width(168)
        .height(168)
    }
    .padding(16)
    .backgroundColor($r('app.color.widget_preview_bg'))
  }
}
