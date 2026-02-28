/**
 * Lifecycle annotation
 *
 * Define the lifecycle of the page
 * @param param
 * @returns
 */
export declare function HMLifecycle(param: HMLifecycleParam): ObjectConstructor;
export interface HMLifecycleParam {
    lifecycleName: string;
    priority?: number;
    global?: boolean;
}
