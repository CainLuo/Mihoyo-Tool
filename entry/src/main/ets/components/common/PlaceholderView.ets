/**
 * PlaceholderView — 通用空态占位视图
 *
 * 用于展示各种空态场景，通过 PlaceholderState 控制标题、描述和按钮样式。
 * PlaceholderState 由各页面的 ViewModel 负责构建。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { ThemeFonts } from '../../theme/ThemeFonts';
import { PrimaryButtonModifier } from '../../styles/ButtonModifier';

/** 空态视图 UI State */
@ObservedV2
export class PlaceholderState {
  /** 图标（emoji 字符串或 SF Symbol 名称如 'sys.symbol.wrench_and_screwdriver'） */
  @Trace icon: string = '🎮';
  /** 标题 */
  @Trace title: ResourceStr = '';
  /** 描述 */
  @Trace description: ResourceStr = '';
  /** 按钮文字（为空则不显示按钮） */
  @Trace buttonText: ResourceStr = '';
  /** 按钮点击回调 */
  @Trace onButtonTap: () => void = () => {};
}

@ComponentV2
export struct PlaceholderView {
  @Param state: PlaceholderState = new PlaceholderState();
  @Local private tm: ThemeManager = themeManager;
  @Local private buttonModifier: PrimaryButtonModifier = new PrimaryButtonModifier(true);

  build() {
    Column({ space: this.tm.current.font20 }) {
      // 图标 — 判断是否为 SF Symbol
      if (this.state.icon.startsWith('sys.symbol.')) {
        SymbolGlyph($r(this.state.icon))
          .fontSize(this.tm.current.value64)
          .fontColor([this.tm.current.colorTextSecondary])
      } else {
        Text(this.state.icon)
          .fontSize(this.tm.current.value64)
      }

      // 标题
      Text(this.state.title)
        .font(ThemeFonts.fontBold18)
        .fontColor(this.tm.current.colorTextPrimary)
        .textAlign(TextAlign.Center)

      // 描述
      Text(this.state.description)
        .font(ThemeFonts.font17)
        .fontColor(this.tm.current.colorTextSecondary)
        .textAlign(TextAlign.Center)
        .padding({ left: this.tm.current.value40, right: this.tm.current.value40 })

      // 按钮（可选）
      if (this.state.buttonText !== '') {
        Button(this.state.buttonText, { type: ButtonType.Normal })
          .attributeModifier(this.buttonModifier)
          .width(this.tm.current.pct90)
          .onClick(() => {
            this.state.onButtonTap();
          })
      }
    }
    .width(this.tm.current.full)
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct PlaceholderViewPreview {
  @Local private noAccountState: PlaceholderState = new PlaceholderState();
  @Local private materialEmptyState: PlaceholderState = new PlaceholderState();

  aboutToAppear(): void {
    // 无账号场景
    this.noAccountState.icon = '🎮';
    this.noAccountState.title = $r('app.string.home_placeholder_title');
    this.noAccountState.description = $r('app.string.home_placeholder_desc');
    this.noAccountState.buttonText = $r('app.string.home_placeholder_button');

    // 材料空态场景
    this.materialEmptyState.icon = '📦';
    this.materialEmptyState.title = $r('app.string.material_list_empty_title');
    this.materialEmptyState.description = $r('app.string.material_list_empty_desc');
    this.materialEmptyState.buttonText = $r('app.string.material_list_empty_button');
  }

  build() {
    Column({ space: 24 }) {
      PlaceholderView({ state: this.noAccountState })
      PlaceholderView({ state: this.materialEmptyState })
    }
    .width('100%')
    .height(800)
    .backgroundColor('#1a1a2e')
  }
}
