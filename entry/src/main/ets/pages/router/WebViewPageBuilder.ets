import { WebViewPage, WebViewParam } from '../WebViewPage'

@Builder
export function WebViewPageBuilder(_name: string, param: Object) {
  WebViewPage({ routerParam: param as WebViewParam })
}
