/**
 * Widget4x4SingleGame.ets — 4×4 单游戏垂直分块布局
 *
 * 布局策略：
 * - 顶部标题行：游戏名 + UID（固定高度）
 * - 区块1：体力区块（固定高度，由内容决定）
 * - 区块2：数据行分组1（固定高度，由内容决定）
 * - 区块3：数据行分组2（固定高度，由内容决定）
 * - 区块4：原神派遣角色头像（flex:1，撑满剩余空间，仅原神）
 *
 * 前几个区块根据内容自动伸缩高度，最后一个区块撑满剩余空间。
 * 分隔线作为区块的 border-bottom。
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import {
  WidgetRoleUIState,
  WidgetExtraRow,
  StaminaColorType,
  WidgetColors,
  ExpeditionAvatar
} from '../models/WidgetUIStates';
import { WIDGET_GAME_ID, formatRecoveryTimeText, getStaminaColorByType } from '../utils/WidgetUtils';

@Component
export struct Widget4x4SingleGame {
  /** 角色 UIState（已解析好的数据） */
  @Prop role: WidgetRoleUIState = new WidgetRoleUIState();

  /** 获取体力颜色 */
  private getStaminaColor(): Resource {
    return getStaminaColorByType(this.role.staminaColorType, this.role.gameId);
  }

  /** 获取体力标签文字 */
  private getStaminaLabel(): string {
    if (this.role.gameId === WIDGET_GAME_ID.STARRAIL) {
      return '开拓力';
    } else if (this.role.gameId === WIDGET_GAME_ID.ZZZ) {
      return '电量';
    }
    return '原粹树脂';
  }

  /** 获取分组1（前半部分） */
  private getGroup1(): WidgetExtraRow[] {
    const half = Math.ceil(this.role.extraRows.length / 2);
    return this.role.extraRows.slice(0, half);
  }

  /** 获取分组2（后半部分） */
  private getGroup2(): WidgetExtraRow[] {
    const half = Math.ceil(this.role.extraRows.length / 2);
    return this.role.extraRows.slice(half);
  }

  /** 是否显示派遣区块（原神 + 有派遣数据） */
  private hasExpeditionBlock(): boolean {
    return this.role.gameId === WIDGET_GAME_ID.GENSHIN && this.role.expeditions.length > 0;
  }

  build() {
    Column() {
      // ── 顶部标题行（固定高度，不参与 flex 分配）──
      Row() {
        // 游戏色圆点
        Row()
          .width(8)
          .height(8)
          .borderRadius(4)
          .backgroundColor(this.role.gameColor)

        // 游戏名
        Text(this.role.gameName)
          .fontSize(14)
          .fontWeight(700)
          .fontColor(WidgetColors.WHITE)
          .opacity(0.95)
          .layoutWeight(1)
          .margin({ left: 6 })

        // UID
        Text(this.role.roleIdWithPrefix)
          .fontSize(10)
          .fontColor(WidgetColors.WHITE)
          .opacity(0.35)
      }
      .width('100%')
      .padding({ bottom: 8 })

      // ── 区块1：体力区块（固定高度，不参与 flex 分配）──
      Column() {
        // 标签（10fp）
        Text(this.getStaminaLabel())
          .fontSize(10)
          .fontColor(WidgetColors.WHITE)
          .opacity(0.3)
          .margin({ bottom: 4 })

        // 数值行
        Row() {
          Text(this.role.currentStamina.toString())
            .fontSize(40)
            .fontWeight(700)
            .fontColor(this.getStaminaColor())

          Text('/ ' + this.role.maxStamina.toString())
            .fontSize(14)
            .fontColor(WidgetColors.WHITE)
            .opacity(0.3)
            .margin({ left: 4 })
        }
        .alignItems(VerticalAlign.Bottom)
        .margin({ bottom: 3 })

        // 恢复时间
        Text(formatRecoveryTimeText(this.role.recoveryTime))
          .fontSize(12)
          .fontColor(WidgetColors.WHITE)
          .opacity(0.5)

        // 星铁：后备开拓力
        if (this.role.gameId === WIDGET_GAME_ID.STARRAIL && this.role.reserveStamina.length > 0) {
          Row() {
            Text('后备开拓力')
              .fontSize(11)
              .fontColor(WidgetColors.WHITE)
              .opacity(0.35)

            Text(this.role.reserveStamina)
              .fontSize(13)
              .fontWeight(600)
              .fontColor(this.role.gameColor)
              .margin({ left: 6 })
          }
          .margin({ top: 3 })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)
      .padding({ top: 8, bottom: 8 })
      .border({ width: { bottom: 1 }, color: 'rgba(255,255,255,0.1)' })

      // ── 区块2：额外数据行分组1（flex:1，与分组2均分高度）──
      if (this.role.extraRows.length > 0) {
        Column() {
          ForEach(this.getGroup1(), (row: WidgetExtraRow) => {
            Row() {
              Text(row.labelResource)
                .fontSize(12)
                .fontColor(WidgetColors.WHITE)
                .opacity(0.45)
                .layoutWeight(1)

              Text(row.displayValue)
                .fontSize(12)
                .fontWeight(600)
                .fontColor(row.valueColor)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ top: 4, bottom: 4 })
          })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
        .padding({ top: 6, bottom: 6 })
        .border({ width: { bottom: this.getGroup2().length > 0 ? 1 : 0 }, color: 'rgba(255,255,255,0.1)' })
      }

      // ── 区块3：额外数据行分组2（flex:1，与分组1均分高度）──
      if (this.role.extraRows.length > 0 && this.getGroup2().length > 0) {
        Column() {
          ForEach(this.getGroup2(), (row: WidgetExtraRow) => {
            Row() {
              Text(row.labelResource)
                .fontSize(12)
                .fontColor(WidgetColors.WHITE)
                .opacity(0.45)
                .layoutWeight(1)

              Text(row.displayValue)
                .fontSize(12)
                .fontWeight(600)
                .fontColor(row.valueColor)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ top: 4, bottom: 4 })
          })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
        .padding({ top: 6, bottom: 6 })
        .border({ width: { bottom: this.hasExpeditionBlock() ? 1 : 0 }, color: 'rgba(255,255,255,0.1)' })
      }

      // ── 区块4：原神派遣角色头像（flex:1，撑满剩余空间）──
      // 原型：纯圆头像图片，无背景色无 border
      // 已完成：头像 + 右下角绿色圆圈勾勾（带黑色描边）
      // 进行中：只显示头像
      if (this.hasExpeditionBlock()) {
        Column() {
          Text('探索派遣')
            .fontSize(10)
            .fontColor(WidgetColors.WHITE)
            .opacity(0.3)
            .margin({ bottom: 6 })

          Row() {
            ForEach(this.role.expeditions, (exp: ExpeditionAvatar, idx: number) => {
              // 每个头像容器
              Stack({ alignContent: Alignment.BottomEnd }) {
                // 头像（优先使用 memory:// 格式，否则显示渐变占位图）
                if (exp.memoryUrl.length > 0) {
                  Image(exp.memoryUrl)
                    .width(32)
                    .height(32)
                    .borderRadius(16)
                    .objectFit(ImageFit.Cover)
                } else if (exp.avatarUrl.length > 0) {
                  // 兜底：尝试网络图片（可能在 Form 环境中无法加载）
                  Image(exp.avatarUrl)
                    .width(32)
                    .height(32)
                    .borderRadius(16)
                    .objectFit(ImageFit.Cover)
                } else {
                  // 无 URL 时使用渐变色占位
                  Row()
                    .width(32)
                    .height(32)
                    .borderRadius(16)
                    .linearGradient({
                      angle: 135,
                      colors: [['rgba(100,100,120,0.8)', 0], ['rgba(60,60,80,0.8)', 1]]
                    })
                }

                // 已完成：黑透遮罩覆盖头像
                if (exp.finished) {
                  Row()
                    .width(32)
                    .height(32)
                    .borderRadius(16)
                    .backgroundColor('rgba(0,0,0,0.5)')
                }

                // 已完成：右下角绿色勾勾（带黑色描边）
                if (exp.finished) {
                  Row() {
                    Text('✓')
                      .fontSize(8)
                      .fontColor('#000000')
                      .fontWeight(700)
                  }
                  .width(12)
                  .height(12)
                  .borderRadius(6)
                  .backgroundColor('#34d399')
                  .justifyContent(FlexAlign.Center)
                  .alignItems(VerticalAlign.Center)
                  .margin({ bottom: -2, right: -2 })
                  .shadow({
                    radius: 2,
                    color: '#111118',
                    offsetX: 0,
                    offsetY: 0
                  })
                }
              }
              .width(32)
              .height(32)
            }, (exp: ExpeditionAvatar, idx: number) => `exp_${idx}`)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceEvenly)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start)
        .padding({ top: 6, bottom: 6 })
      }
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

@Preview
@Component
struct Widget4x4SingleGamePreview {
  private role: WidgetRoleUIState = new WidgetRoleUIState();

  aboutToAppear(): void {
    this.role.gameId = WIDGET_GAME_ID.GENSHIN;
    this.role.gameName = '原神';
    this.role.gameColor = WidgetColors.GENSHIN_PRIMARY;
    this.role.roleId = '123456789';
    this.role.roleIdWithPrefix = 'UID 123456789';
    this.role.currentStamina = 140;
    this.role.maxStamina = 160;
    this.role.recoveryTime.isFull = false;
    this.role.recoveryTime.hours = 4;
    this.role.recoveryTime.minutes = 30;
    this.role.staminaColorType = StaminaColorType.HIGH;

    // 添加派遣头像（Widget 不支持网络图片，用占位符代替）
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
      Widget4x4SingleGame({
        role: this.role
      })
        .width(290)
        .height(309)
        .padding(12)
        .linearGradient({ angle: 135, colors: [[$r('app.color.widget_bg_genshin_1'), 0], [$r('app.color.widget_bg_genshin_3'), 1]] })
        .borderRadius(16)
    }
    .padding(16)
    .backgroundColor($r('app.color.dark_400'))
  }
}
