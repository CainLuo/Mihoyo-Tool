/**
 * Widget4x4.ets — 4×4 大卡片入口
 *
 * v1.1 设计：
 * - 使用单一 @LocalStorageProp('payload') 接收完整 JSON
 * - 解析 payload 决定显示内容
 * - 单游戏：游戏主题色渐变背景
 * - 多游戏：多色混合渐变背景
 */

import { Logger } from 'core';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { WidgetCardContent, WidgetCardSize } from '../components/WidgetCardContent';
import { parsePayload, ParsedPayload, ParsedRole } from '../utils/WidgetPayloadParser';
import { dailyDetailPage, WIDGET_GAME_ID } from '../utils/WidgetUtils';

const TAG = 'Widget4x4';

/** 游戏背景色系 */
class GameColorBase {
  dark: string = '#181820';
  mid: string = '#1c1c2c';

  constructor(dark: string, mid: string) {
    this.dark = dark;
    this.mid = mid;
  }
}

let storage4x4 = new LocalStorage();

@Entry(storage4x4)
@Component
struct Widget4x4 {
  private tm: ThemeManager = themeManager;

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
      return { angle: this.tm.current.a135, colors: [['#181828', 0], ['#201830', 0.5], ['#261c40', 1]] };
    }
    if (gameId === WIDGET_GAME_ID.ZZZ) {
      return { angle: this.tm.current.a135, colors: [['#1e1a0e', 0], ['#2a2010', 0.5], ['#342810', 1]] };
    }

    Logger.info(TAG, `singleGameGradient: gameId=${gameId}`);
    return { angle: this.tm.current.a135, colors: [['#152030', 0], ['#1a2d42', 0.5], ['#1c3350', 1]] };
  }

  /** 多游戏渐变背景 */
  private get multiGameGradient(): LinearGradient {
    const games = this.gameIds;

    Logger.info(TAG, `multiGameGradient: games=${games.join(',')}`);

    if (games.length === 2) {
      const c0 = this.gameColorBase(games[0]);
      const c1 = this.gameColorBase(games[1]);
      return { angle: this.tm.current.a135, colors: [[c0.dark, 0], [c0.mid, 0.4], [c1.mid, 0.6], [c1.dark, 1]] };
    }
    if (games.length >= 3) {
      const c0 = this.gameColorBase(games[0]);
      const c1 = this.gameColorBase(games[1]);
      const c2 = this.gameColorBase(games[2]);
      return { angle: this.tm.current.a135, colors: [[c0.dark, 0], [c0.mid, 0.25], [c1.mid, 0.5], [c2.mid, 0.75], [c2.dark, 1]] };
    }
    return { angle: this.tm.current.a135, colors: [['#181820', 0], ['#1c1c2c', 1]] };
  }

  private gameColorBase(gameId: string): GameColorBase {
    if (gameId === WIDGET_GAME_ID.GENSHIN) return new GameColorBase('#152030', '#1a2d42');
    if (gameId === WIDGET_GAME_ID.STARRAIL) return new GameColorBase('#181828', '#201830');
    if (gameId === WIDGET_GAME_ID.ZZZ) return new GameColorBase('#1e1a0e', '#2a2010');
    return new GameColorBase('#181820', '#1c1c2c');
  }

  build() {
    Column() {
      WidgetCardContent({ 
        cardSize: WidgetCardSize.SIZE_4x4,
        payloadJson: this.payloadJson 
      })
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .padding(this.tm.current.value12)
    .linearGradient(this.parsed.isSingleGame ? this.singleGameGradient : this.multiGameGradient)
    .borderRadius(this.tm.current.radius16)
    .onClick(() => {
      const page = this.parsed.isSingleGame && this.gameIds.length > 0 ?
        dailyDetailPage(this.gameIds[0]) : 'Main';
      postCardAction(this, { action: 'router', abilityName: 'EntryAbility', params: { page: page } });
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
    .backgroundColor('#1a1a2e')
  }
}
