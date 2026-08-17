/**
 * ZZZMaterialTargetConfig.ets — 绝区零养成目标配置页
 *
 * 用户在此页面设置角色/武器/技能的目标等级，配置后进入材料汇总页面。
 * 点击当前/目标等级 → 弹出官方 TextPickerDialog 单列选择器。
 */

import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { Logger } from 'core'
import { ThemeFonts } from '../theme/ThemeFonts'
import { PrimaryButtonModifier } from '../styles/ButtonModifier'
import { AppRoutes } from '../constants/AppRoutes'
import {
  ZZZMaterialTargetConfigViewModel
} from '../viewmodel/ZZZMaterialTargetConfigViewModel'
import { LevelConfigVM, LevelLabelKeys, SkillLevelConfigVM } from '../models/MaterialTargetConfigModels'
import { MaterialTargetConfigParam } from '../models/ToolsModels'

type PickerStep = 'current' | 'target'

@ComponentV2
export struct ZZZMaterialTargetConfig {
  @Local private vm: ZZZMaterialTargetConfigViewModel = new ZZZMaterialTargetConfigViewModel()
  @Local private tm: ThemeManager = themeManager
  @Local private buttonModifier: PrimaryButtonModifier = new PrimaryButtonModifier(true)
  /** 路由参数 */
  @Param private param: MaterialTargetConfigParam | null = null
  private localStack: NavPathStack | null = null

  /** Picker 状态 */
  private pickerConfigKey: string = ''
  private pickerStep: PickerStep = 'current'
  private pickerValue: number = 1

  aboutToAppear(): void {
    // 从路由参数获取 accountId 和 roleUid
    const accountId = this.param?.accountId ?? ''
    const roleUid = this.param?.roleUid ?? ''
    this.vm.init(accountId, roleUid)
  }

  /**
   * 显示等级选择 Picker（官方 TextPickerDialog）
   */
  private showLevelPicker(key: string, step: PickerStep, config: LevelConfigVM): void {
    this.pickerConfigKey = key
    this.pickerStep = step

    if (step === 'current') {
      this.pickerValue = config.current
    } else {
      // 目标等级最小值为当前等级
      this.pickerValue = Math.max(config.current, config.target)
    }

    // 构建选项数组
    const range: string[] = []
    const minValue = step === 'current' ? 1 : config.current
    for (let i = minValue; i <= config.max; i++) {
      range.push(this.formatLevel(i))
    }

    // 计算选中索引
    const selectedIndex = this.pickerValue - minValue

    // 调用官方 TextPickerDialog
    this.getUIContext().showTextPickerDialog({
      range: range,
      selected: selectedIndex,
      canLoop: false,
      onAccept: (result: TextPickerResult) => {
        // result.index 可能是 number 或 number[]，单列时是 number
        const idx = Array.isArray(result.index) ? result.index[0] : result.index
        const selectedValue = idx + minValue
        this.confirmPicker(selectedValue)
      },
      onCancel: () => {}
    })
  }

  /**
   * 确认选择
   */
  private confirmPicker(value: number): void {
    if (this.pickerStep === 'current') {
      // 选择当前等级：如果新值 > 目标等级，自动调高目标等级
      this.vm.updateCurrent(this.pickerConfigKey, value)
    } else {
      // 选择目标等级：直接更新
      this.vm.updateTarget(this.pickerConfigKey, value)
    }
  }

  /**
   * 开始计算材料
   * 先在当前页面同步数据，完成后再跳转到材料总汇页。
   */
  private async startCalculation(): Promise<void> {
    Logger.info('ZZZMaterialTargetConfig', `startCalculation called, isSyncing=${this.vm.isSyncing}`)
    
    // 先同步数据
    const success = await this.vm.syncComputeData()
    Logger.info('ZZZMaterialTargetConfig', `syncComputeData result=${success}`)
    
    // 同步完成后跳转到材料总汇页，替换当前配置页
    // 这样从材料总汇返回时会直接回到 Tools 页面
    if (this.localStack !== null) {
      this.localStack.replacePathByName(AppRoutes.ZZZ_MATERIAL_LIST, null)
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 内容区
        Scroll() {
          Column({ space: this.tm.current.value10 }) {
            // 提示卡片
            this.TipCard($r('app.string.material_target_config_zzz_tip'))
            
            // 角色等级
            this.LevelRow('avatar', this.vm.avatarLevel)
            
            // 武器等级
            this.LevelRow('weapon', this.vm.weaponLevel)

            // 技能等级标题
            Text($r('app.string.material_target_config_skill_level'))
              .font(ThemeFonts.fontBold14)
              .fontColor(this.tm.current.colorTextPrimary)
              .margin({ top: this.tm.current.value12, bottom: this.tm.current.value8 })

            // 6 个技能等级配置
            ForEach(this.vm.skills, (skill: SkillLevelConfigVM) => {
              this.SkillLevelRow(skill)
            })
          }
          .width(this.tm.current.full)
          .padding({
            top: this.tm.current.value12,
            left: this.tm.current.value16,
            right: this.tm.current.value16,
            bottom: this.tm.current.value16
          })
        }
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .align(Alignment.Top)

        // 底部按钮
        Column() {
          Button(
            this.vm.isSyncing 
              ? $r('app.string.material_target_config_syncing')
              : $r('app.string.material_target_config_start_calc')
          )
            .attributeModifier(this.buttonModifier)
            .width(this.tm.current.full)
            .height(this.tm.current.value48)
            .enabled(!this.vm.isSyncing)
            .onClick(() => {
              this.startCalculation()
            })
        }
        .width(this.tm.current.full)
        .padding(this.tm.current.value16)
        .border({ width: 1, color: this.tm.current.colorDivider })
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .backgroundColor(this.tm.current.colorPageBg)
    }
    .title($r('app.string.zzz_material_list_title'))
    .hideTitleBar(false)
    .onReady((ctx: NavDestinationContext) => {
      this.localStack = ctx.pathStack
    })
  }

  // ─── 提示卡片 ─────────────────────────────────────────────────────

  @Builder
  TipCard(tip: ResourceStr) {
    Row() {
      Text('💡')
        .fontSize(this.tm.current.value16)
        .margin({ right: this.tm.current.value8 })

      Text(tip)
        .font(ThemeFonts.font13)
        .fontColor(this.tm.current.colorTextPrimary)
        .layoutWeight(1)
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value12)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .border({ width: 1, color: this.tm.current.colorDivider })
  }

  // ─── 等级行（横向布局：左当前、右目标）────────────────────────────

  @Builder
  LevelRow(key: string, config: LevelConfigVM) {
    Column() {
      // 标题
      Text(this.getLabelResource(config.labelKey))
        .fontSize(this.tm.current.font12)
        .fontColor(this.tm.current.colorTextSecondary)
        .margin({ bottom: this.tm.current.value8 })

      // 横向两列
      Row({ space: this.tm.current.value8 }) {
        // 左列：当前等级
        Column() {
          Text($r('app.string.material_target_config_current'))
            .font(ThemeFonts.font11)
            .fontColor(this.tm.current.colorTextSecondary)
            .margin({ bottom: this.tm.current.value2 })

          Text(config.current.toString())
            .font(ThemeFonts.fontBold18)
            .fontColor(this.tm.current.colorTextPrimary)
        }
        .layoutWeight(1)
        .padding(this.tm.current.value8)
        .backgroundColor(this.tm.current.colorPageBg)
        .borderRadius(this.tm.current.radius8)
        .onClick(() => {
          this.showLevelPicker(key, 'current', config)
        })

        // 右列：目标等级
        Column() {
          Text($r('app.string.material_target_config_target'))
            .font(ThemeFonts.font11)
            .fontColor(this.tm.current.colorTextSecondary)
            .margin({ bottom: this.tm.current.value2 })

          Text(config.target.toString())
            .font(ThemeFonts.fontBold18)
            .fontColor(this.tm.current.colorPrimary)
        }
        .layoutWeight(1)
        .padding(this.tm.current.value8)
        .backgroundColor(this.tm.current.colorPageBg)
        .borderRadius(this.tm.current.radius8)
        .onClick(() => {
          this.showLevelPicker(key, 'target', config)
        })
      }
      .width(this.tm.current.full)
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value10)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .border({ width: 1, color: this.tm.current.colorDivider })
    .margin({ bottom: this.tm.current.value10 })
  }

  // ─── 技能等级行 ─────────────────────────────────────────────────────

  @Builder
  SkillLevelRow(config: SkillLevelConfigVM) {
    Column() {
      // 标题
      Text(this.getLabelResource(config.labelKey))
        .fontSize(this.tm.current.font12)
        .fontColor(this.tm.current.colorTextSecondary)
        .margin({ bottom: this.tm.current.value8 })

      // 横向两列
      Row({ space: this.tm.current.value8 }) {
        // 左列：当前等级
        Column() {
          Text($r('app.string.material_target_config_current'))
            .font(ThemeFonts.font11)
            .fontColor(this.tm.current.colorTextSecondary)
            .margin({ bottom: this.tm.current.value2 })

          Text(config.current.toString())
            .font(ThemeFonts.fontBold18)
            .fontColor(this.tm.current.colorTextPrimary)
        }
        .layoutWeight(1)
        .padding(this.tm.current.value8)
        .backgroundColor(this.tm.current.colorPageBg)
        .borderRadius(this.tm.current.radius8)
        .onClick(() => {
          const key = 'skill' + config.skillType.toString()
          this.showLevelPicker(key, 'current', config)
        })

        // 右列：目标等级
        Column() {
          Text($r('app.string.material_target_config_target'))
            .font(ThemeFonts.font11)
            .fontColor(this.tm.current.colorTextSecondary)
            .margin({ bottom: this.tm.current.value2 })

          Text(config.target.toString())
            .font(ThemeFonts.fontBold18)
            .fontColor(this.tm.current.colorPrimary)
        }
        .layoutWeight(1)
        .padding(this.tm.current.value8)
        .backgroundColor(this.tm.current.colorPageBg)
        .borderRadius(this.tm.current.radius8)
        .onClick(() => {
          const key = 'skill' + config.skillType.toString()
          this.showLevelPicker(key, 'target', config)
        })
      }
      .width(this.tm.current.full)
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value10)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .border({ width: 1, color: this.tm.current.colorDivider })
    .margin({ bottom: this.tm.current.value10 })
  }

  // ─── 工具方法 ─────────────────────────────────────────────────────

  /**
   * 将 labelKey 转换为 Resource
   */
  private getLabelResource(labelKey: string): ResourceStr {
    switch (labelKey) {
      case LevelLabelKeys.AVATAR_LEVEL:
        return $r('app.string.material_target_config_avatar_level')
      case LevelLabelKeys.WEAPON_LEVEL:
        return $r('app.string.material_target_config_weapon_level')
      case LevelLabelKeys.ZZZ_SKILL_NORMAL:
        return $r('app.string.zzz_skill_normal_attack')
      case LevelLabelKeys.ZZZ_SKILL_DODGE:
        return $r('app.string.zzz_skill_dodge')
      case LevelLabelKeys.ZZZ_SKILL_ASSIST:
        return $r('app.string.zzz_skill_assist')
      case LevelLabelKeys.ZZZ_SKILL_SPECIAL:
        return $r('app.string.zzz_skill_special')
      case LevelLabelKeys.ZZZ_SKILL_CHAIN:
        return $r('app.string.zzz_skill_chain')
      case LevelLabelKeys.ZZZ_SKILL_CORE:
        return $r('app.string.zzz_skill_core')
      default:
        return ''
    }
  }

  /**
   * 格式化等级显示（Picker 选项）
   */
  private formatLevel(level: number): string {
    return `${level} 级`
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct ZZZMaterialTargetConfigPreview {
  build() {
    ZZZMaterialTargetConfig()
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function ZZZMaterialTargetConfigBuilder(_name: string, param: Object) {
  ZZZMaterialTargetConfig({ param: param as MaterialTargetConfigParam })
}
