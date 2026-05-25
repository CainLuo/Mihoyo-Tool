/**
 * GameStaminaBlock — 游戏主体力区块（大数字 + 环形进度 + 恢复描述）
 *
 * 四个游戏战绩卡片共用的顶部主数值展示区。
 * 使用方：GameToolCardContent
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { ThemeFonts } from '../../theme/ThemeFonts'
import { TimeFormatUtil } from '../../utils/TimeFormatUtil';

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct GameStaminaBlockPreview {
  build() {
    Column({ space: themeManager.current.value16 }) {
      GameStaminaBlock({
        label: $r('app.string.daily_note_resin_title'),
        current: 152,
        max: 200,
        recoverySeconds: 22800,
        primaryColor: $r('app.color.color_primary'),
        progressRatio: 0.76
      })

      GameStaminaBlock({
        label: $r('app.string.starrail_stamina_title'),
        current: 300,
        max: 300,
        recoverySeconds: 0,
        primaryColor: $r('app.color.color_primary'),
        progressRatio: 1.0
      })
    }
    .padding(themeManager.current.value16)
    .backgroundColor('#1a1a2e')
  }
}

@ComponentV2
export struct GameStaminaBlock {
  /** 主体力标签（树脂/开拓力/电量等） */
  @Param label: ResourceStr = '';
  /** 当前值 */
  @Param current: number = 0;
  /** 最大值 */
  @Param max: number = 0;
  /** 恢复剩余秒数（0 表示已满或无需显示） */
  @Param recoverySeconds: number = 0;
  /** 恢复描述文字颜色（满时用 colorDanger，否则用 colorTextSecondary） */
  @Param recoveryColor: ResourceColor = '';
  /** 主色（数字颜色 + 进度条颜色） */
  @Param primaryColor: ResourceColor = $r('app.color.color_primary');
  /** 进度比例（0~1） */
  @Param progressRatio: number = 0;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Row({ space: this.tm.current.value10 }) {
      Column({ space: this.tm.current.value2 }) {
        Text(this.label)
          .font(ThemeFonts.font14)
          .fontColor(this.tm.current.colorTextSecondary)

        Row({ space: this.tm.current.value4 }) {
          Text(this.current.toString())
            .font(ThemeFonts.fontBold24)
            .fontColor(this.primaryColor)

          Text('/' + this.max.toString())
            .font(ThemeFonts.font17)
            .fontColor(this.tm.current.colorTextSecondary)
            .alignSelf(ItemAlign.End)
            .margin({ bottom: this.tm.current.value2 })
        }
        .alignItems(VerticalAlign.Bottom)

        if (this.recoverySeconds > 0) {
          Text(TimeFormatUtil.recoveryDesc(this.recoverySeconds, this.getUIContext()))
            .font(ThemeFonts.font14)
            .fontColor(this.recoveryColor !== '' ? this.recoveryColor : this.tm.current.colorTextSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Progress({
        value: Math.round(this.progressRatio * 100),
        total: 100,
        type: ProgressType.Ring
      })
        .width(this.tm.current.value52)
        .height(this.tm.current.value52)
        .color(this.primaryColor)
        .backgroundColor(this.tm.current.colorDivider)
        .style({ strokeWidth: this.tm.current.value5 })
    }
    .width(this.tm.current.full)
    .alignItems(VerticalAlign.Center)
  }
}
