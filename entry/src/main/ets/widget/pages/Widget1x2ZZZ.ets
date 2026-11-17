/**
 * Widget1x2ZZZ.ets — 绝区零 1×2 迷你卡片
 *
 * v1.1 设计：
 * - 使用单一 @LocalStorageProp('payload') 接收完整 JSON
 * - 通过 ViewModel 构建 UIState
 * - 游戏主题色渐变背景
 *
 * 注意：
 * - Widget Form 不支持 union 类型，使用默认对象而非 null
 * - Widget 使用 @Component（V1 体系），不能使用 @ObservedV2/@Trace
 * - Widget build() 方法中不能声明局部变量，必须使用组件方法
 *
 * MVVM 数据流：
 *   payload JSON → parsePayload() → ParsedPayload → Widget1x2ViewModel.buildUIState() → UIState → Component
 */

import { Widget1x2ContentView } from '../views/Widget1x2ContentView';
import { WidgetEmptyContent } from '../views/WidgetEmptyContent';
import { parsePayload, Widget1x2UIState, createSingleGameGradient, WidgetGameId, getGameColor, DefaultTheme } from 'widgetbase';
import { Widget1x2ViewModel } from '../viewmodel/Widget1x2ViewModel';

/** 主题常量实例（Widget 直接使用，不依赖 @ObservedV2/@Trace） */
const theme = new DefaultTheme();

let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct Widget1x2ZZZ {
  @LocalStorageProp('payload') payloadJson: string = '';

  /**
   * 性能优化：同一 payload 字符串只解析/构建一次 UIState。
   * build() 中会多次读取 UIState，缓存后避免重复 JSON.parse + ViewModel 计算。
   */
  private cachedPayloadJson: string = '';
  private cachedUIState: Widget1x2UIState =
    Widget1x2ViewModel.buildUIState(parsePayload(''), WidgetGameId.ZZZ);

  /** payload 变化时重建缓存，未变化时直接复用 */
  private ensureCache(): void {
    if (this.cachedPayloadJson === this.payloadJson) {
      return;
    }
    this.cachedPayloadJson = this.payloadJson;
    this.cachedUIState = Widget1x2ViewModel.buildUIState(parsePayload(this.payloadJson), WidgetGameId.ZZZ);
  }

  /** 构建 UIState（在组件方法中调用 ViewModel） */
  private getUIState(): Widget1x2UIState {
    this.ensureCache();
    return this.cachedUIState;
  }

  build() {
    Column() {
      if (this.getUIState().isEmpty) {
        WidgetEmptyContent()
      } else {
        Widget1x2ContentView({
          state: this.getUIState().role,
          gameColor: getGameColor(WidgetGameId.ZZZ)
        })
      }
    }
    .width(theme.full)
    .height(theme.full)
    .padding({
      left: theme.value12,
      right: theme.value12
    })
    .linearGradient(createSingleGameGradient(WidgetGameId.ZZZ))
    .borderRadius(theme.radius16)
    .onClick(() => {
      postCardAction(this, {
        action: 'call',
        abilityName: 'WidgetSyncAbility',
        params: {
          method: 'sync'
        }
      });
    })
  }
}

@Preview
@Component
struct Widget1x2ZZZPreview {
  build() {
    Column({ space: 12 }) {
      Widget1x2ZZZ()
        .width(168)
        .height(80)
    }
    .padding(16)
    .backgroundColor($r('app.color.widget_bg'))
  }
}
