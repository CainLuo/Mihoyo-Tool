import { HMLifecycleCallback, IHMLifecycle } from '../../api/IHMLifecycle';
import { HMLifecycleState } from '../../api/HMLifecycleState';
export interface IHMLifecycleOwner {
    addObserver(state: HMLifecycleState, callback: HMLifecycleCallback, priority?: number): void;
    removeObserver(state: HMLifecycleState, callback?: HMLifecycleCallback): void;
    getLifecycle(): IHMLifecycle | undefined;
}
