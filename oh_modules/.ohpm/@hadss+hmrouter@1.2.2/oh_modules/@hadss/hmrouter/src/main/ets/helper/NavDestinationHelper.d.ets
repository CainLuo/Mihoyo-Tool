import { AttributeUpdater } from '@kit.ArkUI';
/**
 * Page gesture animation binding gesture events
 */
export declare class NavDestinationGestureModifier implements GestureModifier {
    gestureEvent?: UIGestureEvent;
    applyGesture(event: UIGestureEvent): void;
    /**
     * Bind gesture events according to gesture animation
     * @param navDestinationInfo
     */
    registerGestureEvent(navDestinationInfo: NavDestinationInfo): void;
}
/**
 * Page animation registration and destroy
 */
export declare class NavDestinationUpdater extends AttributeUpdater<NavDestinationAttribute> {
    helper?: NavDestinationHelper;
    constructor();
    initializeModifier(instance: NavDestinationAttribute): void;
    registerAnimator(navDestinationInfo: NavDestinationInfo): void;
}
export declare class NavDestinationHelper {
    private _navDestinationInfo?;
    private get navDestinationInfo();
    private navDestinationLifecycleMgr;
    private component;
    modifier: NavDestinationUpdater;
    gestureModifier: NavDestinationGestureModifier;
    sdkApiVersion: number;
    constructor(component: CustomComponent);
    /**
     * Release animation and lifecycle cache
     */
    private destroy;
    /**
     * Get page information
     * @param component
     * @returns
     */
    private getNavDestinationInfo;
    onWillAppear(): void;
    onAppear(): void;
    onReady(ctx: NavDestinationContext): void;
    onWillShow(): void;
    onShown(): void;
    onWillHide(): void;
    onHidden(): void;
    onWillDisappear(): void;
    onDisAppear(): void;
    onBackPressed(): boolean;
    onResult(callback?: ESObject): void;
    onActive(callback?: NavDestinationActiveReason): void;
    onInactive(callback?: NavDestinationActiveReason): void;
    onNewParam(callback?: ESObject): void;
}
