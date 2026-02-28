import { InterceptorContext } from './HMInterceptorInfo';
/**
 * Implementation of InterceptorContext
 * Provides a context for interceptors to share data during a single navigation operation
 */
export declare class HMInterceptorContextImpl implements InterceptorContext {
    private dataMap;
    /**
     * Get data from the context
     * @param key The key to retrieve data
     * @returns The data associated with the key, or undefined if not found
     */
    getData<T>(key: string): T | undefined;
    /**
     * Set data in the context
     * @param key The key to store data
     * @param value The value to store
     */
    setData<T>(key: string, value: T): void;
    /**
     * Clear all data in the context
     * This should be called when the navigation operation is complete
     */
    clear(): void;
}
