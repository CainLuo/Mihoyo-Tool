/**
 * StarRailPropsSection — 星铁属性面板区
 *
 * 仅在 StarRailCharDetailContent 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { StarRailCharacterDetailViewModel } from '../../../viewmodel/StarRailCharacterDetailViewModel';
import { CharDetailSectionLabel } from '../common/CharDetailSectionLabel';
import { StarRailCharDetailProperty } from '../../../models/CharDetailModels';

@ComponentV2
export struct StarRailPropsSection {
  @Param vm: StarRailCharacterDetailViewModel = new StarRailCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      CharDetailSectionLabel({ title: $r('app.string.starrail_char_detail_props_title') })
      Column() {
        ForEach(this.vm.properties, (prop: StarRailCharDetailProperty, idx: number) => {
          Row() {
            Text(prop.name)
              .fontSize(this.tm.current.font14)
              .fontColor(this.tm.current.textOnDarkSecondary)
              .layoutWeight(1)
            Text(prop.final)
              .fontSize(this.tm.current.fontBold14)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.tm.current.textOnDarkHigh)
          }
          .width(this.tm.current.full)
          .padding({ left: this.tm.current.value12, right: this.tm.current.value12, top: this.tm.current.value8, bottom: this.tm.current.value8 })
          .border({ width: { bottom: idx < this.vm.properties.length - 1 ? this.tm.current.value1 : 0 }, color: this.tm.current.surfaceGlass })
        }, (prop: StarRailCharDetailProperty, idx: number) => `prop_${idx}`)
      }
      .width(this.tm.current.full)
      .backgroundColor(this.tm.current.surfaceDarkLg)
      .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
      .borderRadius(this.tm.current.radius12)
      .alignItems(HorizontalAlign.Start)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}
