/**
 * WidgetSettingsGameStep — Widget 配置步骤 2（仅 1x2 卡片）：游戏类型选择
 */
import { ThemeManager, themeManager } from '../../theme/ThemeManager';
import { GameId } from 'core';
import { WidgetGameTypeOption, GameTypeConfig } from './WidgetGameTypeOption';

/** 游戏类型配置列表 */
const GAME_TYPE_CONFIGS: GameTypeConfig[] = [
  { gameId: GameId.GENSHIN, label: $r('app.string.game_name_genshin') },
  { gameId: GameId.STARRAIL, label: $r('app.string.game_name_starrail') },
  { gameId: GameId.ZZZ, label: $r('app.string.game_name_zzz') },
];

@ComponentV2
export struct WidgetSettingsGameStep {
  @Param selectedGameType: string = GameId.GENSHIN;
  @Param getSlotsForGame: (gameId: string) => object[] = (_gameId: string) => [];
  @Param hasDataForGame: (gameId: string) => boolean = (_gameId: string) => false;
  @Param onGameSelect: (gameId: string) => void = (_gameId: string) => {};

  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value10 }) {
      Text($r('app.string.widget_select_game_hint'))
        .fontSize(this.tm.current.font13)
        .fontColor(this.tm.current.colorTextSecondary)
        .width(this.tm.current.full)
        .margin({ bottom: this.tm.current.value8 })

      ForEach(GAME_TYPE_CONFIGS, (config: GameTypeConfig) => {
        WidgetGameTypeOption({
          config: config,
          isSelected: this.selectedGameType === config.gameId,
          accountCount: this.getSlotsForGame(config.gameId).length,
          hasData: this.hasDataForGame(config.gameId),
          onTap: () => { this.onGameSelect(config.gameId); }
        })
      }, (config: GameTypeConfig) => config.gameId)
    }
    .width(this.tm.current.full)
  }
}

@Preview
@ComponentV2
export struct WidgetSettingsGameStepPreview {
  @Local private tm: ThemeManager = themeManager;
  @Local private selectedGameType: string = GameId.GENSHIN;

  build() {
    Column() {
      WidgetSettingsGameStep({
        selectedGameType: this.selectedGameType,
        getSlotsForGame: () => [],
        hasDataForGame: () => true,
        onGameSelect: (gameId: string) => { this.selectedGameType = gameId; }
      })
    }
    .width(this.tm.current.value360)
    .padding(this.tm.current.font16)
    .backgroundColor('#1a1a2e')
  }
}
