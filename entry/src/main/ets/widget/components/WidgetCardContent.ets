/**
 * WidgetCardContent.ets - Multi-game card content component
 *
 * Shared by 2x2, 2x4, 4x4 cards, differentiated by cardSize parameter.
 *
 * v1.1 update:
 * - Use single @LocalStorageProp('payload') to receive complete JSON
 * - Parse payload to determine display content
 *
 * Uses @Component (V1) because card rendering engine does not support @ComponentV2.
 *
 * Important constraints:
 * - Widget components cannot import core module (HSP)
 * - Widget components cannot use hilog, only console.log or silent handling
 */

import { Widget4x4MultiGame } from './Widget4x4MultiGame';
import { WidgetMultiGameCompact } from './WidgetMultiGameCompact';
import { WidgetSlotRenderer, WidgetSlotSize } from './WidgetSlotRenderer';
import { WIDGET_GAME_ID } from '../utils/WidgetUtils';
import { WidgetGameData, WidgetAccountData } from '../models/WidgetModels';
import { ParsedRole } from '../utils/WidgetPayloadParser';
import { ParsedSlotData, parseSlotJson } from '../utils/WidgetSlotDataParser';

/**
 * Slot JSON data structure (for serialization then parsing)
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

/** Card size type, determines which single/multi-game component to use */
export enum WidgetCardSize {
  SIZE_1x2,
  SIZE_2x2,
  SIZE_2x4,
  SIZE_4x4,
}

@Component
export struct WidgetCardContent {

  cardSize: WidgetCardSize = WidgetCardSize.SIZE_2x2;

  // Parsed data received from parent component
  // Note: Widget requires @Prop for object/array types to receive data correctly
  @Prop allRoles: ParsedRole[] = [];
  @Prop gameIds: string[] = [];
  @Prop isSingleGame: boolean = true;

  build() {
    Column() {
      if (this.allRoles.length === 0) {
        // Show placeholder when no account configured
        Column() {
          Text($r('app.string.widget_no_account'))
            .fontSize(13)
            .fontColor($r('app.color.gray_400'))
            .textAlign(TextAlign.Center)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.isSingleGame && this.allRoles.length === 1) {
        // Single role: use WidgetSlotRenderer
        WidgetSlotRenderer({
          data: this.buildSlotData(this.allRoles[0]),
          slotSize: this.slotSize,
        })
      } else if (this.isSingleGame) {
        // Single game multiple roles: use old component
        this.buildSingleGameMultiRoleContent()
      } else {
        // Multiple games: use Column layout to render multiple WidgetSlotRenderer
        Column({ space: 8 }) {
          ForEach(this.allRoles, (role: ParsedRole, idx: number) => {
            WidgetSlotRenderer({
              data: this.buildSlotData(role),
              slotSize: WidgetSlotSize.SIZE_1x2, // Use compact layout for multi-game
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

  /** Get SlotSize enum value */
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

  /** Build data for WidgetSlotRenderer */
  private buildSlotData(role: ParsedRole): ParsedSlotData {
    // Build SlotJsonData and serialize to JSON, then parse using parseSlotJson
    // This correctly fills genshin/starrail/zzz game-specific fields
    const slotJsonObj = new SlotJsonData();
    slotJsonObj.gameId = this.detectGameId(role);
    slotJsonObj.accountId = '';
    slotJsonObj.accountName = '';
    slotJsonObj.roleId = role.roleId;
    slotJsonObj.nickname = role.nickname;
    slotJsonObj.server = role.server;
    slotJsonObj.rawJson = role.rawJson;
    
    // Serialize and parse using parseSlotJson to correctly parse game-specific data
    const slotJson = JSON.stringify(slotJsonObj);
    return parseSlotJson(slotJson);
  }

  /** Detect game type */
  private detectGameId(role: ParsedRole): string {
    if (role.rawJson.length === 0) {
      // Infer from maxStamina
      if (role.maxStamina === 160) {
        return WIDGET_GAME_ID.GENSHIN;
      }
      return WIDGET_GAME_ID.STARRAIL;
    }
    
    try {
      const data = JSON.parse(role.rawJson) as Record<string, Object>;
      if (data['current_resin'] !== undefined) {
        return WIDGET_GAME_ID.GENSHIN;
      }
      if (data['current_stamina'] !== undefined) {
        return WIDGET_GAME_ID.STARRAIL;
      }
      if (data['energy'] !== undefined) {
        return WIDGET_GAME_ID.ZZZ;
      }
    } catch (_e) {
      // Parse failed, use default
    }
    
    return WIDGET_GAME_ID.GENSHIN;
  }

  /** Build single game multiple roles content (using old component) */
  @Builder
  private buildSingleGameMultiRoleContent(): void {
    if (this.cardSize === WidgetCardSize.SIZE_4x4) {
      Widget4x4MultiGame({ data: this.buildMultiRoleData() })
    } else {
      WidgetMultiGameCompact({ 
        accountName: this.buildMultiRoleData().accountName,
        accountUid: this.buildMultiRoleData().accountUid,
        gameCount: this.buildMultiRoleData().gameCount,
        games: this.buildMultiRoleData().games,
        ringSize: this.ringSize 
      })
    }
  }

  /** Build multi-role data */
  private buildMultiRoleData(): WidgetAccountData {
    const acc = new WidgetAccountData();

    acc.accountName = '';
    acc.accountUid = '';
    acc.gameCount = this.gameIds.length;

    for (let i = 0; i < this.gameIds.length; i++) {
      const gameId = this.gameIds[i];
      const gameData = new WidgetGameData();
      gameData.gameId = gameId;

      // Get stamina data from first matching game type role
      // Note: Widget Form does not support union type, use roleId to check if valid data
      const role = this.findRoleByGameId(gameId);

      if (role.roleId.length > 0) {
        gameData.currentStr = role.currentStamina.toString();
        gameData.maxStr = role.maxStamina.toString();
      }

      acc.games.push(gameData);
    }

    return acc;
  }

  /** Find role by game ID */
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
        .backgroundColor($r('app.color.widget_bg'))
        .borderRadius(16)

      WidgetCardContent({ cardSize: WidgetCardSize.SIZE_2x4 })
        .width(352)
        .height(168)
        .padding(12)
        .backgroundColor($r('app.color.widget_bg'))
        .borderRadius(16)
    }
    .padding(16)
    .backgroundColor($r('app.color.widget_bg'))
  }
}
