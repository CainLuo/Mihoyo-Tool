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
    .title($r('app.string.setting_title'))
    .padding(0)
  }
}
