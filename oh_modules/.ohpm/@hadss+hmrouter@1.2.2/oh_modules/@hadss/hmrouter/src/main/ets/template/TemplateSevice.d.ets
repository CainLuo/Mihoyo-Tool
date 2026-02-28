import { OpacityOption, ScaleOption, TranslateOption } from './AnimatorModel';
export declare class TemplateService {
    private static animatorMgr;
    private static navDestinationLifecycleMgr;
    static aboutToAppear(navigationId: string, pageUrl: string, dialog: boolean, translateOption: TranslateOption, scaleOption: ScaleOption, opacityOption: OpacityOption, extendOption?: ESObject): void;
    static aboutToDisappear(navigationId: string, pageUrl: string, ndId: string): void;
    static onDisAppear(navigationId: string, pageUrl: string, navId: string): void;
    static onAppear(navigationId: string, pageUrl: string, navId: string): void;
    static onShown(navigationId: string, pageUrl: string, navId: string): void;
    static onHidden(navigationId: string, pageUrl: string, navId: string): void;
    static onWillAppear(navigationId: string, pageUrl: string): void;
    static onWillDisappear(navigationId: string, pageUrl: string, navId: string): void;
    static onWillShow(navigationId: string, pageUrl: string, navId: string): void;
    static onWillHide(navigationId: string, pageUrl: string, navId: string): void;
    static onReady(navigationId: string, pageUrl: string, navContext: NavDestinationContext): void;
    static onBackPressed(navigationId: string, pageUrl: string, navId: string): boolean;
    static onResult(navigationId: string, pageUrl: string, navId: string, callback?: ESObject): void;
    static onActive(navigationId: string, pageUrl: string, navId: string, callback?: ESObject): void;
    static onInactive(navigationId: string, pageUrl: string, navId: string, callback?: ESObject): void;
    static onNewParam(navigationId: string, pageUrl: string, navId: string, callback?: ESObject): void;
    static interactiveStart(navigationId: string, ndId: string, event: GestureEvent): void;
    static interactiveFinish(navigationId: string, ndId: string, event: GestureEvent): void;
    static interactiveProgress(navigationId: string, ndId: string, event: GestureEvent): void;
    static interactiveCancel(navigationId: string, ndId: string): void;
}
