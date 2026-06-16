/**
 * CharDetailHeroInfoOverlay — 立绘区左下角信息叠加层（原神通用）
 *
 * 显示角色名，底部通过 @BuilderParam 插入差异内容
 * （Portrait 插入好感值行，Landscape 插入好感标签+技能横行）。
 *
 * 布局样式由 mode 决定，调用方只传业务数据，不传样式参数。
 *
 * 使用方：CharDetailHeroPanelPortrait、CharDetailHeroPanelLandscape
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { GenshinElement } from '../../../constants/GenshinElement';
import { HeroPanelMode } from '../../../constants/HeroPanelMode';

@ComponentV2
export struct CharDetailHeroInfoOverlay {
  /** 角色名 */
  @Param charName: string = '';
  /** 元素（供调用方的 extraContent 使用好感颜色） */
  @Param charElement: GenshinElement = GenshinElement.UNKNOWN;
  /** 布局模式：决定字体大小和 padding */
  @Param mode: HeroPanelMode = HeroPanelMode.PORTRAIT;
  /** 底部差异内容（好感行 + 可选技能横行） */
  @BuilderParam extraContent: () => void = this.defaultExtraContent;
  @Local private tm: ThemeManager = themeManager;

  @Builder
  defaultExtraContent() {}

  /** 角色名字体大小：Portrait 较大，Landscape 较小 */
  private nameFontSize(): number {
    return this.mode === HeroPanelMode.LANDSCAPE
      ? this.tm.current.value15
      : this.tm.current.value22;
  }

  /** 左侧 padding：Landscape 贴边，Portrait 留出命座列宽度 */
  private paddingLeft(): number {
    return this.mode === HeroPanelMode.LANDSCAPE
      ? this.tm.current.value10
      : this.tm.current.value56;
  }

  /** 右侧 padding：Landscape 留出命座列，Portrait 留出立绘 */
  private paddingRight(): string {
    return this.mode === HeroPanelMode.LANDSCAPE
      ? this.tm.current.pct35
      : this.tm.current.pct40;
  }

  build() {
    Column({ space: this.tm.current.value4 }) {
      Text(this.charName)
        .fontSize(this.nameFontSize())
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tm.current.textOnDarkHigh)
        .textShadow({ radius: this.tm.current.value8, color: '#80000000', offsetY: 2 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      this.extraContent()
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.End)
    .padding({
      left: this.paddingLeft(),
      right: this.paddingRight(),
      bottom: this.tm.current.font24
    })
    .zIndex(2)
  }
}
