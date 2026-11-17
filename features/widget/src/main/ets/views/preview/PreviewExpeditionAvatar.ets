/**
 * PreviewExpeditionAvatar.ets — Widget 配置预览派遣头像
 *
 * 渐变占位圆头像；completed 时叠加右下角绿色勾勾。
 * 2×4（24vp）与 4×4（32vp）预览共用。
 */

@ComponentV2
export struct PreviewExpeditionAvatar {
  /** 头像直径：2×4 用 24，4×4 用 32 */
  @Param avatarSize: number = 24;

  /** 是否已完成（显示绿色勾勾） */
  @Param completed: boolean = false;

  /** 完成勾勾直径 */
  private get badgeSize(): number {
    return this.avatarSize >= 32 ? 12 : 10;
  }

  /** 完成勾勾字号 */
  private get badgeFontSize(): number {
    return this.avatarSize >= 32 ? 8 : 7;
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Row()
        .width(this.avatarSize)
        .height(this.avatarSize)
        .borderRadius(this.avatarSize / 2)
        .linearGradient({
          angle: 135,
          colors: [['rgba(100,100,120,0.8)', 0], ['rgba(60,60,80,0.8)', 1]]
        })

      if (this.completed) {
        Row() {
          Text('✓')
            .fontSize(this.badgeFontSize)
            .fontColor('#000000')
            .fontWeight(700)
        }
        .width(this.badgeSize)
        .height(this.badgeSize)
        .borderRadius(this.badgeSize / 2)
        .backgroundColor('#34d399')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: -2, right: -2 })
      }
    }
    .width(this.avatarSize)
    .height(this.avatarSize)
  }
}
