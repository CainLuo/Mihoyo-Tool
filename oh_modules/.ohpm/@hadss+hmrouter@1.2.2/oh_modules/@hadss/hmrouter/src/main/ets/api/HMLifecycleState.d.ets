export declare enum HMLifecycleState {
    onDisAppear = "onDisAppear",
    onShown = "onShown",
    onHidden = "onHidden",
    onWillDisappear = "onWillDisappear",
    onWillShow = "onWillShow",
    onWillHide = "onWillHide",
    onBackPressed = "onBackPressed",
    onResult = "onResult",
    onActive = "onActive",
    onInactive = "onInactive",
    onNewParam = "onNewParam"
}
export declare enum InnerLifecycleState {
    onPrepare = "onPrepare",
    onAppear = "onAppear",
    onWillAppear = "onWillAppear",
    onReady = "onReady"
}
export type AllLifecycleState = HMLifecycleState | InnerLifecycleState;
