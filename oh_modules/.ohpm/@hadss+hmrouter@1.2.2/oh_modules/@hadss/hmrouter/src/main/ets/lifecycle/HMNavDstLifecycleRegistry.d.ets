import { AllLifecycleState } from '../api/HMLifecycleState';
import { HMNavDstLifecycleOwner } from './implement/HMNavDstLifecycleOwner';
import { NavDstLifecycleKey } from './interface/NavDstLifecycleKey';
import { IHMLifecycle } from '../api/IHMLifecycle';
/**
 * * Lifecycle management class for NavDestination pages in Navigation, managing the lifecycle of all NavDestinations
 * in Navigation
 */
export declare class HMNavDstLifecycleRegistry {
    private lifecycleMap;
    private uiContext;
    constructor(uiContext: UIContext);
    getLifecycleMap(): Map<NavDstLifecycleKey, HMNavDstLifecycleOwner>;
    /**
     * Get the lifecycle through PageUrl; if the page has multiple instances in the stack, return only the last one
     * @param pageUrl
     * @returns
     */
    getLifecycleOwnerByPageUrl(pageUrl: string): HMNavDstLifecycleOwner | null;
    /**
     * Create NavDestination page corresponding lifecycle
     * @param pageUrl
     * @param singleton
     * @returns
     */
    createLifecycle(pageUrl: string, lifecycle?: IHMLifecycle, singleton?: boolean): HMNavDstLifecycleOwner;
    /**
     * 更新NavDestination生命周期中的navDestinationId
     * @param pageUrl
     * @param navDestinationId
     * @returns
     */
    updateLifecycleKey(pageUrl: string, navContext: NavDestinationContext): boolean;
    /**
     * When the page is destroyed, remove the corresponding lifecycle instance
     * @param pageUrl
     * @param navDestinationId
     * @returns
     */
    destroyLifecycle(pageUrl: string, navDestinationId: string): boolean;
    dispatch(state: AllLifecycleState, pageUrl: string, navDestinationId?: string, callback?: ESObject): boolean | void;
    /**
     * Get the lifecycle instance
     * @param key
     * @param singleton
     * @returns
     */
    private getLifecycleOwnerByKey;
}
