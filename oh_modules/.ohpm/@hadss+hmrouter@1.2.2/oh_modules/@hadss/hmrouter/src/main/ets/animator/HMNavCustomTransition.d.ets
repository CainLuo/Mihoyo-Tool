import { HMAnimatorController } from './HMAnimatorHandle';
export declare class HMNavCustomTransition {
    private static readonly transitionMap;
    proxy: NavigationTransitionProxy | undefined;
    operation: NavigationOperation;
    private navigationId;
    private uiContext;
    private animatorMgr;
    private constructor();
    static getInstance(navigationId: string, uiContext: UIContext): HMNavCustomTransition;
    static destroyInstance(navigationId: string): void;
    getCustomAnimation(from: NavContentInfo, to: NavContentInfo, operation: NavigationOperation): NavigationAnimatedTransition | undefined;
    private getPushOrReplaceOnceAnimatorHandle;
    private getPopOnceAnimatorHandle;
    private getPushOrReplacePageAnimatorHandle;
    private getPopPageAnimatorHandle;
    private animatedTransition;
}
export declare class HandleTuple {
    enterAnimatorHandle: HMAnimatorController | undefined;
    exitAnimatorHandle: HMAnimatorController | undefined;
}
