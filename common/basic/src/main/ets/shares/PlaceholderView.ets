/**
 * PlaceholderView — 通用空态占位视图
 *
 * 用于展示各种空态场景，通过 PlaceholderState 控制标题、描述和按钮样式。
 * PlaceholderState 由各页面的 ViewModel 负责构建。
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager';
import { ThemeFonts } from '../theme/ThemeFonts';
import { PrimaryButtonModifier } from '../theme/PrimaryButtonModifier';

/**
 * 空态视图 UI State（纯数据）
 *
 * 调用方在 build() 中传入新的对象（{...} as PlaceholderState），刷新依赖父组件重建时传入新引用；
 * 不要就地修改已传入对象的字段，那不会触发刷新。
 */
export class PlaceholderState {
  /** 图标（emoji 字符串或 SF Symbol 名称如 'sys.symbol.wrench_and_screwdriver'） */
  icon: string = '🎮';
  /** 标题 */
  title: ResourceStr = '';
  /** 描述 */
  description: ResourceStr = '';
  /** 按钮文字（为空则不显示按钮） */
  buttonText: ResourceStr = '';
  /** 按钮点击回调 */
  onButtonTap: () => void = () => {};
  /** 按钮是否可点击（如刷新进行中时为 false，按钮置灰禁用，防止重复点击） */
  isButtonEnabled: boolean = true;
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
        .font(ThemeFonts.FONT_BOLD_18)
        .fontColor(this.tm.current.colorTextPrimary)
        .textAlign(TextAlign.Center)

      // 描述
      Text(this.state.description)
        .font(ThemeFonts.FONT_17)
        .fontColor(this.tm.current.colorTextSecondary)
        .textAlign(TextAlign.Center)
        .padding({ left: this.tm.current.value40, right: this.tm.current.value40 })

      // 按钮（可选）
      if (this.state.buttonText !== '') {
        Button(this.state.buttonText, { type: ButtonType.Normal })
          .attributeModifier(this.buttonModifier)
          .width(this.tm.current.pct90)
          // 与其他页面的禁用按钮一致：保持主按钮样式，由系统 enabled(false) 统一置灰（浅色 / 深色模式都可见）
          .enabled(this.state.isButtonEnabled)
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
