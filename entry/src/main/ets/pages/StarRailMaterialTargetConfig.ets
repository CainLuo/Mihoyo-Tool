/**
 * StarRailMaterialTargetConfig.ets — 星穹铁道养成目标配置页
 *
 * 用户在此页面设置角色/命途/光锥的目标等级，配置后进入材料汇总页面。
 * 点击当前/目标等级 → 弹出官方 TextPickerDialog 单列选择器。
 */

import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { Logger } from 'core'
import { ThemeFonts } from '../theme/ThemeFonts'
import { PrimaryButtonModifier } from '../styles/ButtonModifier'
import { AppRoutes } from '../constants/AppRoutes'
import {
  StarRailMaterialTargetConfigViewModel
} from '../viewmodel/StarRailMaterialTargetConfigViewModel'
import { LevelConfigVM, LevelLabelKeys } from '../models/MaterialTargetConfigModels'
import { MaterialTargetConfigParam } from '../models/ToolsModels'

type PickerStep = 'current' | 'target'

@ComponentV2
export struct StarRailMaterialTargetConfig {
  @Local private vm: StarRailMaterialTargetConfigViewModel = new StarRailMaterialTargetConfigViewModel()
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
    Logger.info('StarRailMaterialTargetConfig', `startCalculation called, isSyncing=${this.vm.isSyncing}`)
    
    // 先同步数据
    const success = await this.vm.syncComputeData()
    Logger.info('StarRailMaterialTargetConfig', `syncComputeData result=${success}`)
    
    // 同步完成后跳转到材料总汇页，替换当前配置页
    // 这样从材料总汇返回时会直接回到 Tools 页面
    if (this.localStack !== null) {
      this.localStack.replacePathByName(AppRoutes.STARRAIL_MATERIAL_LIST, null)
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 内容区
        Scroll() {
          Column({ space: this.tm.current.value10 }) {
            // 提示卡片
            this.TipCard($r('app.string.material_target_config_starrail_tip'))
            
            // 角色等级
            this.LevelRow('avatar', this.vm.avatarLevel)
            
            // 命途等级
            this.LevelRow('skill', this.vm.skillLevel)
            
            // 光锥等级
            this.LevelRow('lightCone', this.vm.lightConeLevel)
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
    .title($r('app.string.starrail_material_list_title'))
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

  // ─── 工具方法 ─────────────────────────────────────────────────────

  /**
   * 将 labelKey 转换为 Resource
   */
  private getLabelResource(labelKey: string): ResourceStr {
    switch (labelKey) {
      case LevelLabelKeys.AVATAR_LEVEL:
        return $r('app.string.material_target_config_avatar_level')
      case LevelLabelKeys.TRACE_LEVEL:
        return $r('app.string.material_target_config_trace_level')
      case LevelLabelKeys.LIGHT_CONE_LEVEL:
        return $r('app.string.material_target_config_light_cone_level')
      default:
        return ''
    }
  }

  /**
   * 格式化等级显示（Picker 选项）
   */
  private formatLevel(level: number): string {
    // 无法在运行时动态拼接 $r()，使用硬编码格式
    // 已在 string.json 中配置 material_target_config_level_suffix
    return `${level} 级`
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct StarRailMaterialTargetConfigPreview {
  build() {
    StarRailMaterialTargetConfig()
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function StarRailMaterialTargetConfigBuilder(_name: string, param: Object) {
  StarRailMaterialTargetConfig({ param: param as MaterialTargetConfigParam })
}
