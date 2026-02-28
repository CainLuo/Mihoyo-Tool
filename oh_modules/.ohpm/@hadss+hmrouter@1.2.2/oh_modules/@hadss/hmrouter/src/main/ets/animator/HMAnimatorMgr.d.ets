import { AttributeUpdater } from '@kit.ArkUI';
import { IHMAnimator } from '../api/IHMAnimator';
import { HMAnimatorController } from './HMAnimatorHandle';
import { OpacityOption, ScaleOption, TranslateOption } from '../template/AnimatorModel';
interface OnceAnimatorMapInterceptor {
    animator: IHMAnimator;
    operation: NavigationOperation;
}
export declare class HMAnimatorMgr {
    private static instance;
    private static interactiveHandleMap;
    private static enterAnimatorHandleMap;
    private static exitAnimatorHandleMap;
    private static onceAnimatorMap;
    isAnimatorPlayNum: number;
    static getInstance(): HMAnimatorMgr;
    /**
     * interactive animation start
     * @param navigationId
     * @param navDestinationId
     * @param event
     */
    interactiveStart(navigationId: string, navDestinationId: string, event: GestureEvent): void;
    /**
     * interactive animation finish
     * @param navigationId
     * @param navDestinationId
     * @param event
     */
    interactiveFinish(navigationId: string, navDestinationId: string, event: GestureEvent): void;
    /**
     * interactive animation progress change
     * @param navigationId
     * @param navDestinationId
     * @param event
     */
    interactiveProgress(navigationId: string, navDestinationId: string, event: GestureEvent): void;
    /**
     * interactive animation action cancel
     * @param navigationId
     * @param navDestinationId
     */
    interactiveCancel(navigationId: string, navDestinationId: string): void;
    getInteractiveAnimatorHandle(navigationId: string, navDestinationId?: string): HMAnimatorController | undefined;
    getOnceAnimator(navigationId: string, info: NavContentInfo): IHMAnimator | undefined;
    /**
     * get once animator
     * @param handleType
     * @param navigationId
     * @param pageUrl
     * @param navDestinationId
     * @returns
     */
    getOnceAnimatorHandle(handleType: HandleType, navigationId: string, info: NavContentInfo, navDestinationId?: string): HMAnimatorController | undefined;
    /**
     * get NavDestination page custom animator
     * @param handleType
     * @param navigationId
     * @param navDestinationId
     * @returns
     */
    getPageAnimatorHandle(handleType: HandleType, navigationId: string, navDestinationId?: string): HMAnimatorController | undefined;
    /**
     * register once animator
     * @param pageUrl
     * @param animator
     */
    registerOnceAnimator(pageUrl: string, animator: OnceAnimatorMapInterceptor): void;
    getAnimator(navigationId: string, info: NavContentInfo): IHMAnimator;
    /**
     * register page animator by navigationId and pageUrl;
     * @param navigationId
     * @param pageUrl
     * @param dialog
     * @param translateOption
     * @param scaleOption
     * @param opacityOption
     */
    registerAnimatorHandle(navigationId: string, pageUrl: string, dialog: boolean, translateOption?: TranslateOption, scaleOption?: ScaleOption, opacityOption?: OpacityOption, extendOption?: ESObject, modifier?: AttributeUpdater<NavDestinationAttribute>): void;
    /**
     * update animator handle key equal pageUrl add navDestinationId
     * @param pageUrl
     * @param navigationId
     * @param navDestinationId
     */
    updateHandleKey(pageUrl: string, navigationId: string, navDestinationId: string): void;
    /**
     * unregister animator
     * @param navigationId
     * @param navDestinationId
     */
    unRegisterAnimatorHandle(navigationId: string, navDestinationId: string, pageUrl: string): void;
    /**
     * Determine whether the page animation exists
     * @param handleType
     * @param navigationId
     * @param navDestinationId
     * @returns
     */
    isPageAnimatorExists(handleType: HandleType, navigationId: string, navDestinationId?: string): boolean;
    /**
     * Determine whether a one-time animation exists
     * @param pageUrl
     * @returns
     */
    isOnceAnimatorExists(handleType: HandleType, navigationId: string, info: NavContentInfo): boolean;
    /**
     * Get global animation
     * @param navigationId
     * @param dialog
     * @returns
     */
    getGlobalNavigationAnimator(navigationId: string, dialog: boolean): IHMAnimator | null;
    /**
     * copy animator handle
     * @param target target handle
     * @param source source handle
     */
    private copyAnimatorHandle;
}
export declare enum HandleType {
    ENTER = 0,
    EXIT = 1
}
export {};
