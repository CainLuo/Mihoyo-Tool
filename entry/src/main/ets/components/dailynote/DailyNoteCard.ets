/**
 * DailyNoteCard — 通用便签行卡片
 *
 * 布局：[图标] [标题 + 副标题]  [右侧值/状态]
 *
 * 所有游戏的便签条目都基于此组件，差异通过 @BuilderParam slot 扩展。
 * 简单条目直接传 valueText；复杂内容（如每日委托格子）用 customBottom。
 *
 * 注意：@ComponentV2 中 @BuilderParam 不能赋默认值为 this.xxx，
 * 改用 hasCustomRight / hasCustomBottom 布尔标志控制是否渲染插槽。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager'

// ── Preview：简单文字值卡片 ──
@Preview
@ComponentV2
struct DailyNoteCardPreviewSimple {
  @Local private tm: ThemeManager = themeManager
  build() {
    Column({ space: 8 }) {
      DailyNoteCard({
        title: '原粹树脂',
        subtitle: '将于4小时后全部恢复',
        hasSubtitle: true,
        valueText: '140/200',
        hasValueText: true,
        valueColor: $r('app.color.color_warning'),
      })
      DailyNoteCard({
        title: '洞天宝钱',
        valueText: '2400/2400',
        hasValueText: true,
        valueColor: $r('app.color.color_danger'),
      })
      DailyNoteCard({
        title: '参量质变仪',
        subtitle: '已就绪',
        hasSubtitle: true,
        valueText: '可使用',
        hasValueText: true,
        valueColor: $r('app.color.color_primary'),
      })
    }
    .padding(16)
    .backgroundColor($r('app.color.color_page_bg'))
  }
}

@Builder
function emptyBuilder() {}

@ComponentV2
export struct DailyNoteCard {
  /** 左侧图标资源（传 $r('app.media.xxx')，为空则不渲染） */
  @Param icon: ResourceStr = ''
  /** 是否显示图标 */
  @Param hasIcon: boolean = false
  /** 主标题 */
  @Param title: ResourceStr = ''
  /** 副标题（可选，显示在标题下方） */
  @Param subtitle: ResourceStr = ''
  /** 是否显示副标题 */
  @Param hasSubtitle: boolean = false
  /** 右侧文字值（与 customRight 二选一） */
  @Param valueText: ResourceStr = ''
  /** 是否显示右侧文字值 */
  @Param hasValueText: boolean = false
  /** 右侧文字颜色（默认主文字色） */
  @Param valueColor: ResourceColor = ''
  /** 是否有右侧自定义插槽（传 true 时 customRight 生效） */
  @Param hasCustomRight: boolean = false
  /** 是否有底部自定义插槽（传 true 时 customBottom 生效） */
  @Param hasCustomBottom: boolean = false

  /** 右侧自定义内容插槽（需同时设置 hasCustomRight: true） */
  @BuilderParam customRight: () => void = emptyBuilder
  /** 标题下方自定义内容插槽（需同时设置 hasCustomBottom: true） */
  @BuilderParam customBottom: () => void = emptyBuilder

  @Local private tm: ThemeManager = themeManager

  build() {
    Column() {
      Row({ space: this.tm.current.value12 }) {
        // 左侧图标（有才渲染，无则不占位）
        if (this.hasIcon) {
          Image(this.icon)
            .width(this.tm.current.iconSizeSM)
            .height(this.tm.current.iconSizeSM)
            .borderRadius(this.tm.current.radius8)
        }

        // 中间：标题 + 副标题
        Column({ space: this.tm.current.value2 }) {
          Text(this.title)
            .font(this.tm.current.body16)
            .fontColor(this.tm.current.colorTextPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (this.hasSubtitle) {
            Text(this.subtitle)
              .font(this.tm.current.body13)
              .fontColor(this.tm.current.colorTextSecondary)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 右侧：valueText 或 customRight
        if (this.hasCustomRight) {
          this.customRight()
        } else if (this.hasValueText) {
          Text(this.valueText)
            .font(this.tm.current.body16Medium)
            .fontColor(this.valueColor !== '' ? this.valueColor : this.tm.current.colorTextPrimary)
            .maxLines(1)
        }
      }
      .width(this.tm.current.widthFull)
      .padding({
        left: this.tm.current.value16,
        right: this.tm.current.value16,
        top: this.tm.current.value12,
        bottom: this.tm.current.value12
      })
      .alignItems(VerticalAlign.Center)

      // 标题下方自定义区域（每日委托格子等）
      if (this.hasCustomBottom) {
        this.customBottom()
      }
    }
    .width(this.tm.current.widthFull)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
  }
}
