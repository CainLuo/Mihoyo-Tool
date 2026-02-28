import { router } from '@kit.ArkUI';
export declare class HMPageLifecycle {
    private routerInfo;
    private navbarLifecycleMgr;
    constructor(routerInfo: router.RouterState);
    onDisAppear(): void;
    onShown(): void;
    onHidden(): void;
    onBackPressed(): boolean;
    onResult(callback?: ESObject): void;
    onActive(callback?: ESObject): void;
    onInactive(callback?: ESObject): void;
    onNewParam(callback?: ESObject): void;
}
