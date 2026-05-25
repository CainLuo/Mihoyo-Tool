/**
 * CharDetailHeroNameOverlay — 立绘区左下角名字+等级信息叠加层（星铁/绝区零通用）
 *
 * 显示角色名，底部通过 @BuilderParam 插入差异内容
 * （星铁插入等级+星魂行，绝区零插入全名+等级+稀有度+影画数行）。
 *
 * 使用方：StarRailCharDetailHero、ZZZCharDetailHero
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';

@ComponentV2
export struct CharDetailHeroNameOverlay {
  /** 角色名 */
  @Param charName: string = '';
  /** 底部差异内容 */
  @BuilderParam extraContent: () => void = this.defaultExtraContent;
  @Local private tm: ThemeManager = themeManager;

  @Builder
  defaultExtraContent() {}

  build() {
    Column({ space: this.tm.current.value4 }) {
      Text(this.charName)
        .fontSize(this.tm.current.value22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tm.current.textOnDarkHigh)
        .textShadow({ radius: this.tm.current.value8, color: this.tm.current.overlayShadow, offsetY: 2 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      this.extraContent()
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.End)
    .padding({ left: this.tm.current.value56, right: this.tm.current.pct40, bottom: this.tm.current.font24 })
    .zIndex(2)
  }
}
