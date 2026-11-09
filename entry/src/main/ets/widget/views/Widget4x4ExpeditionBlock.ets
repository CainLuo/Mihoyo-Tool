/**
 * Widget4x4ExpeditionBlock.ets — 4×4 Widget 原神派遣角色头像区
 *
 * 纯圆头像图片，无背景色无 border；已完成的头像叠加黑色遮罩 + 右下角绿色勾勾。
 * flex:1，撑满剩余空间（仅原神且有派遣数据时渲染）。
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { ExpeditionAvatar, WidgetColors } from 'widgetbase';

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
            if (exp.isFinished) {
              Row()
                .width(32)
                .height(32)
                .borderRadius(16)
                .backgroundColor('rgba(0,0,0,0.5)')
            }

            // 已完成：右下角绿色勾勾（带黑色描边）
            if (exp.isFinished) {
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
