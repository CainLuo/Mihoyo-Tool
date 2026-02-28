import { router } from '@kit.ArkUI';
import { HMNavPathStack } from '../router/HMNavPathStack';
import { HMLifecycleState } from '../api/HMLifecycleState';
import { HMNavBarLifecycleObserver } from './implement/HMNavBarLifecycleOwner';
import { NavBarParentTypes } from './enums/NavBarParentTypes';
import { NavBarLifecycleKey } from './interface/NavBarLifecycleKey';
export declare class HMNavBarLifecycleMgr {
    private static instance;
    private lifecycleMap;
    private navDestinationLifecycleMgr;
    private uiContext;
    static getInstance(): HMNavBarLifecycleMgr;
    /**
     * Generate Key through PathStack corresponding to NavBar
     * @param pathStack
     * @param routerInfo
     * @returns
     */
    generateNavBarLifecycleKey(pathStack: HMNavPathStack): NavBarLifecycleKey;
    /**
     * Create NavBar lifecycle owner
     * @param pathStack
     * @returns
     */
    createNavBarLifecycleOwner(pathStack: HMNavPathStack): HMNavBarLifecycleObserver;
    /**
     * When the NavBar is destroyed, recycle the NavBar lifecycle
     * @param key
     */
    deleteNavBarLifecycle(key: NavBarLifecycleKey): void;
    /**
     * Execute the NavBar lifecycle when a page navigation occurs within the NavBar or when the Router navigates
     * @param state
     * @param parentType
     * @param stackInfo
     * @returns
     */
    dispatchEvent(state: HMLifecycleState, parentType: NavBarParentTypes, stackInfo: HMNavPathStack | router.RouterState, callback?: ESObject): void | boolean;
    /**
     * Check the corresponding lifecycle instance
     * @param key
     * @returns
     */
    private getLifecycleOwner;
}
