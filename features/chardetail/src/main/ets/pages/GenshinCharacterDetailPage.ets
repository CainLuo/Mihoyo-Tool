/**
 * GenshinCharacterDetailPage — 角色详情页（View 层）
 */
import { UIContext } from '@kit.ArkUI'
import { themeManager, ThemeManager, ViewState, showFeedback, FeedbackType, AppRoutes } from 'basic'
import { GenshinCharacterDetailViewModel } from '../viewmodel/GenshinCharacterDetailViewModel'
import { CharDetailLoadingView } from '../views/common/CharDetailLoadingView'
import { CharDetailEmptyView } from '../views/common/CharDetailEmptyView'
import { CharDetailPortraitLayout } from '../views/genshin/CharDetailPortraitLayout'
import { CharDetailLandscapeLayout } from '../views/genshin/CharDetailLandscapeLayout'
import { CharDetailWideLayout } from '../views/genshin/CharDetailWideLayout'
import { CharDetailRouterParam } from '../model/CharDetailModels'
import { CharDetailWindowSize, resolveCharDetailBreakpoint } from '../utils/CharDetailWindowSize'
import { MaterialCalcParam } from 'material'

/** 原神角色详情路由参数（与 CharDetailRouterParam 字段一致，保留别名供 Builder 使用） */
export type GenshinCharacterDetailParam = CharDetailRouterParam;

@ComponentV2
export struct GenshinCharacterDetailPage {
  @Param routerParam: GenshinCharacterDetailParam = new CharDetailRouterParam()
  @Local private tm: ThemeManager = themeManager
  @Local private vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel()
  @Local private windowWidthVp: number = themeManager.current.value360
  @Local private windowHeightVp: number = 780
  @Local private currentBreakpoint: string = 'xs'

  private uiCtx: UIContext | null = null
  private localStack: NavPathStack | null = null
  private windowSize: CharDetailWindowSize | null = null

  aboutToAppear(): void {
    const ctx = this.getUIContext()
    this.uiCtx = ctx
    this.windowSize = new CharDetailWindowSize(ctx, (w: number, h: number) => {
      this.windowWidthVp = w
      this.windowHeightVp = h
    })
    this.windowSize.attach()
    this.vm.init(this.routerParam.accountId, this.routerParam.roleUid, this.routerParam.entityId)
    this.vm.loadData()
  }

  @Monitor('vm.networkErrorMsg')
  onNetworkError(_monitor: IMonitor): void {
    const msg = this.vm.networkErrorMsg
    if (msg === '') { return }
    this.vm.networkErrorMsg = ''
    const ctx = this.uiCtx
    if (ctx === null) { return }
    showFeedback(ctx, FeedbackType.ERROR, msg)
  }

  aboutToDisappear(): void {
    if (this.windowSize !== null) {
      this.windowSize.detach()
      this.windowSize = null
    }
  }

  private isPhoneLandscape(): boolean {
    return this.currentBreakpoint === 'xs' && this.windowWidthVp > this.windowHeightVp
  }

  private isPhonePortrait(): boolean {
    return this.currentBreakpoint === 'xs' && this.windowWidthVp <= this.windowHeightVp
  }

  /**
   * 跳转到材料计算页
   */
  private goToMaterialCalc(): void {
    if (this.localStack !== null) {
      const params: MaterialCalcParam = {
        accountId: this.routerParam.accountId,
        roleUid: this.routerParam.roleUid,
        avatarId: this.routerParam.entityId
      };
      this.localStack.pushPathByName(AppRoutes.MATERIAL_CALC, params);
    }
  }

  build() {
    NavDestination() {
      Column() {
        if (this.vm.viewState === ViewState.LOADING) {
          CharDetailLoadingView()
        } else if (this.vm.viewState === ViewState.EMPTY || this.vm.viewState === ViewState.ERROR) {
          CharDetailEmptyView()
        } else {
          if (this.isPhonePortrait()) {
            CharDetailPortraitLayout({ vm: this.vm, onMaterialCalcTap: () => { this.goToMaterialCalc() } })
          } else if (this.isPhoneLandscape()) {
            CharDetailLandscapeLayout({ vm: this.vm, onMaterialCalcTap: () => { this.goToMaterialCalc() } })
          } else {
            CharDetailWideLayout({ vm: this.vm, onMaterialCalcTap: () => { this.goToMaterialCalc() } })
          }
        }
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .backgroundColor(this.tm.current.bgPageDeep)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .onAreaChange((_old, newArea) => {
        this.currentBreakpoint = resolveCharDetailBreakpoint(newArea.width as number)
      })
    }
    .title($r('app.string.char_detail_title'))
    .hideTitleBar(false)
    .onReady((ctx: NavDestinationContext) => { this.localStack = ctx.pathStack })
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct GenshinCharacterDetailPagePreview {
  build() {
    GenshinCharacterDetailPage({ routerParam: new CharDetailRouterParam() })
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function GenshinCharacterDetailPageBuilder(_name: string, param: Object) {
  GenshinCharacterDetailPage({ routerParam: param as GenshinCharacterDetailParam })
}
