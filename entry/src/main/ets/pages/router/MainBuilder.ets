import { Main } from '../Main';

@Builder
export function MainBuilder(_name: string, _param: Object) {
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
