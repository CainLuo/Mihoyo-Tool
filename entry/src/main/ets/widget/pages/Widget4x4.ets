/**
 * Widget4x4.ets — 4×4 大卡片入口
 *
 * v1.1 设计：
 * - 单游戏：游戏主题色渐变背景
 * - 多游戏：多色混合渐变背景
 */

import { Logger } from 'core';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { WidgetCardContent, WidgetCardSize } from '../components/WidgetCardContent';
import { dailyDetailPage, WIDGET_GAME_ID } from '../utils/WidgetUtils';

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

  @LocalStorageProp('accountName') accountName: string = '';
  @LocalStorageProp('accountUid') accountUid: string = '';
  @LocalStorageProp('gameCount') gameCountStr: string = '0';
  @LocalStorageProp('game0Id') game0Id: string = '';
  @LocalStorageProp('game0Json') game0Json: string = '';
  @LocalStorageProp('game1Id') game1Id: string = '';
  @LocalStorageProp('game1Json') game1Json: string = '';
  @LocalStorageProp('game2Id') game2Id: string = '';
  @LocalStorageProp('game2Json') game2Json: string = '';

  private get gameCount(): number { return parseInt(this.gameCountStr) || 0; }

  /** 单游戏渐变背景 */
  private get singleGameGradient(): LinearGradient {
    if (this.game0Id === WIDGET_GAME_ID.STARRAIL) {
      return { angle: this.tm.current.a135, colors: [['#181828', 0], ['#201830', 0.5], ['#261c40', 1]] };
    }
    if (this.game0Id === WIDGET_GAME_ID.ZZZ) {
      return { angle: this.tm.current.a135, colors: [['#1e1a0e', 0], ['#2a2010', 0.5], ['#342810', 1]] };
    }

    Logger.info('Widget 4X4', `💥💥💥 singleGameGradient`)

    return { angle: this.tm.current.a135, colors: [['#152030', 0], ['#1a2d42', 0.5], ['#1c3350', 1]] };
  }

  /** 多游戏渐变背景 */
  private get multiGameGradient(): LinearGradient {
    Logger.info('Widget 4X4', `💥💥💥 Widget 4X4`)

    const games: string[] = [];
    if (this.game0Id) games.push(this.game0Id);
    if (this.game1Id) games.push(this.game1Id);
    if (this.game2Id) games.push(this.game2Id);

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
      WidgetCardContent({ cardSize: WidgetCardSize.SIZE_4x4 })
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .padding(this.tm.current.value12)
    // .linearGradient(this.gameCount === 1 ? this.singleGameGradient : this.multiGameGradient)
    .linearGradient({ angle: this.tm.current.a135, colors: [['#152030', 0], ['#1a2d42', 0.5], ['#1c3350', 1]] })
    .borderRadius(this.tm.current.radius16)
    .onClick(() => {
      const page = this.gameCount === 1 ? dailyDetailPage(this.game0Id) : 'Main';
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
