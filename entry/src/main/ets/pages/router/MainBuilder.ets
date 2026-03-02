import { Main } from '../Main';

@Builder
export function MainBuilder(_name: string, _param: object) {
  MainDestination()
}

@Component
struct MainDestination {
  build() {
    NavDestination() {
      Main()
    }
    .hideTitleBar(true)
  }
}
