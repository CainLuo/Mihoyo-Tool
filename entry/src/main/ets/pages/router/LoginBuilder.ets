import { Login } from '../Login';

@Builder
export function LoginBuilder(_name: string, _param: Object) {
  LoginDestination()
}

@Component
struct LoginDestination {
  build() {
    NavDestination() {
      Login()
    }
    .title($r('app.string.login_title'))
    .hideTitleBar(false)
  }
}
