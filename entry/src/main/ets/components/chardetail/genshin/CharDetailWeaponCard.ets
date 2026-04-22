/**
 * CharDetailWeaponCard — 原神武器卡片（宽屏样式）
 *
 * 图标 + 名称 + 精炼/等级 + 副词条 + 星级行。
 * 仅在 CharDetailStatsPanel 宽屏模式下使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { CharDetailWeapon } from '../../../models/CharDetailModels';
import { GenshinElement, elementColor } from '../../../constants/GenshinElement';

@ComponentV2
export struct CharDetailWeaponCard {
  @Param weapon: CharDetailWeapon = new CharDetailWeapon();
  @Param charElement: GenshinElement = GenshinElement.UNKNOWN;
  @Local private tm: ThemeManager = themeManager;

  private starsText(n: number): string {
    let s = '';
    for (let i = 0; i < n; i++) { s += '★'; }
    return s;
  }

  build() {
    Column({ space: this.tm.current.value8 }) {
      Row({ space: this.tm.current.value10 }) {
        if (this.weapon.iconUrl !== '') {
          Image(this.weapon.iconUrl)
            .width(this.tm.current.value52)
            .height(this.tm.current.value52)
            .objectFit(ImageFit.Contain)
            .borderRadius(this.tm.current.value8)
            .backgroundColor(this.tm.current.surfaceGlass)
        } else {
          Column()
            .width(this.tm.current.value52)
            .height(this.tm.current.value52)
            .borderRadius(this.tm.current.value8)
            .backgroundColor(this.tm.current.surfaceGlass)
        }
        Column({ space: this.tm.current.value4 }) {
          Text(this.weapon.name)
            .fontSize(this.tm.current.body13Bold.size)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.tm.current.textOnDarkHigh)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Row({ space: this.tm.current.value8 }) {
            Text($r('app.string.char_detail_weapon_refine_prefix', this.weapon.affix))
              .fontSize(this.tm.current.body10.size)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.tm.current.accentRefine)
              .backgroundColor(this.tm.current.accentRefineBg)
              .borderRadius(this.tm.current.value4)
              .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
            Text($r('app.string.char_detail_weapon_lv_prefix', this.weapon.level))
              .fontSize(this.tm.current.body10.size)
              .fontColor(this.tm.current.textOnDarkMuted)
          }
          if (this.weapon.subLabel !== null) {
            Row({ space: this.tm.current.value4 }) {
              Text(this.weapon.subLabel)
                .fontSize(this.tm.current.body12.size)
                .fontColor(this.tm.current.textOnDarkMuted)
              Text(this.weapon.subVal)
                .fontSize(this.tm.current.body12.size)
                .fontColor(elementColor(this.charElement))
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width(this.tm.current.full)
      .alignItems(VerticalAlign.Center)

      // 星级
      Row({ space: 1 }) {
        ForEach(this.buildStarArray(this.weapon.rarity), (_: number, idx: number) => {
          Text('★')
            .fontSize(this.tm.current.body12.size)
            .fontColor(this.tm.current.accentRefine)
        }, (_: number, idx: number) => `star_${idx}`)
      }
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value12)
    .backgroundColor(this.tm.current.surfaceGlass)
    .border({ width: { bottom: this.tm.current.value1 }, color: this.tm.current.surfaceGlass })
  }

  private buildStarArray(count: number): number[] {
    const arr: number[] = [];
    for (let i = 0; i < count; i++) { arr[arr.length] = i; }
    return arr;
  }
}
