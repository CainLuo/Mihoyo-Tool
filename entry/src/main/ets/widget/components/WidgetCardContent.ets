/**
 * WidgetCardContent.ets — 多游戏卡片通用内容组件
 *
 * 2×2、2×4、4×4 三种卡片共用此组件，差异通过 cardSize 参数区分。
 * 
 * v1.1 更新：支持新的多账号混显 payload 格式
 * - 新格式：slot0Json、slot1Json、slot2Json（每个 slot 含完整的账号/游戏/角色数据）
 * - 旧格式：game0Json、game1Json、game2Json（单账号多游戏）
 * 
 * 自动检测 payload 格式并选择对应的渲染方式。
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { Logger } from 'core';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { Widget2x2SingleGame } from './Widget2x2SingleGame';
import { Widget2x4SingleGame } from './Widget2x4SingleGame';
import { Widget4x4SingleGame } from './Widget4x4SingleGame';
import { Widget4x4MultiGame } from './Widget4x4MultiGame';
import { WidgetMultiGameCompact } from './WidgetMultiGameCompact';
import { WidgetSlotRenderer, WidgetSlotSize } from './WidgetSlotRenderer';
import { dailyDetailPage, WIDGET_GAME_ID } from '../utils/WidgetUtils';
import { WidgetGameData, WidgetAccountData, WidgetSingleGameData } from '../models/WidgetModels';
import { parseSlotJson, ParsedSlotData } from '../utils/WidgetSlotDataParser';

/** 卡片尺寸类型，决定使用哪个单游戏/多游戏组件 */
export enum WidgetCardSize {
  SIZE_1x2,
  SIZE_2x2,
  SIZE_2x4,
  SIZE_4x4,
}

@Component
export struct WidgetCardContent {
  private tm: ThemeManager = themeManager;

  cardSize: WidgetCardSize = WidgetCardSize.SIZE_2x2;

  // ── 新格式：多账号混显 payload ──
  @LocalStorageProp('widgetSize') private widgetSize: string = '';
  @LocalStorageProp('slotCount') private slotCountStr: string = '0';
  @LocalStorageProp('slot0Json') private slot0Json: string = '';
  @LocalStorageProp('slot1Json') private slot1Json: string = '';
  @LocalStorageProp('slot2Json') private slot2Json: string = '';

  // ── 旧格式：单账号多游戏 payload ──
  @LocalStorageProp('accountName') private accountName: string = '';
  @LocalStorageProp('accountUid') private accountUid: string = '';
  @LocalStorageProp('gameCount') private gameCountStr: string = '0';
  @LocalStorageProp('game0Id') private game0Id: string = '';
  @LocalStorageProp('game0Json') private game0Json: string = '';
  @LocalStorageProp('game1Id') private game1Id: string = '';
  @LocalStorageProp('game1Json') private game1Json: string = '';
  @LocalStorageProp('game2Id') private game2Id: string = '';
  @LocalStorageProp('game2Json') private game2Json: string = '';

  private get slotCount(): number { return parseInt(this.slotCountStr) || 0; }
  private get gameCount(): number { return parseInt(this.gameCountStr) || 0; }

  /** 是否使用新格式（多账号混显） */
  private get useNewFormat(): boolean {
    return this.slotCount > 0 || this.slot0Json.length > 0;
  }

  private get ringSize(): number {
    if (this.cardSize === WidgetCardSize.SIZE_2x2) {
      return 0;
    }
    return 1;
  }

  /** 获取 SlotSize 枚举值 */
  private get slotSize(): WidgetSlotSize {
    switch (this.cardSize) {
      case WidgetCardSize.SIZE_1x2:
        return WidgetSlotSize.SIZE_1x2;
      case WidgetCardSize.SIZE_2x4:
        return WidgetSlotSize.SIZE_2x4;
      case WidgetCardSize.SIZE_4x4:
        return WidgetSlotSize.SIZE_4x4;
      default:
        return WidgetSlotSize.SIZE_2x2;
    }
  }

  // ── 旧格式数据构建 ──

  private buildSingleData(): WidgetSingleGameData {
    const d = new WidgetSingleGameData();
    d.accountName = this.accountName;
    d.accountUid = this.accountUid;
    d.game = WidgetGameData.fromJson(this.game0Json);
    Logger.info('WidgetCardContent', `buildSingleData: gameId=${d.game.gameId} currentStr=${d.game.currentStr} maxStr=${d.game.maxStr}`);
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

  // ── 新格式数据解析 ──

  private parseSlot(json: string): ParsedSlotData {
    return parseSlotJson(json);
  }

  private get parsedSlots(): ParsedSlotData[] {
    const slots: ParsedSlotData[] = [];
    if (this.slot0Json.length > 0) { slots.push(this.parseSlot(this.slot0Json)); }
    if (this.slotCount >= 2 && this.slot1Json.length > 0) { slots.push(this.parseSlot(this.slot1Json)); }
    if (this.slotCount >= 3 && this.slot2Json.length > 0) { slots.push(this.parseSlot(this.slot2Json)); }
    return slots;
  }

  /** 供 @Entry 的 onClick 使用 */
  get targetPage(): string {
    if (this.useNewFormat) {
      const slots = this.parsedSlots;
      if (slots.length === 1) {
        return dailyDetailPage(slots[0].gameId);
      }
      return 'Main';
    }
    return this.gameCount === 1 ? dailyDetailPage(this.game0Id) : 'Main';
  }

  build() {
    Column() {
      if (this.useNewFormat) {
        // ── 新格式：多账号混显 ──
        this.buildNewFormatContent();
      } else {
        // ── 旧格式：单账号多游戏 ──
        this.buildOldFormatContent();
      }
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
  }

  @Builder
  private buildNewFormatContent(): void {
    if (this.parsedSlots.length === 0) {
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
    } else if (this.parsedSlots.length === 1) {
      // 单 Slot：使用新的 WidgetSlotRenderer
      WidgetSlotRenderer({
        data: this.parsedSlots[0],
        slotSize: this.slotSize,
      })
    } else {
      // 多 Slot：使用 Column 布局渲染多个 WidgetSlotRenderer
      // TODO: 后续可优化为多 Slot 布局
      Column({ space: themeManager.current.value8 }) {
        ForEach(this.parsedSlots, (slot: ParsedSlotData, idx: number) => {
          WidgetSlotRenderer({
            data: slot,
            slotSize: WidgetSlotSize.SIZE_1x2, // 多 Slot 时使用紧凑布局
          })
        })
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .justifyContent(FlexAlign.SpaceEvenly)
    }
  }

  @Builder
  private buildOldFormatContent(): void {
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
