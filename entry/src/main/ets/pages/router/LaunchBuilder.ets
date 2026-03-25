import { Launch } from '../Launch';

@Builder
export function LaunchBuilder(_name: string, _param: Object) {
  LaunchDestination()
}

@Component
struct LaunchDestination {
  build() {
    NavDestination() {
      Launch()
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.color_page_bg'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
