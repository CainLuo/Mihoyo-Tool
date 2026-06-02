/**
 * ZZZWeaponSection — 绝区零音擎区（有音擎/无音擎两种状态）
 *
 * 仅在 ZZZCharDetailContent 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ZZZCharacterDetailViewModel } from '../../../viewmodel/ZZZCharacterDetailViewModel';
import { CharDetailSectionLabel } from '../common/CharDetailSectionLabel';
import { ZZZWeaponCard } from './ZZZWeaponCard';
import { TransparentColorCache } from '../../../utils/ColorUtil';

@ComponentV2
export struct ZZZWeaponSection {
  @Param vm: ZZZCharacterDetailViewModel = new ZZZCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      CharDetailSectionLabel({ title: $r('app.string.zzz_char_detail_weapon_title') })
      Column() {
        if (this.vm.weapon !== null) {
          ZZZWeaponCard({ weapon: this.vm.weapon })
        } else {
          Row({ space: this.tm.current.value8 }) {
            Column()
              .width(this.tm.current.value44)
              .height(this.tm.current.value44)
              .borderRadius(this.tm.current.value8)
              .backgroundColor(TransparentColorCache.blackWith60)
              .border({ width: this.tm.current.value1, color: TransparentColorCache.whiteWith10, style: BorderStyle.Dashed })

            Text($r('app.string.zzz_char_detail_no_weapon'))
              .fontSize(this.tm.current.font14)
              .fontColor(TransparentColorCache.whiteWith35)
          }
          .width(this.tm.current.full)
          .padding(this.tm.current.value12)
          .alignItems(VerticalAlign.Center)
        }
      }
      .width(this.tm.current.full)
      .backgroundColor(TransparentColorCache.blackWith60)
      .border({ width: this.tm.current.value1, color: TransparentColorCache.whiteWith10 })
      .borderRadius(this.tm.current.radius12)
      .alignItems(HorizontalAlign.Start)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}
