import { Setting } from '../Setting';

@Builder
export function SettingBuilder(_name: string, _param: object) {
  SettingDestination()
}

@Component
struct SettingDestination {
  build() {
    NavDestination() {
      Setting()
    }
    .hideTitleBar(true)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
  }
}
