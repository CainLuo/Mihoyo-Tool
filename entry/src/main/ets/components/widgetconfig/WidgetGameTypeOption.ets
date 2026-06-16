/**
 * WidgetGameTypeOption — 游戏类型选项组件
 *
 * 用于 Widget 配置页的步骤 2（仅 1x2 卡片），展示可选的游戏类型。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { GameId } from 'core';
import { gameIdStrToLogo, gameIdStrToColor } from '../../utils/GameIdUtil';

/** 游戏类型配置 */
export interface GameTypeConfig {
  gameId: string;
  label: ResourceStr;
}

@ComponentV2
export struct WidgetGameTypeOption {
  @Local private tm: ThemeManager = themeManager;
  /** 游戏配置 */
  @Param config: GameTypeConfig = { gameId: GameId.GENSHIN, label: '' };
  /** 是否选中 */
  @Param isSelected: boolean = false;
  /** 该游戏的账号数量 */
  @Param accountCount: number = 0;
  /** 是否有数据 */
  @Param hasData: boolean = true;
  /** 点击回调 */
  @Param onTap: () => void = () => {};

  build() {
    Row() {
      // 左侧：游戏图标
      Image(gameIdStrToLogo(this.config.gameId))
        .width(this.tm.current.value40)
        .height(this.tm.current.value40)
        .borderRadius(this.tm.current.radius12)
        .objectFit(ImageFit.Cover)
        .opacity(this.hasData ? 1 : 0.3)

      // 中间：游戏名称 + 账号数量
      Column() {
        Text(this.config.label)
          .fontSize(this.tm.current.fontBold14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isSelected ? gameIdStrToColor(this.config.gameId) : this.tm.current.colorTextPrimary)

        Text($r('app.string.widget_game_account_count', this.accountCount))
          .fontSize(this.tm.current.font13)
          .fontColor(this.tm.current.colorTextSecondary)
          .margin({ top: this.tm.current.value2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: this.tm.current.value12 })

      // 右侧：选中状态
      if (this.isSelected) {
        Row() {
          Text('✓')
            .fontSize(this.tm.current.font13)
            .fontColor(Color.White)
        }
        .width(this.tm.current.font18)
        .height(this.tm.current.font18)
        .borderRadius(this.tm.current.value9)
        .backgroundColor(gameIdStrToColor(this.config.gameId))
        .justifyContent(FlexAlign.Center)
      }
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.font14)
    .backgroundColor(this.isSelected ? '#263A6FD8' : this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .border({
      width: this.tm.current.value2,
      color: this.isSelected ? gameIdStrToColor(this.config.gameId) : this.tm.current.colorDivider
    })
    .opacity(this.hasData ? 1 : 0.5)
    .onClick(() => {
      if (this.hasData) {
        this.onTap();
      }
    })
  }
}

@Preview
@ComponentV2
struct WidgetGameTypeOptionPreview {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value10 }) {
      WidgetGameTypeOption({
        config: { gameId: GameId.GENSHIN, label: $r('app.string.game_name_genshin') },
        isSelected: true,
        accountCount: 1,
        hasData: true
      })
      WidgetGameTypeOption({
        config: { gameId: GameId.STARRAIL, label: $r('app.string.game_name_starrail') },
        isSelected: false,
        accountCount: 0,
        hasData: false
      })
    }
    .padding(this.tm.current.font16)
    .backgroundColor('#1a1a2e')
  }
}
