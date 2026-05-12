/**
 * WidgetSettings — Widget 卡片配置页
 *
 * 采用步骤流程：
 * 1. 选择卡片尺寸（1×2 / 2×2 / 2×4 / 4×4）
 * 2. 选择要显示的角色 slots（跨账号多选）
 * 3. 完成 → 调用 formProvider.openFormManager()
 */
import { common } from '@kit.AbilityKit';
import { themeManager, ThemeManager } from '../theme/ThemeManager';
import { WidgetConfigViewModel, WidgetConfigStep } from '../viewmodel/WidgetConfigViewModel';
import { WidgetSize } from '../widget/models/WidgetConfig';
import { WidgetStepIndicator } from '../components/widgetconfig/WidgetStepIndicator';
import { WidgetConfigDone } from '../components/widgetconfig/WidgetConfigDone';
import { WidgetConfigPreview } from '../components/widgetconfig/WidgetConfigPreview';
import { WidgetSlotRef } from '../widget/models/WidgetDataStore';
import { GameId } from 'core';

/** 尺寸配置 */
interface SizeConfig {
  size: WidgetSize;
  label: ResourceStr;
  desc: ResourceStr;
}

const SIZE_CONFIGS: SizeConfig[] = [
  { size: WidgetSize.SIZE_1x2, label: $r('app.string.widget_size_1x2'), desc: $r('app.string.widget_size_1x2_desc') },
  { size: WidgetSize.SIZE_2x2, label: $r('app.string.widget_size_2x2'), desc: $r('app.string.widget_size_2x2_desc') },
  { size: WidgetSize.SIZE_2x4, label: $r('app.string.widget_size_2x4'), desc: $r('app.string.widget_size_2x4_desc') },
  { size: WidgetSize.SIZE_4x4, label: $r('app.string.widget_size_4x4'), desc: $r('app.string.widget_size_4x4_desc') },
];

/** 游戏颜色 */
function getGameColor(gameId: string): ResourceColor {
  if (gameId === GameId.GENSHIN || gameId === 'genshin') {
    return '#5ba3e8';
  } else if (gameId === GameId.STARRAIL || gameId === 'starrail') {
    return '#9b8eff';
  } else if (gameId === GameId.ZZZ || gameId === 'zzz') {
    return '#f7b84b';
  }
  return '#888888';
}

/** 游戏名称 */
function getGameName(gameId: string): ResourceStr {
  if (gameId === GameId.GENSHIN || gameId === 'genshin') {
    return $r('app.string.game_name_genshin');
  } else if (gameId === GameId.STARRAIL || gameId === 'starrail') {
    return $r('app.string.game_name_starrail');
  } else if (gameId === GameId.ZZZ || gameId === 'zzz') {
    return $r('app.string.game_name_zzz');
  }
  return gameId;
}

/** 游戏类型配置（用于 1x2 卡片选择，使用 core 的 GameId） */
interface GameTypeConfig {
  gameId: string;
  label: ResourceStr;
  color: ResourceColor;
}

const GAME_TYPE_CONFIGS: GameTypeConfig[] = [
  { gameId: GameId.GENSHIN, label: $r('app.string.game_name_genshin'), color: '#5ba3e8' },
  { gameId: GameId.STARRAIL, label: $r('app.string.game_name_starrail'), color: '#9b8eff' },
  { gameId: GameId.ZZZ, label: $r('app.string.game_name_zzz'), color: '#f7b84b' },
];

@ComponentV2
export struct WidgetSettings {
  @Local private tm: ThemeManager = themeManager;
  @Local private vm: WidgetConfigViewModel = new WidgetConfigViewModel();
  @Local private isLoading: boolean = true;
  private localStack: NavPathStack | null = null;

  async aboutToAppear(): Promise<void> {
    // 获取 context 用于初始化 WidgetDataStoreManager
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    await this.vm.init(context);
    this.isLoading = false;
    this.vm.onConfigComplete = () => {
      this.localStack?.pop();
    };
  }

  build() {
    NavDestination() {
      Column() {
        if (this.isLoading) {
          this.LoadingView()
        } else {
          this.MainContent()
        }
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .backgroundColor(this.tm.current.colorPageBg)
    }
    .title($r('app.string.widget_config_title'))
    .hideTitleBar(false)
    .backgroundColor(this.tm.current.colorPageBg)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .onReady((ctx: NavDestinationContext) => {
      this.localStack = ctx.pathStack;
    })
  }

  @Builder
  LoadingView() {
    Column() {
      LoadingProgress()
        .width(this.tm.current.value48)
        .height(this.tm.current.value48)
        .color(this.tm.current.colorPrimary)
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  MainContent() {
    Column() {
      Scroll() {
        Column() {
          // 卡片预览
          Column() {
            WidgetConfigPreview({
              selectedSize: this.vm.selectedSize,
              selectedSlots: this.vm.selectedSlots
            })
          }
          .width(this.tm.current.full)
          .padding({ top: this.tm.current.value16, bottom: this.tm.current.value16 })
          .justifyContent(FlexAlign.Center)

          // 步骤指示器
          WidgetStepIndicator({
            currentStep: this.vm.currentStep,
            selectedSize: this.vm.selectedSize
          })

          // 步骤内容
          Column() {
            if (this.vm.currentStep === WidgetConfigStep.SIZE) {
              this.renderSizeStep()
            } else if (this.vm.currentStep === WidgetConfigStep.GAME) {
              this.renderGameStep()
            } else if (this.vm.currentStep === WidgetConfigStep.SLOT) {
              this.renderSlotStep()
            } else if (this.vm.currentStep === WidgetConfigStep.DONE) {
              WidgetConfigDone({
                selectedSize: this.vm.selectedSize,
                selectedSummary: this.vm.getSelectedSummary()
              })
            }
          }
          .width(this.tm.current.full)
          .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
        }
        .width(this.tm.current.full)
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)

      // 底部按钮
      Row({ space: this.tm.current.value10 }) {
        if (this.vm.canGoPrev()) {
          Button($r('app.string.widget_btn_prev'))
            .height(this.tm.current.value44)
            .layoutWeight(1)
            .fontSize(this.tm.current.body13.size)
            .fontColor(this.tm.current.colorTextPrimary)
            .backgroundColor(Color.Transparent)
            .border({ width: 1, color: this.tm.current.colorDivider })
            .borderRadius(this.tm.current.radius12)
            .onClick(() => { this.vm.goPrev(); })
        }

        if (this.vm.currentStep === WidgetConfigStep.DONE) {
          Button($r('app.string.widget_btn_add'))
            .height(this.tm.current.value44)
            .layoutWeight(2)
            .fontSize(this.tm.current.body13Bold.size)
            .fontWeight(this.tm.current.body13Bold.weight)
            .fontColor(Color.White)
            .backgroundColor(this.tm.current.colorPrimary)
            .borderRadius(this.tm.current.radius12)
            .onClick(() => { this.vm.complete(); })
        } else {
          Button($r('app.string.widget_btn_next'))
            .height(this.tm.current.value44)
            .layoutWeight(2)
            .fontSize(this.tm.current.body13Bold.size)
            .fontWeight(this.tm.current.body13Bold.weight)
            .fontColor(Color.White)
            .backgroundColor(this.tm.current.colorPrimary)
            .borderRadius(this.tm.current.radius12)
            .enabled(this.vm.canGoNext())
            .opacity(this.vm.canGoNext() ? 1 : 0.5)
            .onClick(() => { this.vm.goNext(); })
        }
      }
      .width(this.tm.current.full)
      .padding({
        left: this.tm.current.value16,
        right: this.tm.current.value16,
        top: this.tm.current.value12,
        bottom: this.tm.current.value24
      })
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
  }

  // ─── 步骤 1：尺寸选择 ─────────────────────────────────────────────

  @Builder
  renderSizeStep() {
    Column({ space: this.tm.current.value10 }) {
      ForEach(SIZE_CONFIGS, (config: SizeConfig) => {
        this.SizeOption(config)
      }, (config: SizeConfig) => config.size)
    }
    .width(this.tm.current.full)
  }

  @Builder
  SizeOption(config: SizeConfig) {
    Row() {
      this.SizeThumb(config.size)

      Column() {
        Text(config.label)
          .fontSize(this.tm.current.body13Bold.size)
          .fontWeight(this.tm.current.body13Bold.weight)
          .fontColor(this.vm.selectedSize === config.size ?
            this.tm.current.colorPrimary : this.tm.current.colorTextPrimary)

        Text(config.desc)
          .fontSize(this.tm.current.body12.size)
          .fontColor(this.tm.current.colorTextSecondary)
          .margin({ top: this.tm.current.value2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: this.tm.current.value12 })

      if (this.vm.selectedSize === config.size) {
        Row() {
          Text('✓')
            .fontSize(this.tm.current.body12.size)
            .fontColor(Color.White)
        }
        .width(this.tm.current.value18)
        .height(this.tm.current.value18)
        .borderRadius(this.tm.current.value9)
        .backgroundColor(this.tm.current.colorPrimary)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value14)
    .backgroundColor(this.vm.selectedSize === config.size ?
      'rgba(58,111,216,0.15)' : Color.Transparent)
    .borderRadius(this.tm.current.radius12)
    .border({
      width: 2,
      color: this.vm.selectedSize === config.size ?
        this.tm.current.colorPrimary : this.tm.current.colorDivider
    })
    .onClick(() => { this.vm.selectSize(config.size); })
  }

  @Builder
  SizeThumb(size: WidgetSize) {
    Column() {
      if (size === WidgetSize.SIZE_1x2) {
        Row({ space: 2 }) {
          Column().width(10).height(10).backgroundColor(this.getThumbColor(size)).borderRadius(2)
          Column().width(10).height(10).backgroundColor(this.getThumbColor(size)).borderRadius(2)
        }
      } else if (size === WidgetSize.SIZE_2x2) {
        Column({ space: 2 }) {
          Row({ space: 2 }) {
            Column().width(10).height(10).backgroundColor(this.getThumbColor(size)).borderRadius(2)
            Column().width(10).height(10).backgroundColor(this.getThumbColor(size)).borderRadius(2)
          }
          Row({ space: 2 }) {
            Column().width(10).height(10).backgroundColor(this.getThumbColor(size)).borderRadius(2)
            Column().width(10).height(10).backgroundColor(this.getThumbColor(size)).borderRadius(2)
          }
        }
      } else if (size === WidgetSize.SIZE_2x4) {
        Column({ space: 2 }) {
          Row({ space: 2 }) {
            Column().width(8).height(10).backgroundColor(this.getThumbColor(size)).borderRadius(2)
            Column().width(8).height(10).backgroundColor(this.getThumbColor(size)).borderRadius(2)
            Column().width(8).height(10).backgroundColor(this.getThumbColor(size)).borderRadius(2)
            Column().width(8).height(10).backgroundColor(this.getThumbColor(size)).borderRadius(2)
          }
          Row({ space: 2 }) {
            Column().width(8).height(10).backgroundColor(this.getThumbColor(size)).borderRadius(2)
            Column().width(8).height(10).backgroundColor(this.getThumbColor(size)).borderRadius(2)
            Column().width(8).height(10).backgroundColor(this.getThumbColor(size)).borderRadius(2)
            Column().width(8).height(10).backgroundColor(this.getThumbColor(size)).borderRadius(2)
          }
        }
      } else {
        Column({ space: 2 }) {
          Row({ space: 2 }) {
            Column().width(7).height(7).backgroundColor(this.getThumbColor(size)).borderRadius(2)
            Column().width(7).height(7).backgroundColor(this.getThumbColor(size)).borderRadius(2)
            Column().width(7).height(7).backgroundColor(this.getThumbColor(size)).borderRadius(2)
            Column().width(7).height(7).backgroundColor(this.getThumbColor(size)).borderRadius(2)
          }
          Row({ space: 2 }) {
            Column().width(7).height(7).backgroundColor(this.getThumbColor(size)).borderRadius(2)
            Column().width(7).height(7).backgroundColor(this.getThumbColor(size)).borderRadius(2)
            Column().width(7).height(7).backgroundColor(this.getThumbColor(size)).borderRadius(2)
            Column().width(7).height(7).backgroundColor(this.getThumbColor(size)).borderRadius(2)
          }
          Row({ space: 2 }) {
            Column().width(7).height(7).backgroundColor(this.getThumbColor(size)).borderRadius(2)
            Column().width(7).height(7).backgroundColor(this.getThumbColor(size)).borderRadius(2)
            Column().width(7).height(7).backgroundColor(this.getThumbColor(size)).borderRadius(2)
            Column().width(7).height(7).backgroundColor(this.getThumbColor(size)).borderRadius(2)
          }
          Row({ space: 2 }) {
            Column().width(7).height(7).backgroundColor(this.getThumbColor(size)).borderRadius(2)
            Column().width(7).height(7).backgroundColor(this.getThumbColor(size)).borderRadius(2)
            Column().width(7).height(7).backgroundColor(this.getThumbColor(size)).borderRadius(2)
            Column().width(7).height(7).backgroundColor(this.getThumbColor(size)).borderRadius(2)
          }
        }
      }
    }
    .width(this.tm.current.value40)
    .height(this.tm.current.value40)
    .justifyContent(FlexAlign.Center)
  }

  private getThumbColor(size: WidgetSize): ResourceColor {
    return this.vm.selectedSize === size ? this.tm.current.colorPrimary : this.tm.current.colorTextSecondary;
  }

  // ─── 步骤 2：游戏类型选择（仅 1x2 卡片）─────────────────────────────────────

  @Builder
  renderGameStep() {
    Column({ space: this.tm.current.value10 }) {
      // 提示文字
      Text($r('app.string.widget_select_game_hint'))
        .fontSize(this.tm.current.body12.size)
        .fontColor(this.tm.current.colorTextSecondary)
        .width(this.tm.current.full)
        .margin({ bottom: this.tm.current.value8 })

      ForEach(GAME_TYPE_CONFIGS, (config: GameTypeConfig) => {
        this.GameTypeOption(config)
      }, (config: GameTypeConfig) => config.gameId)
    }
    .width(this.tm.current.full)
  }

  @Builder
  GameTypeOption(config: GameTypeConfig) {
    Row() {
      // 左侧：游戏色块
      Column()
        .width(40)
        .height(40)
        .borderRadius(this.tm.current.radius12)
        .backgroundColor(config.color)
        .justifyContent(FlexAlign.Center)
        .opacity(this.vm.hasDataForGame(config.gameId) ? 1 : 0.3)

      // 中间：游戏名称 + 账号数量
      Column() {
        Text(config.label)
          .fontSize(this.tm.current.body13Bold.size)
          .fontWeight(this.tm.current.body13Bold.weight)
          .fontColor(this.vm.selectedGameType === config.gameId ?
            this.tm.current.colorPrimary : this.tm.current.colorTextPrimary)

        Text(`${this.vm.getSlotsForGame(config.gameId).length} 个账号`)
          .fontSize(this.tm.current.body12.size)
          .fontColor(this.tm.current.colorTextSecondary)
          .margin({ top: this.tm.current.value2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: this.tm.current.value12 })

      // 右侧：选中状态
      if (this.vm.selectedGameType === config.gameId) {
        Row() {
          Text('✓')
            .fontSize(this.tm.current.body12.size)
            .fontColor(Color.White)
        }
        .width(this.tm.current.value18)
        .height(this.tm.current.value18)
        .borderRadius(this.tm.current.value9)
        .backgroundColor(this.tm.current.colorPrimary)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value14)
    .backgroundColor(this.vm.selectedGameType === config.gameId ?
      'rgba(58,111,216,0.15)' : Color.Transparent)
    .borderRadius(this.tm.current.radius12)
    .border({
      width: 2,
      color: this.vm.selectedGameType === config.gameId ?
        this.tm.current.colorPrimary : this.tm.current.colorDivider
    })
    .opacity(this.vm.hasDataForGame(config.gameId) ? 1 : 0.5)
    .onClick(() => {
      if (this.vm.hasDataForGame(config.gameId)) {
        this.vm.selectGameType(config.gameId);
      }
    })
  }

  // ─── 步骤 3：Slot 选择 ─────────────────────────────────────────────

  @Builder
  renderSlotStep() {
    Column({ space: this.tm.current.value10 }) {
      // 提示文字（根据尺寸显示不同的提示）
      if (this.vm.selectedSize === WidgetSize.SIZE_1x2) {
        Text($r('app.string.widget_select_account_hint'))
          .fontSize(this.tm.current.body12.size)
          .fontColor(this.tm.current.colorTextSecondary)
          .width(this.tm.current.full)
          .margin({ bottom: this.tm.current.value8 })
      } else {
        Text(`已选 ${this.vm.selectedSlots.length}/${this.vm.getMaxSlots()} 个角色`)
          .fontSize(this.tm.current.body12.size)
          .fontColor(this.tm.current.colorPrimary)
          .width(this.tm.current.full)
          .margin({ bottom: this.tm.current.value8 })
      }

      // 所有账号的所有角色列表
      ForEach(this.vm.getAllSlots(), (slot: WidgetSlotRef) => {
        this.SlotOption(slot)
      }, (slot: WidgetSlotRef) => slot.key)
    }
    .width(this.tm.current.full)
  }

  @Builder
  SlotOption(slot: WidgetSlotRef) {
    Row() {
      // 左侧：游戏色条
      Column()
        .width(3)
        .height(this.tm.current.value36)
        .borderRadius(2)
        .backgroundColor(getGameColor(slot.gameId))

      // 中间：账号 + 游戏 + 角色信息
      Column() {
        Row({ space: this.tm.current.value4 }) {
          Text(slot.accountName)
            .fontSize(this.tm.current.body13Bold.size)
            .fontWeight(this.tm.current.body13Bold.weight)
            .fontColor(this.vm.isSlotSelected(slot.accountId, slot.gameId, slot.roleId) ?
              this.tm.current.colorPrimary : this.tm.current.colorTextPrimary)

          Text('·')
            .fontSize(this.tm.current.body13.size)
            .fontColor(this.tm.current.colorTextSecondary)

          Text(getGameName(slot.gameId) as string)
            .fontSize(this.tm.current.body12.size)
            .fontColor(getGameColor(slot.gameId))
        }

        Row({ space: this.tm.current.value4 }) {
          Text(slot.nickname)
            .fontSize(this.tm.current.body12.size)
            .fontColor(this.tm.current.colorTextSecondary)

          Text(`UID ${slot.roleId}`)
            .fontSize(this.tm.current.body10.size)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .margin({ top: this.tm.current.value2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: this.tm.current.value12 })

      // 右侧：选中状态
      Row() {
        if (this.vm.isSlotSelected(slot.accountId, slot.gameId, slot.roleId)) {
          Text('✓')
            .fontSize(this.tm.current.body12.size)
            .fontColor(Color.White)
        }
      }
      .width(this.tm.current.value18)
      .height(this.tm.current.value18)
      .borderRadius(this.tm.current.value9)
      .backgroundColor(this.vm.isSlotSelected(slot.accountId, slot.gameId, slot.roleId) ?
        getGameColor(slot.gameId) : Color.Transparent)
      .border({
        width: 2,
        color: this.vm.isSlotSelected(slot.accountId, slot.gameId, slot.roleId) ?
          getGameColor(slot.gameId) : this.tm.current.colorDivider
      })
      .justifyContent(FlexAlign.Center)
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value14)
    .backgroundColor(this.vm.isSlotSelected(slot.accountId, slot.gameId, slot.roleId) ?
      'rgba(58,111,216,0.08)' : Color.Transparent)
    .borderRadius(this.tm.current.radius12)
    .border({
      width: 1,
      color: this.vm.isSlotSelected(slot.accountId, slot.gameId, slot.roleId) ?
        'rgba(58,111,216,0.3)' : this.tm.current.colorDivider
    })
    .onClick(() => { this.vm.toggleSlot(slot); })
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function WidgetSettingsBuilder(_name: string, _param: Object) {
  WidgetSettings()
}
