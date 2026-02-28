import { AttributeUpdater } from '@kit.ArkUI';
import { OpacityOption, ScaleOption, TranslateOption } from '../template/AnimatorModel';
export declare class HMAnimatorHandle {
    translateOption: TranslateOption;
    scaleOption: ScaleOption;
    opacityOption: OpacityOption;
    extendOption?: ESObject;
    modifier?: AttributeUpdater<NavDestinationAttribute>;
    startCallback?: AnimatorCallback;
    finishCallback?: AnimatorCallback;
    onFinishCallback?: AnimatorCallback;
    passiveStartCallback?: AnimatorCallback;
    passiveFinishCallback?: AnimatorCallback;
    passiveOnFinishCallback?: AnimatorCallback;
    customAnimationCallback?: CustomAnimatorCallback;
    passiveCustomAnimationCallback?: CustomAnimatorCallback;
    actionStartCallback?: (event: GestureEvent) => void;
    updateProgressCallback?: InteractiveCallback;
    actionEndCallback?: InteractiveCallback;
    actionCancelCallback?: InteractiveCancelCallback;
    startOffset?: number;
    timeout?: number;
    duration: number;
    curve: Curve | string | ICurve;
    constructor(translateOption?: TranslateOption, scaleOption?: ScaleOption, opacityOption?: OpacityOption, extendOption?: ESObject, modifier?: AttributeUpdater<NavDestinationAttribute>);
    /**
     * custom transition start callback
     * define translate/scale/opacity setting of beginning state
     * @param callback
     * @returns
     */
    start(callback: AnimatorCallback): HMAnimatorHandle;
    /**
     * custom transition finish callback
     * define translate/scale/opacity setting of ending state
     * @param callback
     * @returns
     */
    finish(callback: AnimatorCallback): HMAnimatorHandle;
    /**
     * custom transition onFinish callback
     * define translate/scale/opacity setting after ending state
     * @param callback
     * @returns
     */
    onFinish(callback: AnimatorCallback): HMAnimatorHandle;
    /**
     * custom animate
     * @param callback
     * @returns
     */
    customAnimation(callback: AnimatorCallback): HMAnimatorHandle;
    /**
     * custom transition of passive triggered start callback
     * @param callback
     * @returns
     */
    passiveStart(callback: AnimatorCallback): HMAnimatorHandle;
    /**
     * custom transition of passive triggered finish callback
     * @param callback
     * @returns
     */
    passiveFinish(callback: AnimatorCallback): HMAnimatorHandle;
    /**
     * custom transition of passive triggered onFinish callback
     * @param callback
     * @returns
     */
    passiveOnFinish(callback: AnimatorCallback): HMAnimatorHandle;
    /**
     * custom passive animate
     * @param callback
     * @returns
     */
    passiveCustomAnimation(callback: AnimatorCallback): HMAnimatorHandle;
    /**
     * interactive transition of gesture triggered start callback
     * @param callback
     */
    actionStart(callback: (event: GestureEvent) => void): void;
    /**
     * interactive transition of gesture triggered update progress callback
     * @param callback
     */
    updateProgress(callback: InteractiveCallback): void;
    /**
     * interactive transition of gesture triggered end callback
     * @param callback
     */
    actionEnd(callback: InteractiveCallback): void;
    /**
     * interactive transition of gesture triggered cancel callback
     * @param callback
     */
    actionCancel(callback: InteractiveCancelCallback): void;
}
export declare class HMAnimatorController extends HMAnimatorHandle {
    interactive: boolean;
    operation?: NavigationOperation;
    proxy?: NavigationTransitionProxy;
    constructor(translateOption?: TranslateOption, scaleOption?: ScaleOption, opacityOption?: OpacityOption, extendOption?: ESObject, modifier?: AttributeUpdater<NavDestinationAttribute>);
    doStart(): void;
    doFinish(): void;
    doOnFinish(): void;
    doCustomAnimation(proxy: NavigationTransitionProxy): void;
    doPassiveStart(): void;
    doPassiveFinish(): void;
    doPassiveOnFinish(): void;
    doPassiveCustomAnimation(proxy: NavigationTransitionProxy): void;
    doActionStart(event: GestureEvent): void;
    doUpdateProgress(event: GestureEvent): void;
    doActionEnd(event: GestureEvent): void;
    doActionCancel(): void;
    recoverState(): void;
}
type NormalAnimationCallback = (translateOption: TranslateOption, scaleOption: ScaleOption, opacityOption: OpacityOption, extendOption?: ESObject) => void;
type ModifierAnimationCallback = (modifier: AttributeUpdater<NavDestinationAttribute>) => void;
export type AnimatorCallback = NormalAnimationCallback | ModifierAnimationCallback | undefined;
type NormalCustomAnimationCallback = (translateOption: TranslateOption, scaleOption: ScaleOption, opacityOption: OpacityOption, extendOption: ESObject, proxy: NavigationTransitionProxy) => void;
type ModifierCustomAnimationCallback = (modifier: AttributeUpdater<NavDestinationAttribute>, proxy: NavigationTransitionProxy) => void;
export type CustomAnimatorCallback = NormalCustomAnimationCallback | ModifierCustomAnimationCallback | undefined;
type InteractiveCallback = (event: GestureEvent, proxy?: NavigationTransitionProxy, operation?: NavigationOperation, startOffset?: number) => void;
type InteractiveCancelCallback = () => void;
export {};
