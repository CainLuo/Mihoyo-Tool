import { GenshinDailyDetail, GenshinDailyDetailParam } from '../GenshinDailyDetail'

@Builder
export function GenshinDailyDetailBuilder(_name: string, param: object) {
  GenshinDailyDetailDestination({ routerParam: param as GenshinDailyDetailParam })
}

@Component
struct GenshinDailyDetailDestination {
  @Prop routerParam: GenshinDailyDetailParam = new GenshinDailyDetailParam()

  build() {
    NavDestination() {
      GenshinDailyDetail({ routerParam: this.routerParam })
    }
    .hideTitleBar(true)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
  }
}
