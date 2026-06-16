/**
 * StarRailEquipSection — 星铁光锥区（有光锥/无光锥两种状态）
 *
 * 仅在 StarRailCharDetailContent 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { StarRailCharacterDetailViewModel } from '../../../viewmodel/StarRailCharacterDetailViewModel';
import { CharDetailSectionLabel } from '../common/CharDetailSectionLabel';
import { StarRailEquipCard } from './StarRailEquipCard';

@ComponentV2
export struct StarRailEquipSection {
  @Param vm: StarRailCharacterDetailViewModel = new StarRailCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      CharDetailSectionLabel({ title: $r('app.string.starrail_char_detail_equip_title') })
      Column() {
        if (this.vm.equip !== null) {
          StarRailEquipCard({ equip: this.vm.equip })
        } else {
          Row({ space: this.tm.current.value8 }) {
            Column()
              .width(this.tm.current.value44)
              .height(this.tm.current.value44)
              .borderRadius(this.tm.current.value8)
              .backgroundColor(this.tm.current.surfaceDarkLg)
              .border({ width: this.tm.current.value1, color: this.tm.current.surfaceInactiveBorder, style: BorderStyle.Dashed })
            Text($r('app.string.starrail_char_detail_no_equip'))
              .fontSize(this.tm.current.font14)
              .fontColor(this.tm.current.textOnDarkMuted)
          }
          .width(this.tm.current.full)
          .padding(this.tm.current.value12)
          .alignItems(VerticalAlign.Center)
        }
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
