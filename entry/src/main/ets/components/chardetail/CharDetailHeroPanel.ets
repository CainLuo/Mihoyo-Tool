/**
 * CharDetailHeroPanel — 角色立绘区入口组件
 *
 * 根据 mode 分发到对应布局组件：
 *   WIDE      → CharDetailHeroPanelWide（宽屏三栏）
 *   PORTRAIT  → CharDetailHeroPanelPortrait（Phone 竖屏）
 *   LANDSCAPE → CharDetailHeroPanelLandscape（Phone 横屏）
 */

import { GenshinCharacterDetailViewModel } from '../../viewmodel/GenshinCharacterDetailViewModel';
import { CharDetailConstellation, CharDetailSkill } from './CharDetailModels';
import { HeroPanelMode } from '../../constants/HeroPanelMode';
import { CharDetailHeroPanelWide } from './CharDetailHeroPanelWide';
import { CharDetailHeroPanelPortrait } from './CharDetailHeroPanelPortrait';
import { CharDetailHeroPanelLandscape } from './CharDetailHeroPanelLandscape';
import { GenshinElement } from '../../constants/GenshinElement';
import { themeManager } from '../../theme/ThemeManager';
import { ViewState } from '../../constants/ViewStates';

function makeMockHeroPanelVM(element: GenshinElement, name: string, cons: number): GenshinCharacterDetailViewModel {
  const vm = new GenshinCharacterDetailViewModel();
  vm.viewState = ViewState.DATA;
  vm.charName = name;
  vm.charLevel = 90;
  vm.charFetter = 10;
  vm.charElement = element;
  vm.charImageUrl = '';
  const consList: CharDetailConstellation[] = [];
  for (let i = 0; i < 6; i++) {
    const c = new CharDetailConstellation();
    c.pos = i + 1;
    c.iconUrl = '';
    c.isActived = i < cons;
    consList[consList.length] = c;
  }
  vm.constellations = consList;
  const skillList: CharDetailSkill[] = [];
  for (let i = 0; i < 3; i++) {
    const s = new CharDetailSkill();
    s.iconUrl = '';
    s.level = 10;
    skillList[skillList.length] = s;
  }
  vm.skills = skillList;
  return vm;
}

// ── Preview：WIDE 模式 ──
@Preview
@ComponentV2
struct CharDetailHeroPanelPreviewWide {
  build() {
    CharDetailHeroPanel({
      vm: makeMockHeroPanelVM(GenshinElement.HYDRO, '夜兰', 6),
      mode: HeroPanelMode.WIDE
    })
    .width(themeManager.current.value400)
    .height(themeManager.current.value480)
  }
}

// ── Preview：PORTRAIT 模式 ──
@Preview
@ComponentV2
struct CharDetailHeroPanelPreviewPortrait {
  build() {
    CharDetailHeroPanel({
      vm: makeMockHeroPanelVM(GenshinElement.PYRO, '胡桃', 1),
      mode: HeroPanelMode.PORTRAIT
    })
    .width(themeManager.current.value360)
    .height(themeManager.current.value260)
  }
}

// ── Preview：LANDSCAPE 模式 ──
@Preview
@ComponentV2
struct CharDetailHeroPanelPreviewLandscape {
  build() {
    CharDetailHeroPanel({
      vm: makeMockHeroPanelVM(GenshinElement.ELECTRO, '雷电将军', 6),
      mode: HeroPanelMode.LANDSCAPE
    })
    .width(themeManager.current.value200)
    .height(themeManager.current.value360)
  }
}

@ComponentV2
export struct CharDetailHeroPanel {
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel();
  @Param mode: HeroPanelMode = HeroPanelMode.WIDE;

  build() {
    if (this.mode === HeroPanelMode.PORTRAIT) {
      CharDetailHeroPanelPortrait({ vm: this.vm })
    } else if (this.mode === HeroPanelMode.LANDSCAPE) {
      CharDetailHeroPanelLandscape({ vm: this.vm })
    } else {
      CharDetailHeroPanelWide({ vm: this.vm })
    }
  }
}
