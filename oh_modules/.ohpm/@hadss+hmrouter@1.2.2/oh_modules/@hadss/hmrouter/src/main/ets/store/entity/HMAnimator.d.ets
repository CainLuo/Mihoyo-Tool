import { IHMAnimator } from '../../api/IHMAnimator';
import { HMComponent } from './HMComponent';
/**
 * HMAnimatorData
 */
@Sendable
export declare class HMAnimatorData extends HMComponent {
    /**
     * animatorName
     */
    animatorName: string;
    constructor();
}
/**
 * HMAnimatorStoreData
 */
export declare class HMAnimatorStoreData {
    animator?: IHMAnimator;
    hmAnimatorData?: HMAnimatorData;
}
