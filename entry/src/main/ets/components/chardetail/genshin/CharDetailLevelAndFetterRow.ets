/**
 * CharDetailLevelAndFetterRow — 等级和好感行
 *
 * 用于角色详情英雄区的等级和好感度显示，支持 Portrait 和 Landscape 两种模式。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { GenshinCharacterDetailViewModel } from '../../../viewmodel/GenshinCharacterDetailViewModel';
import { elementColor, GenshinElement } from '../../../constants/GenshinElement';
import { HeroPanelMode } from '../../../constants/HeroPanelMode';
import { TransparentColorCache } from '../../../utils/ColorUtil';

@ComponentV2
export struct CharDetailLevelAndFetterRow {
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel();
  @Param mode: HeroPanelMode = HeroPanelMode.PORTRAIT;
  @Local private tm: ThemeManager = themeManager;

  private elementBgColor(): string {
    // TODO: 元素背景色应该从 color.json 的元素色动态计算透明度
    // 当前暂时保留硬编码，等待后续统一处理
    if (this.vm.charElement === GenshinElement.PYRO) { return '#26EF7A35'; }
    if (this.vm.charElement === GenshinElement.HYDRO) { return '#264BC3F1'; }
    if (this.vm.charElement === GenshinElement.ANEMO) { return '#2674C2A8'; }
    if (this.vm.charElement === GenshinElement.ELECTRO) { return '#26B08FC2'; }
    if (this.vm.charElement === GenshinElement.DENDRO) { return '#26A5C83B'; }
    if (this.vm.charElement === GenshinElement.CRYO) { return '#2698D5E4'; }
    if (this.vm.charElement === GenshinElement.GEO) { return '#26CFA726'; }
    return '#26666666';
  }

  build() {
    Row({ space: this.mode === HeroPanelMode.PORTRAIT ? this.tm.current.value8 : this.tm.current.value4 }) {
      Text(`Lv.${this.vm.charLevel}`)
        .fontSize(this.mode === HeroPanelMode.PORTRAIT ? this.tm.current.font13 : this.tm.current.font11)
        .fontColor(this.tm.current.textOnDarkMedium)

      Text($r('app.string.character_fetter_value', this.vm.charFetter))
        .fontSize(this.mode === HeroPanelMode.PORTRAIT ? this.tm.current.font11 : this.tm.current.font11)
        .fontColor(elementColor(this.vm.charElement))
        .backgroundColor(this.elementBgColor())
        .border({ width: this.tm.current.value1, color: TransparentColorCache.whiteWith60 })
        .borderRadius(this.tm.current.value4)
        .padding({
          left: this.tm.current.value4,
          right: this.tm.current.value4,
          top: this.tm.current.value1,
          bottom: this.tm.current.value1
        })
    }
  }
}
