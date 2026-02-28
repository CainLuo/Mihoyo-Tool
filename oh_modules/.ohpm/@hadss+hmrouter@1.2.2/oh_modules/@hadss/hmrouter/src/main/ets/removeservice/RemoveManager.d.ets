import { HMRouterPathInfo } from '../api/HMRouterPathInfo';
export declare class RemoveManager {
    private static instance;
    private isExecutingCallback;
    private removeMap?;
    static getInstance(): RemoveManager;
    addRemoveListener(callback: RemoveCallback, options: RemoveListenerOptions): void;
    deleteRemoveListener(callback: RemoveCallback): void;
    clearRemoveListener(): void;
    notifyRemoveListener(removePagesInfo: HMRouterPathInfo[]): void;
}
export interface RemoveListenerOptions {
    navigationId: string;
}
export type RemoveCallback = (removePagesInfo: HMRouterPathInfo[]) => boolean | void;
