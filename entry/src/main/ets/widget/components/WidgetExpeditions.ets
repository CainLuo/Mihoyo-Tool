/**
 * WidgetExpeditions.ets — 原神探索派遣头像行组件
 *
 * 显示最多 5 个派遣格子，已完成的显示 ✓ 标记。
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';


@Component
export struct WidgetExpeditions {
  private tm: ThemeManager = themeManager;
  /** 派遣总数 */
  expeditionMax: string = '5';
  /** 各派遣完成状态，逗号分隔的 'true'/'false' 字符串 */
  expeditionFinishedFlags: string = '';

  private buildIndices(): number[] {
    const count = parseInt(this.expeditionMax) || 5;
    const result: number[] = [];
    for (let i = 0; i < count; i++) {
      result.push(i);
    }
    return result;
  }

  private isFinished(idx: number): boolean {
    if (this.expeditionFinishedFlags.length === 0) {
      return false;
    }
    const flags = this.expeditionFinishedFlags.split(',');
    return idx < flags.length && flags[idx] === 'true';
  }

  build() {
    Column({ space: themeManager.current.value8 }) {
      Text($r('app.string.widget_expedition'))
        .fontSize(themeManager.current.value14)
        .fontColor($r('app.color.text_on_dark_secondary'))

      Row() {
        ForEach(this.buildIndices(), (_: number, idx: number) => {
          Stack() {
            Circle()
              .width(this.tm.current.value36)
              .height(this.tm.current.value36)
              .fill($r('app.color.surface_inactive_border'))
              .stroke($r('app.color.game_color_genshin'))
              .strokeWidth(themeManager.current.value2)

            Text('👤')
              .fontSize(themeManager.current.value16)

            if (this.isFinished(idx)) {
              Text('✓')
                .fontSize(themeManager.current.value11)
                .fontColor($r('app.color.text_on_dark_high'))
                .backgroundColor($r('app.color.game_color_genshin'))
                .borderRadius(this.tm.current.value8)
                .width(this.tm.current.value14)
                .height(this.tm.current.value14)
                .textAlign(TextAlign.Center)
                .position({ x: themeManager.current.value22, y: themeManager.current.value22 })
            }
          }
          .width(this.tm.current.value36)
          .height(this.tm.current.value36)
          .layoutWeight(1)
        }, (idx: number) => String(idx))
      }
      .width(this.tm.current.full)
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width(this.tm.current.full)
    .margin({ top: this.tm.current.value8 })
    .flexShrink(0)
  }
}

@Preview
@Component
struct WidgetExpeditionsPreview {
  build() {
    Column() {
      WidgetExpeditions({
        expeditionMax: '5',
        expeditionFinishedFlags: 'true,false,true,false,true'
      })
    }
    .padding(16)
    .width(200)
    .backgroundColor('#1a1a2e')
  }
}
