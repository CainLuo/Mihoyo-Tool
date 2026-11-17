/**
 * Widget4x4ExpeditionBlock.ets — 4×4 Widget 原神派遣角色头像区
 *
 * 纯圆头像图片，无背景色无 border；已完成的头像叠加黑色遮罩 + 右下角绿色勾勾。
 * flex:1，撑满剩余空间（仅原神且有派遣数据时渲染）。
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { ExpeditionAvatar, WidgetColors } from 'widgetbase';
import { WidgetExpeditionAvatar } from './WidgetExpeditionAvatar';

@Component
export struct Widget4x4ExpeditionBlock {
  /** 派遣角色头像列表 */
  @Prop expeditions: ExpeditionAvatar[] = [];

  build() {
    Column() {
      Text('探索派遣')
        .fontSize(10)
        .fontColor(WidgetColors.WHITE)
        .opacity(0.3)
        .margin({ bottom: 6 })

      Row() {
        ForEach(this.expeditions, (exp: ExpeditionAvatar, idx: number) => {
          WidgetExpeditionAvatar({ exp: exp, avatarSize: 32 })
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

@Preview
@Component
struct Widget4x4ExpeditionBlockPreview {
  private expeditions: ExpeditionAvatar[] = [];

  aboutToAppear(): void {
    const exp1 = new ExpeditionAvatar();
    exp1.isFinished = true;
    const exp2 = new ExpeditionAvatar();
    exp2.isFinished = false;
    const exp3 = new ExpeditionAvatar();
    exp3.isFinished = true;
    this.expeditions = [exp1, exp2, exp3];
  }

  build() {
    Column() {
      Widget4x4ExpeditionBlock({ expeditions: this.expeditions })
    }
    .padding(16)
    .backgroundColor($r('app.color.dark_400'))
  }
}
