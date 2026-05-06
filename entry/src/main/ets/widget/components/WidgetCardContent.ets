/**
 * WidgetCardContent.ets — 多游戏卡片通用内容组件
 *
 * 2×2、2×4、4×4 三种卡片共用此组件，差异通过 cardSize 参数区分。
 *
 * v1.1 更新：
 * - 使用单一 @LocalStorageProp('payload') 接收完整 JSON
 * - 解析 payload 决定显示内容
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
import { parsePayload, ParsedPayload, ParsedRole, ParsedAccount } from '../utils/WidgetPayloadParser';
import { ParsedSlotData, parseSlotJson } from '../utils/WidgetSlotDataParser';

/**
 * Slot JSON 数据结构（用于序列化后解析）
 */
class SlotJsonData {
  gameId: string = '';
  accountId: string = '';
  accountName: string = '';
  roleId: string = '';
  nickname: string = '';
  server: string = '';
  rawJson: string = '';
}

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

  // 从父组件接收 payload
  payloadJson: string = '';

  /** 解析后的 payload */
  private get parsed(): ParsedPayload {
    return parsePayload(this.payloadJson);
  }

  /** 获取所有角色 */
  private get allRoles(): ParsedRole[] {
    return this.parsed.getAllRoles();
  }

  /** 获取游戏 ID 列表 */
  private get gameIds(): string[] {
    return this.parsed.getUniqueGameIds();
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

  /** 供 @Entry 的 onClick 使用 */
  get targetPage(): string {
    if (this.parsed.isSingleGame && this.gameIds.length > 0) {
      return dailyDetailPage(this.gameIds[0]);
    }
    return 'Main';
  }

  build() {
    Column() {
      if (this.allRoles.length === 0) {
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
      } else if (this.parsed.isSingleGame && this.allRoles.length === 1) {
        // 单角色：使用 WidgetSlotRenderer
        WidgetSlotRenderer({
          data: this.buildSlotData(this.allRoles[0]),
          slotSize: this.slotSize,
        })
      } else if (this.parsed.isSingleGame) {
        // 单游戏多角色：使用旧组件
        this.buildSingleGameMultiRoleContent()
      } else {
        // 多游戏：使用 Column 布局渲染多个 WidgetSlotRenderer
        Column({ space: themeManager.current.value8 }) {
          ForEach(this.allRoles, (role: ParsedRole, idx: number) => {
            WidgetSlotRenderer({
              data: this.buildSlotData(role),
              slotSize: WidgetSlotSize.SIZE_1x2, // 多游戏时使用紧凑布局
            })
          })
        }
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .justifyContent(FlexAlign.SpaceEvenly)
      }
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
  }

  /** 构建 WidgetSlotRenderer 所需的数据 */
  private buildSlotData(role: ParsedRole): ParsedSlotData {
    // 构建 slot JSON 格式，然后用 parseSlotJson 解析（它会自动解析 rawJson 中的游戏专属数据）
    const slotJsonObj: SlotJsonData = new SlotJsonData();
    slotJsonObj.gameId = this.gameIds.length > 0 ? this.gameIds[0] : '';
    slotJsonObj.accountId = '';
    slotJsonObj.accountName = '';
    slotJsonObj.roleId = role.roleId;
    slotJsonObj.nickname = role.nickname;
    slotJsonObj.server = role.server;
    slotJsonObj.rawJson = role.rawJson;
    return parseSlotJson(JSON.stringify(slotJsonObj));
  }

  /** 构建单游戏多角色内容（使用旧组件） */
  @Builder
  private buildSingleGameMultiRoleContent(): void {
    if (this.cardSize === WidgetCardSize.SIZE_4x4) {
      Widget4x4MultiGame({ data: this.buildMultiRoleData() })
    } else {
      WidgetMultiGameCompact({ data: this.buildMultiRoleData(), ringSize: this.ringSize })
    }
  }

  /** 构建多角色数据 */
  private buildMultiRoleData(): WidgetAccountData {
    const acc = new WidgetAccountData();
    const firstAccount = this.parsed.firstAccount;

    if (firstAccount !== null) {
      acc.accountName = firstAccount.accountName;
      acc.accountUid = firstAccount.accountId;
    }

    acc.gameCount = this.gameIds.length;

    for (const gameId of this.gameIds) {
      const gameData = new WidgetGameData();
      gameData.gameId = gameId;

      // 从第一个匹配游戏类型的角色获取体力数据
      const role = this.findRoleByGameId(gameId);

      if (role !== null) {
        gameData.currentStr = role.currentStamina.toString();
        gameData.maxStr = role.maxStamina.toString();
      }

      acc.games.push(gameData);
    }

    return acc;
  }

  /** 根据游戏 ID 查找角色 */
  private findRoleByGameId(gameId: string): ParsedRole | null {
    for (const role of this.allRoles) {
      if (gameId === WIDGET_GAME_ID.GENSHIN && role.isGenshin()) {
        return role;
      }
      if (gameId === WIDGET_GAME_ID.STARRAIL && role.isStarRail()) {
        return role;
      }
      if (gameId === WIDGET_GAME_ID.ZZZ && role.isZZZ()) {
        return role;
      }
    }
    return null;
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
