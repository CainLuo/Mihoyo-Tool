/**
 * ZZZPropsSection — 绝区零属性面板区
 *
 * 仅在 ZZZCharDetailContent 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ZZZCharacterDetailViewModel } from '../../../viewmodel/ZZZCharacterDetailViewModel';
import { CharDetailSectionLabel } from '../common/CharDetailSectionLabel';
import { ZZZCharDetailProperty } from '../../../models/CharDetailModels';

@ComponentV2
export struct ZZZPropsSection {
  @Param vm: ZZZCharacterDetailViewModel = new ZZZCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      CharDetailSectionLabel({ title: $r('app.string.zzz_char_detail_props_title') })

      Column() {
        ForEach(this.vm.properties, (prop: ZZZCharDetailProperty, idx: number) => {
          Row() {
            Text(prop.name)
              .fontSize(this.tm.current.font14)
              .fontColor('#80FFFFFF')
              .layoutWeight(1)

            Text(prop.final)
              .fontSize(this.tm.current.fontBold14)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.tm.current.textOnDarkHigh)
          }
          .width(this.tm.current.full)
          .padding({ left: this.tm.current.value12, right: this.tm.current.value12, top: this.tm.current.value8, bottom: this.tm.current.value8 })
          .border({ width: { bottom: idx < this.vm.properties.length - 1 ? this.tm.current.value1 : 0 }, color: '#1AFFFFFF' })
        }, (prop: ZZZCharDetailProperty, idx: number) => `prop_${idx}`)
      }
      .width(this.tm.current.full)
      .backgroundColor('#99000000')
      .border({ width: this.tm.current.value1, color: '#1AFFFFFF' })
      .borderRadius(this.tm.current.radius12)
      .alignItems(HorizontalAlign.Start)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}
