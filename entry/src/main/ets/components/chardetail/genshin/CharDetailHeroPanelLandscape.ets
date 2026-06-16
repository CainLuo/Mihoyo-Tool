/**
 * CharDetailHeroPanelLandscape — Phone 横屏立绘区
 *
 * 立绘铺满，底部渐变遮罩，左下角名字+等级+好感+技能横行，右侧命座纵列居中。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { GenshinCharacterDetailViewModel } from '../../../viewmodel/GenshinCharacterDetailViewModel';
import { CharDetailSkill, CharDetailRankItem } from '../../../models/CharDetailModels';
import { elementColor, GenshinElement } from '../../../constants/GenshinElement';
import { CharDetailConsColumn } from '../common/CharDetailConsColumn';
import { CharDetailLandscapeSkillItem } from './CharDetailLandscapeSkillItem';
import { CharDetailHeroInfoOverlay } from './CharDetailHeroInfoOverlay';
import { genshinElementBgGradient } from '../../../utils/GenshinElementBgUtil';
import { HeroPanelMode } from '../../../constants/HeroPanelMode';
import { ViewState } from '../../../constants/ViewStates';
import { TransparentColorCache } from '../../../utils/ColorUtil';

function makeMockLandscapeVM(): GenshinCharacterDetailViewModel {
  const vm = new GenshinCharacterDetailViewModel();
  vm.viewState = ViewState.DATA;
  vm.charName = '雷电将军';
  vm.charLevel = 90;
  vm.charFetter = 10;
  vm.charElement = GenshinElement.ELECTRO;
  vm.charImageUrl = '';
  const cons: CharDetailRankItem[] = [];
  for (let i = 0; i < 6; i++) {
    const c = new CharDetailRankItem();
    c.pos = i + 1;
    c.iconUrl = '';
    c.isActived = i < 6;
    cons[cons.length] = c;
  }
  vm.constellations = cons;
  const skills: CharDetailSkill[] = [];
  const levels = [10, 10, 13];
  for (let i = 0; i < 3; i++) {
    const s = new CharDetailSkill();
    s.iconUrl = '';
    s.level = levels[i];
    skills[skills.length] = s;
  }
  vm.skills = skills;
  return vm;
}

// ── Preview：Phone 横屏立绘区 ──
@Preview
@ComponentV2
export struct CharDetailHeroPanelLandscapePreview {
  build() {
    CharDetailHeroPanelLandscape({ vm: makeMockLandscapeVM() })
      .width(themeManager.current.value200)
      .height(themeManager.current.value360)
  }
}

@ComponentV2
export struct CharDetailHeroPanelLandscape {
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  @Builder
  LevelAndFetterRow() {
    Row({ space: this.tm.current.value4 }) {
      Text(`Lv.${this.vm.charLevel}`)
        .fontSize(this.tm.current.font11)
        .fontColor(this.tm.current.textOnDarkMedium)
      Text($r('app.string.char_detail_fetter_label'))
        .fontSize(this.tm.current.font11)
        .fontColor(elementColor(this.vm.charElement))
        .backgroundColor(this.elementBgColor())
        .border({ width: this.tm.current.value1, color: TransparentColorCache.whiteWith60 })
        .borderRadius(this.tm.current.value4)
        .padding({
          left: this.tm.current.value4, right: this.tm.current.value4,
          top: this.tm.current.value1, bottom: this.tm.current.value1
        })
    }
  }

  private elementBgColor(): string {
    // TODO: 元素背景色应该从 color.json 的元素色动态计算透明度
    // 当前暂时保留硬编码，等待后续统一处理
    if (this.vm.charElement === GenshinElement.PYRO)    { return '#26EF7A35'; }
    if (this.vm.charElement === GenshinElement.HYDRO)   { return '#264BC3F1'; }
    if (this.vm.charElement === GenshinElement.ANEMO)   { return '#2674C2A8'; }
    if (this.vm.charElement === GenshinElement.ELECTRO) { return '#26B08FC2'; }
    if (this.vm.charElement === GenshinElement.DENDRO)  { return '#26A5C83B'; }
    if (this.vm.charElement === GenshinElement.CRYO)    { return '#2698D5E4'; }
    if (this.vm.charElement === GenshinElement.GEO)     { return '#26CFA726'; }
    return '#26666666';
  }

  @Builder
  SkillsRow() {
    Row({ space: this.tm.current.value8 }) {
      ForEach(this.vm.skills, (skill: CharDetailSkill) => {
        CharDetailLandscapeSkillItem({ skill: skill, charElement: this.vm.charElement })
      }, (_skill: CharDetailSkill, idx: number) => `lskill_${idx}`)
    }
  }

  build() {
    Stack() {
      // 背景（元素力渐变）
      Column()
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .linearGradient(genshinElementBgGradient(this.vm.charElement, this.tm.current, this.tm.current.a150))

      // 立绘铺满
      if (this.vm.charImageUrl !== '') {
        Image(this.vm.charImageUrl)
          .width(this.tm.current.full)
          .height(this.tm.current.full)
          .objectFit(ImageFit.Cover)
          .objectRepeat(ImageRepeat.NoRepeat)
      }

      // 底部渐变遮罩
      Column()
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .linearGradient({
          angle: this.tm.current.a0,
          colors: [
            [TransparentColorCache.blackWith80, 0],
            [TransparentColorCache.blackWith60, 0.4],
            [TransparentColorCache.blackWith40, 0.65],
            [Color.Transparent, 1.0]
          ]
        })

      // 右侧命座纵列（垂直居中）
      Column() {
        CharDetailConsColumn({ constellations: this.vm.constellations })
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .alignItems(HorizontalAlign.End)
      .justifyContent(FlexAlign.Center)
      .padding({ right: this.tm.current.value12 })
      .zIndex(3)

      // 左下角：名字 + 等级 + 好感 + 技能横行
      CharDetailHeroInfoOverlay({
        charName: this.vm.charName,
        charElement: this.vm.charElement,
        mode: HeroPanelMode.LANDSCAPE,
        extraContent: () => {
          this.LevelAndFetterRow()
          this.SkillsRow()
        }
      })
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .clip(true)
  }
}
