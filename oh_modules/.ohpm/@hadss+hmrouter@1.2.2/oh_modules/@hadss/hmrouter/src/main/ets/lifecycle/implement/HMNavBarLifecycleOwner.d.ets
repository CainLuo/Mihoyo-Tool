import { HMLifecycleState } from '../../api/HMLifecycleState';
import { HMLifecycleOwner } from './HMLifecycleOwner';
export declare class HMNavBarLifecycleObserver extends HMLifecycleOwner {
    navbarState?: HMLifecycleState;
    constructor(parentLifecycle?: HMLifecycleOwner);
}
