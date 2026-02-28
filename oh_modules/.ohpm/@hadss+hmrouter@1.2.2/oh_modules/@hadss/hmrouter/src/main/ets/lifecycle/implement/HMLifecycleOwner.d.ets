import { HMLifecycleCallback, HMLifecycleContext, IHMLifecycle } from '../../api/IHMLifecycle';
import { AllLifecycleState, HMLifecycleState } from '../../api/HMLifecycleState';
import { HMLifecycleInstance } from '../../store/ComponentInstance';
import { IHMLifecycleOwner } from '../interface/IHMLifecycleOwner';
export declare abstract class HMLifecycleOwner implements IHMLifecycleOwner {
    navContext?: NavDestinationContext;
    private lifecycleInstance?;
    private onceLifecycle?;
    private observerMap?;
    state?: AllLifecycleState;
    constructor(lifecycleInstance?: HMLifecycleInstance | null, onceLifecycle?: IHMLifecycle);
    getLifecycle(): IHMLifecycle | undefined;
    addObserver(state: HMLifecycleState, callback: HMLifecycleCallback, priority?: number): void;
    removeObserver(state: HMLifecycleState, callback?: HMLifecycleCallback | undefined): void;
    /**
     * dispatch NavDestination lifecycle
     * @param state
     * @param ctx
     * @returns
     */
    dispatch(state: AllLifecycleState, ctx: HMLifecycleContext, callback?: ESObject): boolean | void;
    /**
     * execute NavDestination lifecycle
     * @param state
     * @param lifecycle
     * @returns
     */
    private executeLifecycle;
}
