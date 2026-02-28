interface HMNavPathInfo {
    name: string;
    param?: Object;
}
/**
 * Indicates the information of the popped page.
 *
 */
export interface HMPopInfo extends PopInfo {
    srcPageInfo: HMNavPathInfo;
}
/**
 * Router callback
 */
export interface HMRouterPathCallback {
    /**
     * The callback when page returns.
     * @param popInfo
     */
    onResult?: (popInfo: HMPopInfo) => void;
    /**
     * The callback when system push executed successfully.
     */
    onArrival?: () => void;
    /**
     * The callback when page could not be found.
     */
    onLost?: () => void;
}
export {};
