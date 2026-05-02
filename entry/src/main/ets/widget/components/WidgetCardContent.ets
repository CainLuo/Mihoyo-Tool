/**
 * WidgetCardContent.ets — 多游戏卡片通用内容组件
 *
 * 2×2、2×4、4×4 三种卡片共用此组件，差异通过 cardSize 参数区分。
 * @LocalStorageProp 在此组件内声明，子组件自动继承 @Entry 的 LocalStorage 实例，
 * 无需在 @Entry 里重复声明后再传参。
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { Widget2x2SingleGame } from './Widget2x2SingleGame';
import { Widget2x4SingleGame } from './Widget2x4SingleGame';
import { Widget4x4SingleGame } from './Widget4x4SingleGame';
import { Widget4x4MultiGame } from './Widget4x4MultiGame';
import { WidgetMultiGameCompact } from './WidgetMultiGameCompact';
import { dailyDetailPage } from '../utils/WidgetUtils';
import { WidgetGameData, WidgetAccountData, WidgetSingleGameData } from '../models/WidgetModels';

/** 卡片尺寸类型，决定使用哪个单游戏/多游戏组件 */
export enum WidgetCardSize {
  SIZE_2x2,
  SIZE_2x4,
  SIZE_4x4,
}

@Component
export struct WidgetCardContent {
  private tm: ThemeManager = themeManager;

  cardSize: WidgetCardSize = WidgetCardSize.SIZE_2x2;

  // 从 LocalStorage 直接读取，子组件自动继承 @Entry 的 LocalStorage 实例
  @LocalStorageProp('accountName') private accountName: string = '';
  @LocalStorageProp('accountUid') private accountUid: string = '';
  @LocalStorageProp('gameCount') private gameCountStr: string = '0';
  @LocalStorageProp('game0Id') private game0Id: string = '';
  @LocalStorageProp('game0Json') private game0Json: string = '';
  @LocalStorageProp('game1Json') private game1Json: string = '';
  @LocalStorageProp('game2Json') private game2Json: string = '';

  private get gameCount(): number { return parseInt(this.gameCountStr) || 0; }

  private get ringSize(): number {
    return this.cardSize === WidgetCardSize.SIZE_2x2 ? themeManager.current.value28 : themeManager.current.value24;
  }

  private buildSingleData(): WidgetSingleGameData {
    const d = new WidgetSingleGameData();
    d.accountName = this.accountName;
    d.accountUid = this.accountUid;
    d.game = WidgetGameData.fromJson(this.game0Json);
    return d;
  }

  private buildMultiData(): WidgetAccountData {
    const acc = new WidgetAccountData();
    acc.accountName = this.accountName;
    acc.accountUid = this.accountUid;
    acc.gameCount = this.gameCount;
    acc.games.push(WidgetGameData.fromJson(this.game0Json));
    if (this.gameCount >= 2) { acc.games.push(WidgetGameData.fromJson(this.game1Json)); }
    if (this.gameCount >= 3) { acc.games.push(WidgetGameData.fromJson(this.game2Json)); }
    return acc;
  }

  /** 供 @Entry 的 onClick 使用，避免重复解析 JSON */
  get targetPage(): string {
    return this.gameCount === 1 ? dailyDetailPage(this.game0Id) : 'Main';
  }

  build() {
    Column() {
      if (this.gameCount === 0) {
        // 未配置账号时显示占位提示
        Column() {
          Text($r('app.string.widget_no_account'))
            .fontSize(themeManager.current.value13)
            .fontColor($r('app.color.text_on_dark_secondary'))
            .textAlign(TextAlign.Center)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.gameCount === 1) {
        if (this.cardSize === WidgetCardSize.SIZE_4x4) {
          Widget4x4SingleGame({ data: this.buildSingleData() })
        } else if (this.cardSize === WidgetCardSize.SIZE_2x4) {
          Widget2x4SingleGame({ data: this.buildSingleData() })
        } else {
          Widget2x2SingleGame({ data: this.buildSingleData() })
        }
      } else {
        if (this.cardSize === WidgetCardSize.SIZE_4x4) {
          Widget4x4MultiGame({ data: this.buildMultiData() })
        } else {
          WidgetMultiGameCompact({ data: this.buildMultiData(), ringSize: this.ringSize })
        }
      }
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
  }
}

@Preview
@Component
struct WidgetCardContentPreview {
  build() {
    Column({ space: 12 }) {
      WidgetCardContent({ cardSize: WidgetCardSize.SIZE_2x2 })
        .width(168)
        .height(168)
        .padding(12)
        .backgroundColor('#2E3033')
        .borderRadius(16)

      WidgetCardContent({ cardSize: WidgetCardSize.SIZE_2x4 })
        .width(352)
        .height(168)
        .padding(12)
        .backgroundColor('#2E3033')
        .borderRadius(16)
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
