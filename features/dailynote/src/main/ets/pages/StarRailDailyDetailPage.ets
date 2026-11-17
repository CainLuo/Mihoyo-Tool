/**
 * StarRailDailyDetailPage — 崩坏：星穹铁道实时便笺详情页（View 层）
 */

import { themeManager, ThemeManager } from 'basic'
import { DailyNoteStarRail } from '../views/starrail/DailyNoteStarRail'
import { StarRailDailyDetailViewModel } from '../viewmodel/StarRailDailyDetailViewModel'
import { DailyDetailScaffold } from '../views/common/DailyDetailScaffold'

/** 系统 Navigation 传入的路由参数 */
export class StarRailDailyDetailParam {
  accountId: string = '';
  roleUid: string = '';
}

@ComponentV2
export struct StarRailDailyDetailPage {
  @Param routerParam: StarRailDailyDetailParam = new StarRailDailyDetailParam()
  @Local private tm: ThemeManager = themeManager
  @Local private vm: StarRailDailyDetailViewModel = new StarRailDailyDetailViewModel()

  aboutToAppear(): void {
    this.vm.init(this.routerParam.accountId, this.routerParam.roleUid)
    this.vm.loadData()
  }

  @Builder
  gameContent() {
    DailyNoteStarRail({ data: this.vm.note })
      .padding({ left: this.tm.current.font16, right: this.tm.current.font16 })
  }

  build() {
    DailyDetailScaffold({
      title: $r('app.string.starrail_daily_title'),
      viewState: this.vm.viewState,
      content: () => { this.gameContent() }
    })
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct StarRailDailyDetailPagePreview {
  build() {
    StarRailDailyDetailPage({ routerParam: new StarRailDailyDetailParam() })
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function StarRailDailyDetailPageBuilder(_name: string, param: Object) {
  StarRailDailyDetailPage({ routerParam: param as StarRailDailyDetailParam })
}
