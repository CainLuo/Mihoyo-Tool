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
import { CharDetailLevelAndFetterRow } from './CharDetailLevelAndFetterRow';
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
  extraContentBuilder() {
    Column({ space: this.tm.current.value4 }) {
      CharDetailLevelAndFetterRow({ vm: this.vm, mode: HeroPanelMode.LANDSCAPE })

      // 技能横行
      Row({ space: this.tm.current.value8 }) {
        ForEach(this.vm.skills, (skill: CharDetailSkill) => {
          CharDetailLandscapeSkillItem({ skill: skill, charElement: this.vm.charElement })
        }, (_skill: CharDetailSkill, idx: number) => `lskill_${idx}`)
      }
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
        extraContent: () => { this.extraContentBuilder() }
      })
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .clip(true)
  }
}
