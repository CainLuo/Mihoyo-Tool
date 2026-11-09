/**
 * WidgetExpeditionAvatar.ets — Widget 派遣角色头像（单枚）
 *
 * 纯圆头像，无背景色无 border；已完成叠加黑色遮罩 + 右下角绿色勾勾。
 * 2×4（24vp）与 4×4（32vp）卡片共用，勾勾尺寸 / 字号 / 阴影按头像尺寸派生。
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { ExpeditionAvatar } from 'widgetbase';

@Component
export struct WidgetExpeditionAvatar {
  /** 派遣角色数据 */
  @Prop exp: ExpeditionAvatar = new ExpeditionAvatar();

  /** 头像直径：2×4 用 24，4×4 用 32（不能命名为 size，会与通用属性冲突） */
  avatarSize: number = 24;

  /** 完成勾勾直径 */
  private get badgeSize(): number {
    return this.avatarSize >= 32 ? 12 : 10;
  }

  /** 完成勾勾字号 */
  private get badgeFontSize(): number {
    return this.avatarSize >= 32 ? 8 : 7;
  }

  /** 完成勾勾描边半径 */
  private get badgeShadowRadius(): number {
    return this.avatarSize >= 32 ? 2 : 1.5;
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // 头像（优先使用 memory:// 格式，否则显示渐变占位图）
      if (this.exp.memoryUrl.length > 0) {
        Image(this.exp.memoryUrl)
          .width(this.avatarSize)
          .height(this.avatarSize)
          .borderRadius(this.avatarSize / 2)
          .objectFit(ImageFit.Cover)
      } else if (this.exp.avatarUrl.length > 0) {
        // 兜底：尝试网络图片（可能在 Form 环境中无法加载）
        Image(this.exp.avatarUrl)
          .width(this.avatarSize)
          .height(this.avatarSize)
          .borderRadius(this.avatarSize / 2)
          .objectFit(ImageFit.Cover)
      } else {
        // 无 URL 时使用渐变色占位
        Row()
          .width(this.avatarSize)
          .height(this.avatarSize)
          .borderRadius(this.avatarSize / 2)
          .linearGradient({
            angle: 135,
            colors: [['rgba(100,100,120,0.8)', 0], ['rgba(60,60,80,0.8)', 1]]
          })
      }

      // 已完成：黑透遮罩覆盖头像
      if (this.exp.isFinished) {
        Row()
          .width(this.avatarSize)
          .height(this.avatarSize)
          .borderRadius(this.avatarSize / 2)
          .backgroundColor('rgba(0,0,0,0.5)')
      }

      // 已完成：右下角绿色勾勾（带黑色描边）
      if (this.exp.isFinished) {
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
        .shadow({
          radius: this.badgeShadowRadius,
          color: '#111118',
          offsetX: 0,
          offsetY: 0
        })
      }
    }
    .width(this.avatarSize)
    .height(this.avatarSize)
  }
}

@Preview
@Component
struct WidgetExpeditionAvatarPreview {
  private finished: ExpeditionAvatar = new ExpeditionAvatar();
  private ongoing: ExpeditionAvatar = new ExpeditionAvatar();

  aboutToAppear(): void {
    this.finished.isFinished = true;
    this.ongoing.isFinished = false;
  }

  build() {
    Column({ space: 16 }) {
      Row({ space: 8 }) {
        WidgetExpeditionAvatar({ exp: this.finished, avatarSize: 32 })
        WidgetExpeditionAvatar({ exp: this.ongoing, avatarSize: 32 })
      }

      Row({ space: 4 }) {
        WidgetExpeditionAvatar({ exp: this.finished, avatarSize: 24 })
        WidgetExpeditionAvatar({ exp: this.ongoing, avatarSize: 24 })
      }
    }
    .padding(16)
    .backgroundColor($r('app.color.dark_400'))
  }
}
