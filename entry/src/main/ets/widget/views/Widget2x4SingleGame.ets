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

import { WidgetRoleUIState, WidgetExtraRow, StaminaColorType, WidgetColors, ExpeditionAvatar, WidgetGameId, DefaultTheme } from 'widgetbase';
import { Widget2x4InfoColumn } from './Widget2x4InfoColumn';
import { WidgetDataRow } from './WidgetDataRow';
import { WidgetExpeditionAvatar } from './WidgetExpeditionAvatar';

@Component
export struct Widget2x4SingleGame {
  /** 角色 UIState（已解析好的数据） */
  @Prop role: WidgetRoleUIState = new WidgetRoleUIState();

  /** 是否在嵌套容器中（用于 4x4 多游戏模式，移除左右 margin） */
  @Prop isInNestedContainer: boolean = false;

  /** 主题常量 */
  theme: DefaultTheme = new DefaultTheme();

  build() {
    Column() {
      // ── 主体内容：左右两列 ──
      Row() {
        // ── 左侧：游戏名 → 角色名 → UID → 体力 → 恢复时间 ──
        Widget2x4InfoColumn({ role: this.role })

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
            WidgetDataRow({
              row: row,
              fontSize: 12,
              labelOpacity: WidgetColors.OPACITY_TEXT_FAINT,
              valueFontWeight: 600
            })
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
      if (this.role.gameId === WidgetGameId.GENSHIN && this.role.expeditions.length > 0) {
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
              WidgetExpeditionAvatar({ exp: exp, avatarSize: 24 })
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
    .padding(this.isInNestedContainer ? 0 : { left: 12, right: 12 })
  }
}

@Preview
@Component
struct Widget2x4SingleGamePreview {
  private role: WidgetRoleUIState = new WidgetRoleUIState();

  aboutToAppear(): void {
    this.role.gameId = WidgetGameId.GENSHIN;
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
    exp1.isFinished = true;
    const exp2 = new ExpeditionAvatar();
    exp2.isFinished = true;
    const exp3 = new ExpeditionAvatar();
    exp3.isFinished = false;
    const exp4 = new ExpeditionAvatar();
    exp4.isFinished = false;
    const exp5 = new ExpeditionAvatar();
    exp5.isFinished = false;
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
