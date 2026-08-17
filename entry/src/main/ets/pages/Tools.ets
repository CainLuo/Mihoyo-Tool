/**
 * Tools.ets — 工具页主页面
 *
 * 展示三个游戏的材料总汇入口，处理空态。
 * 作为 Tab 子页面嵌入 Main。
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { UIContext } from '@kit.ArkUI'
import { ViewState } from '../constants/ViewStates'
import { ToolsViewModel } from '../viewmodel/ToolsViewModel'
import { PlaceholderView, PlaceholderState } from '../components/common/PlaceholderView'
import { GameEntryCard } from '../components/tools/GameEntryCard'
import { AppRoutes } from '../constants/AppRoutes'
import { AccountSignal } from '../utils/AccountSignal'
import { GameId } from 'core'
import { GameEntryVM, MaterialTargetConfigParam } from '../models/ToolsModels'

@ComponentV2
export struct Tools {
  @Local private vm: ToolsViewModel = new ToolsViewModel()
  @Local private tm: ThemeManager = themeManager
  @Local private signal: AccountSignal = AccountSignal.instance()
  /** Navigation stack from Main */
  @Param detailStack: NavPathStack | null = null
  private uiContext: UIContext | null = null

  aboutToAppear(): void {
    this.uiContext = this.getUIContext()
    this.vm.loadData()
  }

  /**
   * 监听 AccountSignal.version 变化
   * 当账号登录成功或计算数据同步完成后刷新 Tools 页面
   */
  @Monitor('signal.version')
  onSignalChanged(_monitor: IMonitor): void {
    this.vm.loadData()
  }

  build() {
    Column() {
      if (this.vm.viewState === ViewState.LOADING) {
        // 加载中视图 — 只有 5 行，直接内联
        Column() {
          LoadingProgress()
            .width(this.tm.current.value32)
            .height(this.tm.current.value32)
            .color(this.tm.current.colorPrimary)
        }
        .width(this.tm.current.full)
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.vm.viewState === ViewState.EMPTY) {
        // 空态视图
        PlaceholderView({
          state: {
            icon: '🧰',
            title: $r('app.string.home_placeholder_title'),
            description: $r('app.string.home_placeholder_desc'),
            buttonText: $r('app.string.home_placeholder_button'),
            onButtonTap: () => {
              if (this.detailStack !== null) {
                this.detailStack.pushPathByName(AppRoutes.LOGIN, null)
              }
            }
          } as PlaceholderState
        })
      } else {
        // 内容视图 — 游戏入口列表
        Scroll() {
          Column({ space: this.tm.current.value12 }) {
            ForEach(this.vm.gameEntries, (entry: GameEntryVM) => {
              GameEntryCard({
                entry: entry,
                onTap: () => {
                  this.onEntryTap(entry)
                }
              })
            }, (entry: GameEntryVM) => entry.gameId)
          }
          .width(this.tm.current.full)
          .padding({
            top: this.tm.current.value8,
            left: this.tm.current.value16,
            right: this.tm.current.value16,
            bottom: this.tm.current.value16
          })
        }
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .align(Alignment.Top)
      }
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .backgroundColor(this.tm.current.colorPageBg)
  }

  /**
   * 游戏入口点击处理
   * - 如果已计算角色数 > 0：直接跳转到对应游戏的材料汇总页
   * - 如果已计算角色数 = 0：弹出 Alert，提示用户先去配置
   */
  private onEntryTap(entry: GameEntryVM): void {
    if (!entry.hasData) {
      return
    }

    if (this.detailStack === null) {
      return
    }

    // 构建路由参数（accountId + roleUid + gameId）
    const param: MaterialTargetConfigParam = {
      accountId: entry.accountId,
      roleUid: entry.roleUid,
      gameId: entry.gameId
    }

    // 已有计算数据 → 直接跳转到材料汇总页
    if (entry.computedCount > 0) {
      if (entry.gameId === GameId.GENSHIN) {
        this.detailStack.pushPathByName(AppRoutes.GENSHIN_MATERIAL_LIST, null)
      } else if (entry.gameId === GameId.STARRAIL) {
        this.detailStack.pushPathByName(AppRoutes.STARRAIL_MATERIAL_LIST, null)
      } else if (entry.gameId === GameId.ZZZ) {
        this.detailStack.pushPathByName(AppRoutes.ZZZ_MATERIAL_LIST, null)
      }
      return
    }

    // 无计算数据 → 弹出 Alert 提示用户先配置
    this.uiContext?.showAlertDialog({
      title: $r('app.string.tool_sync_required_title'),
      message: $r('app.string.tool_sync_required_desc'),
      primaryButton: {
        value: $r('app.string.tool_sync_required_button'),
        action: () => {
          // 根据游戏类型跳转到对应的配置页，传递参数
          if (entry.gameId === GameId.GENSHIN) {
            this.detailStack!.pushPathByName(AppRoutes.GENSHIN_MATERIAL_TARGET_CONFIG, param)
          } else if (entry.gameId === GameId.STARRAIL) {
            this.detailStack!.pushPathByName(AppRoutes.STARRAIL_MATERIAL_TARGET_CONFIG, param)
          } else if (entry.gameId === GameId.ZZZ) {
            this.detailStack!.pushPathByName(AppRoutes.ZZZ_MATERIAL_TARGET_CONFIG, param)
          }
        }
      },
      secondaryButton: {
        value: $r('app.string.dialog_cancel'),
        action: () => {}
      }
    })
  }
}

@Preview
@ComponentV2
export struct ToolsPreview {
  build() {
    Tools()
  }
}
