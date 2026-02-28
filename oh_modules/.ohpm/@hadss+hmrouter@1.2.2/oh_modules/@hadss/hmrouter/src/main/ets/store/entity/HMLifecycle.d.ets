import { IHMLifecycle } from '../../api/IHMLifecycle';
import { HMLifecycleInstance } from '../ComponentInstance';
import { HMComponent } from './HMComponent';
@Sendable
export declare class HMLifecycleData extends HMComponent {
    /**
     * lifecycleName
     */
    lifecycleName: string;
    /**
     * 优先级，默认9，值越大优先级越高
     */
    priority: number;
    /**
     * 是否全局，默认false
     */
    global?: boolean;
    constructor();
}
/**
 * HMLifecycleStoreData
 */
export declare class HMLifecycleStoreData {
    lifecycle?: IHMLifecycle;
    hmLifecycleData: HMLifecycleData;
}
/**
 * page lifecycle data,
 */
export interface HMPageLifecycleData {
    pageUrl: string;
    hmLifecycleInstance: HMLifecycleInstance;
    navigationId?: string;
    navDestinationId?: string;
}
