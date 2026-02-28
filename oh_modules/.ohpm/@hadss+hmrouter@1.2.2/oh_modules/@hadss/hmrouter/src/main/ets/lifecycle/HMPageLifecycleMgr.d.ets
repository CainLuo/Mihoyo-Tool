import { HMPageLifecycle } from './HMPageLifecycle';
export declare class HMPageLifecycleMgr {
    private static instance;
    private pageLifecycleMap;
    static getInstance(): HMPageLifecycleMgr;
    /**
     * Create a page lifecycle instance
     * @returns pageLifecycleId
     */
    createPageLifecycle(uiContext: UIContext): string;
    /**
     * Get page lifecycle instance
     * @returns
     */
    getPageLifecycle(pageLifecycleId: string): HMPageLifecycle | undefined;
}
