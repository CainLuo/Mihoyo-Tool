/**
 * Widget2x4SingleGame.ets — 2×4 单游戏水平布局
 *
 * 严格按原型 wr-2x4.js 单游戏分支实现：
 * - 左侧：游戏名（14fp）→ 角色名（12fp）→ UID（12fp）→ 体力数值（22fp）→ 恢复时间（12fp）
 * - 右侧：额外数据行（最多3条，原神去掉探索派遣）
 * - 底部（原神）：派遣角色头像（最多5个），已完成加 mask + 绿色勾勾
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 *
 * 重构说明：
 * - 所有数据通过 WidgetRoleUIState 传入，组件内部不做任何数据转换
 * - 组件只负责渲染，不包含业务逻辑
 * - 支持动态尺寸适配
 */

import {
  WidgetRoleUIState,
  WidgetExtraRow,
  StaminaColorType,
  WidgetColors,
  ExpeditionAvatar
} from '../models/WidgetUIStates';
import { WIDGET_GAME_ID, formatRecoveryTimeText, getStaminaColorByType } from '../utils/WidgetUtils';
import { DefaultTheme } from '../../theme/DefaultTheme';

@Component
export struct Widget2x4SingleGame {
  /** 角色 UIState（已解析好的数据） */
  @Prop role: WidgetRoleUIState = new WidgetRoleUIState();

  /** 是否在嵌套容器中（用于 4x4 多游戏模式，移除左右 margin） */
  @Prop inNestedContainer: boolean = false;

  /** 主题常量 */
  theme: DefaultTheme = new DefaultTheme();

  /** 获取体力颜色 */
  private getStaminaColor(): Resource {
    return getStaminaColorByType(this.role.staminaColorType, this.role.gameId);
  }

  build() {
    Column() {
      // ── 主体内容：左右两列 ──
      Row() {
        // ── 左侧：游戏名 → 角色名 → UID → 体力 → 恢复时间 ──
        // 原型：gap: 2px，体力区域 margin-top: 4px
        Column() {
          // 游戏名 14fp
          Text(this.role.gameName)
            .fontSize(14)
            .fontWeight(500)
            .fontColor(WidgetColors.WHITE)
            .opacity(WidgetColors.OPACITY_TEXT_MEDIUM)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 角色名 12fp（如果有）
          if (this.role.roleName.length > 0) {
            Text(this.role.roleName)
              .fontSize(12)
              .fontColor(WidgetColors.WHITE)
              .opacity(WidgetColors.OPACITY_TEXT_MUTED)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 2 })
          }

          // UID 12fp
          Text(this.role.roleIdWithPrefix)
            .fontSize(12)
            .fontColor(WidgetColors.WHITE)
            .opacity(WidgetColors.OPACITY_TEXT_GHOST)
            .maxLines(1)
            .margin({ top: 2 })

          // 体力数值 22fp（原型：margin-top: 4px）
          Row() {
            Text(this.role.currentStamina.toString())
              .fontSize(22)
              .fontWeight(700)
              .fontColor(this.getStaminaColor())

            Text('/' + this.role.maxStamina.toString())
              .fontSize(14)
              .fontColor(WidgetColors.WHITE)
              .opacity(WidgetColors.OPACITY_TEXT_GHOST)
              .margin({ left: 2 })
          }
          .alignItems(VerticalAlign.Bottom)
          .margin({ top: 4 })

          // 恢复时间 12fp（始终显示，满时显示"已满"）
          Text(formatRecoveryTimeText(this.role.recoveryTime))
            .fontSize(12)
            .fontColor(WidgetColors.WHITE)
            .opacity(WidgetColors.OPACITY_TEXT_FAINT)
            .maxLines(1)
            .margin({ top: 2 })
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start)
        .flexShrink(0)

        // 分隔线
        Row()
          .width(1)
          .height('50%')
          .backgroundColor(WidgetColors.WHITE)
          .opacity(0.08)
          .margin({ left: 12, right: 12 })

        // ── 右侧：额外数据行 ──
        // 数据已在 ViewModel 中按布局限制截取，组件只负责渲染
        Column({ space: 6 }) {
          ForEach(this.role.extraRows, (row: WidgetExtraRow) => {
            Row() {
              Text(row.labelResource)
                .fontSize(12)
                .fontColor(WidgetColors.WHITE)
                .opacity(WidgetColors.OPACITY_TEXT_FAINT)
                .layoutWeight(1)

              Text(row.displayValue)
                .fontSize(12)
                .fontWeight(600)
                .fontColor(row.valueColor)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
          })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)

      // ── 底部（原神）：派遣角色头像 ──
      // 原型：margin-top: 8px, padding-top: 8px, border-top: 1px solid rgba(255,255,255,.06)
      // 头像：纯圆图片，无背景色无 border
      // 已完成：头像 + 黑透遮罩 + 绿色勾勾（带黑色描边）
      // 进行中：只显示头像
      if (this.role.gameId === WIDGET_GAME_ID.GENSHIN && this.role.expeditions.length > 0) {
        Column() {
          // 分隔线（模拟 border-top）
          Row()
            .width('100%')
            .height(1)
            .backgroundColor(WidgetColors.WHITE)
            .opacity(0.06)

          // 派遣内容
          Row({ space: 4 }) {
            Text($r('app.string.widget_expedition'))
              .fontSize(10)
              .fontColor(WidgetColors.WHITE)
              .opacity(0.35)
              .margin({ right: 2 })

            ForEach(this.role.expeditions, (exp: ExpeditionAvatar, idx: number) => {
              // 每个头像容器
              Stack({ alignContent: Alignment.BottomEnd }) {
                // 头像（优先使用 memory:// 格式，否则显示渐变占位图）
                if (exp.memoryUrl.length > 0) {
                  Image(exp.memoryUrl)
                    .width(24)
                    .height(24)
                    .borderRadius(12)
                    .objectFit(ImageFit.Cover)
                } else if (exp.avatarUrl.length > 0) {
                  // 兜底：尝试网络图片（可能在 Form 环境中无法加载）
                  Image(exp.avatarUrl)
                    .width(24)
                    .height(24)
                    .borderRadius(12)
                    .objectFit(ImageFit.Cover)
                } else {
                  // 无 URL 时使用渐变色占位
                  Row()
                    .width(24)
                    .height(24)
                    .borderRadius(12)
                    .linearGradient({
                      angle: 135,
                      colors: [['rgba(100,100,120,0.8)', 0], ['rgba(60,60,80,0.8)', 1]]
                    })
                }

                // 已完成：黑透遮罩覆盖头像
                if (exp.finished) {
                  Row()
                    .width(24)
                    .height(24)
                    .borderRadius(12)
                    .backgroundColor('rgba(0,0,0,0.5)')
                }

                // 已完成：右下角绿色勾勾（带黑色描边）
                if (exp.finished) {
                  Row() {
                    Text('✓')
                      .fontSize(7)
                      .fontColor('#000000')
                      .fontWeight(700)
                  }
                  .width(10)
                  .height(10)
                  .borderRadius(5)
                  .backgroundColor('#34d399')
                  .justifyContent(FlexAlign.Center)
                  .alignItems(VerticalAlign.Center)
                  .margin({ bottom: -2, right: -2 })
                  .shadow({
                    radius: 1.5,
                    color: '#111118',
                    offsetX: 0,
                    offsetY: 0
                  })
                }
              }
              .width(24)
              .height(24)
            }, (exp: ExpeditionAvatar, idx: number) => `exp_${idx}`)
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .alignItems(VerticalAlign.Center)
          .margin({ top: 8 })
        }
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(this.inNestedContainer ? 0 : { left: 12, right: 12 })
  }
}

@Preview
@Component
struct Widget2x4SingleGamePreview {
  private role: WidgetRoleUIState = new WidgetRoleUIState();

  aboutToAppear(): void {
    this.role.gameId = WIDGET_GAME_ID.GENSHIN;
    this.role.gameName = '原神';
    this.role.gameColor = WidgetColors.GENSHIN_PRIMARY;
    this.role.roleId = '123456789';
    this.role.roleIdWithPrefix = 'UID 123456789';
    this.role.roleName = '旅行者 · Lv.60';
    this.role.currentStamina = 140;
    this.role.maxStamina = 160;
    this.role.recoveryTime.isFull = false;
    this.role.recoveryTime.hours = 4;
    this.role.recoveryTime.minutes = 30;
    this.role.staminaColorType = StaminaColorType.HIGH;

    // 添加派遣状态（Widget 不支持网络图片）
    const exp1 = new ExpeditionAvatar();
    exp1.finished = true;
    const exp2 = new ExpeditionAvatar();
    exp2.finished = true;
    const exp3 = new ExpeditionAvatar();
    exp3.finished = false;
    const exp4 = new ExpeditionAvatar();
    exp4.finished = false;
    const exp5 = new ExpeditionAvatar();
    exp5.finished = false;
    this.role.expeditions = [exp1, exp2, exp3, exp4, exp5];
  }

  build() {
    Column({ space: 12 }) {
      Widget2x4SingleGame({
        role: this.role
      })
        .width(316)
        .height(146)
        .padding(12)
        .linearGradient({ angle: 135, colors: [[$r('app.color.widget_bg_genshin_1'), 0], [$r('app.color.widget_bg_genshin_3'), 1]] })
        .borderRadius(16)
    }
    .padding(16)
    .backgroundColor($r('app.color.dark_400'))
  }
}
