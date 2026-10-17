/**
 * MaterialCalc.ets — 材料计算页主页面
 *
 * 单个角色的材料计算页面，支持：
 * 1. 设置角色目标等级
 * 2. 设置武器目标等级
 * 3. 设置技能目标等级
 * 4. 查看材料缺口
 */

import { themeManager, ThemeManager } from '../theme/ThemeManager';
import { ViewState } from '../constants/ViewStates';
import { MaterialCalcViewModel, MaterialCalcViewModelKeys } from '../viewmodel/MaterialCalcViewModel';
import { MaterialCalcContentView } from '../components/material-calc/MaterialCalcContentView';
import { MaterialCalcEmptyView } from '../components/material-calc/MaterialCalcEmptyView';
import { MaterialCalcLoadingView } from '../components/material-calc/MaterialCalcLoadingView';
import { LevelPicker } from '../components/material-calc/LevelPicker';
import { LevelOptionVM } from '../models/MaterialCalcModels';
import { GameId } from 'core';

/** 页面参数 */
export class MaterialCalcParam {
  accountId: string = '';
  roleUid: string = '';
  avatarId: string = '';
}

@ComponentV2
export struct MaterialCalc {
  @Param param: MaterialCalcParam = new MaterialCalcParam();
  @Local private vm: MaterialCalcViewModel = new MaterialCalcViewModel();
  @Local private showLevelPicker: boolean = false;
  @Local private levelPickerType: 'character' | 'weapon' = 'character';
  @Local private levelOptions: LevelOptionVM[] = [];
  @Local private tm: ThemeManager = themeManager;

  aboutToAppear(): void {
    this.vm.init(this.param.accountId, this.param.roleUid, this.param.avatarId);
    this.levelOptions = this.vm.getLevelOptions();
  }

  build() {
    NavDestination() {
      Column() {
        // 内容区
        if (this.vm.viewState === ViewState.LOADING) {
          MaterialCalcLoadingView()
        } else if (this.vm.viewState === ViewState.EMPTY) {
          MaterialCalcEmptyView()
        } else {
          MaterialCalcContentView({
            character: this.vm.character,
            skills: this.vm.skills,
            avatarSection: this.vm.avatarSection,
            weaponSection: this.vm.weaponSection,
            onCharacterLevelTap: () => {
              this.levelPickerType = 'character';
              this.showLevelPicker = true;
            },
            onWeaponLevelTap: () => {
              this.levelPickerType = 'weapon';
              this.showLevelPicker = true;
            },
            onSkillTap: (skillId: string) => {
              // TODO: 显示技能等级选择器
            }
          })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.tm.current.colorPageBg)

      // 等级选择器弹窗
      LevelPicker({
        currentLevel: this.levelPickerType === 'character' ? this.vm.charTargetLevel : this.vm.weaponTargetLevel,
        options: this.levelOptions,
        visible: this.showLevelPicker,
        onSelect: (level: number) => {
          if (this.levelPickerType === 'character') {
            this.vm.setCharTargetLevel(level);
          } else {
            this.vm.setWeaponTargetLevel(level);
          }
        },
        onDismiss: () => {
          this.showLevelPicker = false;
        }
      })
    }
    .title($r('app.string.material_calc_title'))
    .hideTitleBar(false)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct MaterialCalcPreview {
  build() {
    MaterialCalc()
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function MaterialCalcBuilder(_name: string, param: Object) {
  MaterialCalc({ param: param as MaterialCalcParam })
}
