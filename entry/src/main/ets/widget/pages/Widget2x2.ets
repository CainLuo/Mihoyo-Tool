/**
 * Widget2x2.ets - 2x2 standard card entry
 *
 * v1.1 design:
 * - Use single @LocalStorageProp('payload') to receive complete JSON
 * - Parse payload to determine display content
 * - Single game (1 role): detailed layout with extra rows (expedition, home coin, etc.)
 * - Multi game (2 roles): compact layout showing stamina only
 */

import { WidgetCardContent, WidgetCardSize } from '../components/WidgetCardContent';
import { Widget2x2SingleGame } from '../components/Widget2x2SingleGame';
import { WidgetMultiGameCompact } from '../components/WidgetMultiGameCompact';
import { parsePayload, ParsedRole } from '../utils/WidgetPayloadParser';
import { widgetGradient, WIDGET_GAME_ID, gameColorRes } from '../utils/WidgetUtils';
import { WidgetSingleGameData, WidgetGameData, WidgetAccountData } from '../models/WidgetModels';
import { DefaultTheme } from '../../theme/DefaultTheme';

/** 主题常量实例（Widget 直接使用，不依赖 @ObservedV2/@Trace） */
const theme = new DefaultTheme();

let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct Widget2x2 {
  @LocalStorageProp('payload') payloadJson: string = '';

  private getAllRoles(): ParsedRole[] {
    return parsePayload(this.payloadJson).getAllRoles();
  }

  private getGameIds(): string[] {
    return parsePayload(this.payloadJson).getUniqueGameIds();
  }

  build() {
    Stack() {
      // Background layer with gradient
      Column()
        .width(theme.full)
        .height(theme.full)
        .linearGradient(widgetGradient(this.getGameIds()))
        .borderRadius(theme.radius16)

      // Content layer
      Column() {
        this.buildContent()
      }
      .width(theme.full)
      .height(theme.full)
      .padding(theme.value12)
    }
    .width(theme.full)
    .height(theme.full)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { page: 'Main' }
      });
    })
  }

  /** 根据角色数量选择布局 */
  @Builder
  private buildContent(): void {
    if (this.getAllRoles().length === 0) {
      // 无账号：显示占位
      Column() {
        Text($r('app.string.widget_no_account'))
          .fontSize(theme.value13)
          .fontColor($r('app.color.text_on_dark_secondary'))
          .textAlign(TextAlign.Center)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width(theme.full)
      .height(theme.full)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else if (this.getAllRoles().length === 1) {
      // 单游戏：使用 Widget2x2SingleGame，显示完整数据（派遣、洞天宝钱等）
      Widget2x2SingleGame({ data: this.buildSingleGameData(this.getAllRoles()[0]) })
    } else {
      // 双游戏：使用紧凑布局，只显示体力
      WidgetMultiGameCompact({ data: this.buildMultiGameData(this.getAllRoles()), ringSize: 0 })
    }
  }

  /** 构建单游戏数据 */
  private buildSingleGameData(role: ParsedRole): WidgetSingleGameData {
    const result = new WidgetSingleGameData();
    result.accountName = role.nickname;
    result.accountUid = role.roleId;
    
    const gameData = new WidgetGameData();
    gameData.gameId = this.detectGameId(role);
    gameData.currentStr = role.currentStamina.toString();
    gameData.maxStr = role.maxStamina.toString();
    gameData.secondsStr = role.recoverySeconds.toString();
    
    // 解析 rawJson 填充游戏专属字段
    this.parseGameSpecificData(role.rawJson, gameData);
    
    result.game = gameData;
    return result;
  }

  /** 构建多游戏数据 */
  private buildMultiGameData(roles: ParsedRole[]): WidgetAccountData {
    const acc = new WidgetAccountData();
    acc.accountName = roles.length > 0 ? roles[0].nickname : '';
    acc.accountUid = roles.length > 0 ? roles[0].roleId : '';
    acc.gameCount = roles.length;
    
    for (let i = 0; i < roles.length && i < 2; i++) {
      const role = roles[i];
      const gameData = new WidgetGameData();
      gameData.gameId = this.detectGameId(role);
      gameData.currentStr = role.currentStamina.toString();
      gameData.maxStr = role.maxStamina.toString();
      gameData.secondsStr = role.recoverySeconds.toString();
      acc.games.push(gameData);
    }
    
    return acc;
  }

  /** 检测游戏类型 */
  private detectGameId(role: ParsedRole): string {
    if (role.rawJson.length === 0) {
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
      // 解析失败使用默认值
    }
    
    return WIDGET_GAME_ID.GENSHIN;
  }

  /** 解析游戏专属数据 */
  private parseGameSpecificData(rawJson: string, gameData: WidgetGameData): void {
    if (rawJson.length === 0) {
      return;
    }
    
    try {
      const data = JSON.parse(rawJson) as Record<string, Object>;
      
      if (gameData.gameId === WIDGET_GAME_ID.GENSHIN) {
        // 原神：派遣、洞天宝钱
        gameData.expeditionMaxStr = data['max_expedition_num'] !== undefined ? String(data['max_expedition_num']) : '5';
        
        // 计算已完成的派遣数量
        const expeditions = data['expeditions'];
        if (expeditions !== undefined && expeditions !== null && Array.isArray(expeditions)) {
          let finishedCount = 0;
          for (let i = 0; i < expeditions.length; i++) {
            const exp = expeditions[i] as Record<string, Object>;
            if (exp['status'] === 'Finished') {
              finishedCount++;
            }
          }
          gameData.expeditionFinishedStr = String(finishedCount);
        } else {
          gameData.expeditionFinishedStr = '0';
        }
        
        gameData.coinStr = data['current_home_coin'] !== undefined ? String(data['current_home_coin']) : '0';
        gameData.coinMaxStr = data['max_home_coin'] !== undefined ? String(data['max_home_coin']) : '2400';
      } else if (gameData.gameId === WIDGET_GAME_ID.STARRAIL) {
        // 星铁：后备开拓力、每日实训、历战余响
        gameData.reserveStr = data['current_reserve_stamina'] !== undefined ? String(data['current_reserve_stamina']) : '0';
        gameData.trainStr = data['current_train_score'] !== undefined ? String(data['current_train_score']) : '0';
        gameData.trainMaxStr = data['max_train_score'] !== undefined ? String(data['max_train_score']) : '500';
        gameData.cocoonStr = data['weekly_cocoon_cnt'] !== undefined ? String(data['weekly_cocoon_cnt']) : '0';
        gameData.cocoonLimitStr = data['weekly_cocoon_limit'] !== undefined ? String(data['weekly_cocoon_limit']) : '3';
      } else if (gameData.gameId === WIDGET_GAME_ID.ZZZ) {
        // 绝区零：活跃度、刮刮卡
        const vitality = data['vitality'];
        if (vitality !== undefined && vitality !== null) {
          const vitalityObj = vitality as Record<string, Object>;
          gameData.vitalityStr = vitalityObj['current'] !== undefined ? String(vitalityObj['current']) : '0';
          gameData.vitalityMaxStr = vitalityObj['max'] !== undefined ? String(vitalityObj['max']) : '400';
        }
        gameData.cardSign = data['card_sign'] !== undefined ? String(data['card_sign']) : '';
      }
    } catch (_e) {
      // 解析失败保持默认值
    }
  }
}
