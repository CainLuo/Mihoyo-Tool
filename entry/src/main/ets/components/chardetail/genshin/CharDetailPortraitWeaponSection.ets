/**
 * CharDetailPortraitWeaponSection — 武器区 Section
 *
 * Phone 竖屏布局的武器区块，包含标题和武器卡片或空态占位。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { GenshinCharacterDetailViewModel } from '../../../viewmodel/GenshinCharacterDetailViewModel';
import { CharDetailSectionLabel } from '../common/CharDetailSectionLabel';
import { CharDetailPortraitWeaponCard } from './CharDetailPortraitWeaponCard';

@ComponentV2
export struct CharDetailPortraitWeaponSection {
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      CharDetailSectionLabel({ title: $r('app.string.char_detail_section_weapon') })

      if (this.vm.weapon.name !== '') {
        CharDetailPortraitWeaponCard({ weapon: this.vm.weapon })
      } else {
        Row({ space: this.tm.current.value8 }) {
          SymbolGlyph($r('sys.symbol.lock'))
            .fontSize(this.tm.current.font16)
            .fontColor([this.tm.current.textOnDarkMuted])

          Text($r('app.string.char_detail_no_weapon'))
            .fontSize(this.tm.current.font14)
            .fontColor(this.tm.current.textOnDarkMuted)
        }
        .width(this.tm.current.full)
        .height(this.tm.current.value56)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .backgroundColor(this.tm.current.surfaceDarkLg)
        .border({ width: this.tm.current.value1, color: this.tm.current.surfaceInactiveBorder, style: BorderStyle.Dashed })
        .borderRadius(this.tm.current.radius12)
      }
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}
