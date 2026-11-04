/**
 * MaterialCalcPage.ets — 材料计算页主页面
 *
 * 单个角色的材料计算页面，支持：
 * 1. 设置角色目标等级
 * 2. 设置武器目标等级
 * 3. 设置技能目标等级
 * 4. 查看材料缺口
 */

import { themeManager, ThemeManager, ViewState } from 'basic';
import { MaterialCalcViewModel } from '../viewmodel/MaterialCalcViewModel';
import { MaterialCalcContentView } from '../views/MaterialCalcContentView';
import { MaterialCalcEmptyView } from '../views/MaterialCalcEmptyView';
import { MaterialCalcLoadingView } from '../views/MaterialCalcLoadingView';
import { MaterialCalcLevelPicker } from '../views/MaterialCalcLevelPicker';
import { LevelOptionVM } from '../model/MaterialCalcModels';

/** 页面参数 */
export class MaterialCalcParam {
  accountId: string = '';
  roleUid: string = '';
  avatarId: string = '';
}

@ComponentV2
export struct MaterialCalcPage {
  @Param param: MaterialCalcParam = new MaterialCalcParam();
  @Local private vm: MaterialCalcViewModel = new MaterialCalcViewModel();
  @Local private shouldShowLevelPicker: boolean = false;
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
              this.shouldShowLevelPicker = true;
            },
            onWeaponLevelTap: () => {
              this.levelPickerType = 'weapon';
              this.shouldShowLevelPicker = true;
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
      MaterialCalcLevelPicker({
        currentLevel: this.levelPickerType === 'character' ? this.vm.charTargetLevel : this.vm.weaponTargetLevel,
        options: this.levelOptions,
        isVisible: this.shouldShowLevelPicker,
        onSelect: (level: number) => {
          if (this.levelPickerType === 'character') {
            this.vm.setCharTargetLevel(level);
          } else {
            this.vm.setWeaponTargetLevel(level);
          }
        },
        onDismiss: () => {
          this.shouldShowLevelPicker = false;
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
export struct MaterialCalcPagePreview {
  build() {
    MaterialCalcPage()
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function MaterialCalcPageBuilder(_name: string, param: Object) {
  MaterialCalcPage({ param: param as MaterialCalcParam })
}
