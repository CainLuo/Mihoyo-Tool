/**
 * Widget4x4SingleGame.ets — 4×4 单游戏垂直分块布局
 *
 * 布局策略：
 * - 顶部标题行：游戏名 + UID（固定高度）→ Widget4x4Header
 * - 区块1：体力区块（固定高度，由内容决定）→ Widget4x4StaminaBlock
 * - 区块2：数据行分组1（flex:1）→ Widget4x4ExtraRowsGroup
 * - 区块3：数据行分组2（flex:1）→ Widget4x4ExtraRowsGroup
 * - 区块4：原神派遣角色头像（flex:1，撑满剩余空间，仅原神）→ Widget4x4ExpeditionBlock
 *
 * 前几个区块根据内容自动伸缩高度，最后一个区块撑满剩余空间。
 * 分隔线作为区块的 border-bottom。
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { WidgetRoleUIState, WidgetExtraRow, WidgetGameId, WidgetColors,
  StaminaColorType, ExpeditionAvatar } from 'widgetbase';
import { Widget4x4Header } from './Widget4x4Header';
import { Widget4x4StaminaBlock } from './Widget4x4StaminaBlock';
import { Widget4x4ExtraRowsGroup } from './Widget4x4ExtraRowsGroup';
import { Widget4x4ExpeditionBlock } from './Widget4x4ExpeditionBlock';

@Component
export struct Widget4x4SingleGame {
  /** 角色 UIState（已解析好的数据） */
  @Prop role: WidgetRoleUIState = new WidgetRoleUIState();

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
    return this.role.gameId === WidgetGameId.GENSHIN && this.role.expeditions.length > 0;
  }

  build() {
    Column() {
      // ── 顶部标题行（固定高度，不参与 flex 分配）──
      Widget4x4Header({
        gameColor: this.role.gameColor,
        gameName: this.role.gameName,
        roleIdWithPrefix: this.role.roleIdWithPrefix
      })

      // ── 区块1：体力区块（固定高度，不参与 flex 分配）──
      Widget4x4StaminaBlock({ role: this.role })

      // ── 区块2：额外数据行分组1（flex:1，与分组2均分高度）──
      if (this.role.extraRows.length > 0) {
        Widget4x4ExtraRowsGroup({
          rows: this.getGroup1(),
          showBottomBorder: this.getGroup2().length > 0
        })
      }

      // ── 区块3：额外数据行分组2（flex:1，与分组1均分高度）──
      if (this.role.extraRows.length > 0 && this.getGroup2().length > 0) {
        Widget4x4ExtraRowsGroup({
          rows: this.getGroup2(),
          showBottomBorder: this.hasExpeditionBlock()
        })
      }

      // ── 区块4：原神派遣角色头像（flex:1，撑满剩余空间）──
      if (this.hasExpeditionBlock()) {
        Widget4x4ExpeditionBlock({ expeditions: this.role.expeditions })
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
    this.role.gameId = WidgetGameId.GENSHIN;
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
