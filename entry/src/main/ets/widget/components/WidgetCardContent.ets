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
 *
 * 重要约束：
 * - Widget 组件不能导入 core 模块（HSP）
 * - Widget 组件不能使用 hilog，只能使用 console.log 或静默处理
 */

import { Widget4x4MultiGame } from './Widget4x4MultiGame';
import { WidgetMultiGameCompact } from './WidgetMultiGameCompact';
import { WidgetSlotRenderer, WidgetSlotSize } from './WidgetSlotRenderer';
import { WIDGET_GAME_ID } from '../utils/WidgetUtils';
import { WidgetGameData, WidgetAccountData } from '../models/WidgetModels';
import { ParsedRole } from '../utils/WidgetPayloadParser';
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

  cardSize: WidgetCardSize = WidgetCardSize.SIZE_2x2;

  // 从父组件接收解析后的数据
  allRoles: ParsedRole[] = [];
  gameIds: string[] = [];
  isSingleGame: boolean = true;

  build() {
    Column() {
      if (this.allRoles.length === 0) {
        // 未配置账号时显示占位提示
        Column() {
          Text($r('app.string.widget_no_account'))
            .fontSize(13)
            .fontColor($r('app.color.text_on_dark_secondary'))
            .textAlign(TextAlign.Center)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.isSingleGame && this.allRoles.length === 1) {
        // 单角色：使用 WidgetSlotRenderer
        WidgetSlotRenderer({
          data: this.buildSlotData(this.allRoles[0]),
          slotSize: this.slotSize,
        })
      } else if (this.isSingleGame) {
        // 单游戏多角色：使用旧组件
        this.buildSingleGameMultiRoleContent()
      } else {
        // 多游戏：使用 Column 布局渲染多个 WidgetSlotRenderer
        Column({ space: 8 }) {
          ForEach(this.allRoles, (role: ParsedRole, idx: number) => {
            WidgetSlotRenderer({
              data: this.buildSlotData(role),
              slotSize: WidgetSlotSize.SIZE_1x2, // 多游戏时使用紧凑布局
            })
          })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
      }
    }
    .width('100%')
    .height('100%')
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

  private get ringSize(): number {
    if (this.cardSize === WidgetCardSize.SIZE_2x2) {
      return 0;
    }
    return 1;
  }

  /** 构建 WidgetSlotRenderer 所需的数据 */
  private buildSlotData(role: ParsedRole): ParsedSlotData {
    // 从角色数据推断游戏类型
    let detectedGameId = '';
    if (role.isGenshin()) {
      detectedGameId = WIDGET_GAME_ID.GENSHIN;
    } else if (role.isStarRail()) {
      detectedGameId = WIDGET_GAME_ID.STARRAIL;
    } else if (role.isZZZ()) {
      detectedGameId = WIDGET_GAME_ID.ZZZ;
    }
    
    // 构建 slot JSON 格式，然后用 parseSlotJson 解析（它会自动解析 rawJson 中的游戏专属数据）
    const slotJsonObj: SlotJsonData = new SlotJsonData();
    slotJsonObj.gameId = detectedGameId;
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

    acc.accountName = '';
    acc.accountUid = '';
    acc.gameCount = this.gameIds.length;

    for (let i = 0; i < this.gameIds.length; i++) {
      const gameId = this.gameIds[i];
      const gameData = new WidgetGameData();
      gameData.gameId = gameId;

      // 从第一个匹配游戏类型的角色获取体力数据
      // 注意：Widget Form 不支持 union 类型，使用 roleId 判断是否有有效数据
      const role = this.findRoleByGameId(gameId);

      if (role.roleId.length > 0) {
        gameData.currentStr = role.currentStamina.toString();
        gameData.maxStr = role.maxStamina.toString();
      }

      acc.games.push(gameData);
    }

    return acc;
  }

  /** 根据游戏 ID 查找角色 */
  private findRoleByGameId(gameId: string): ParsedRole {
    for (let i = 0; i < this.allRoles.length; i++) {
      const role = this.allRoles[i];
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
    return new ParsedRole();
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
        .backgroundColor($r('app.color.widget_card_bg'))
        .borderRadius(16)

      WidgetCardContent({ cardSize: WidgetCardSize.SIZE_2x4 })
        .width(352)
        .height(168)
        .padding(12)
        .backgroundColor($r('app.color.widget_card_bg'))
        .borderRadius(16)
    }
    .padding(16)
    .backgroundColor($r('app.color.widget_preview_bg'))
  }
}
