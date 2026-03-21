import { Login } from '../Login';

@Builder
export function LoginBuilder(_name: string, _param: object) {
  LoginDestination()
}

@Component
struct LoginDestination {
  build() {
    NavDestination() {
      Login()
    }
    .title($r('app.string.login_title'))
  }
}
