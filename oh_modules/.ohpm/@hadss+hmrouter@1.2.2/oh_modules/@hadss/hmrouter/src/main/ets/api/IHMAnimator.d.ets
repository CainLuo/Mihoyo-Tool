import { HMAnimatorHandle } from '../animator/HMAnimatorHandle';
export interface IHMAnimator {
    effect(enterHandle: HMAnimatorHandle, exitHandle: HMAnimatorHandle): void;
    interactive?(handle: HMAnimatorHandle): void;
}
export declare namespace IHMAnimator {
    interface EffectOptions {
        direction?: IHMAnimator.Direction;
        opacity?: IHMAnimator.OpacityOption;
        scale?: IHMAnimator.ScaleOption;
        duration?: number;
        curve?: Curve | string | ICurve;
    }
    interface TranslateOption {
        x?: number | string;
        y?: number | string;
        z?: number | string;
    }
    interface ScaleOption {
        x?: number;
        y?: number;
        centerX?: number | string;
        centerY?: number | string;
    }
    interface OpacityOption {
        opacity?: number;
    }
    enum Direction {
        RIGHT_TO_LEFT = 0,
        LEFT_TO_RIGHT = 1,
        BOTTOM_TO_TOP = 2,
        TOP_TO_BOTTOM = 3
    }
    class Effect {
        effectOption: IHMAnimator.EffectOptions;
        constructor(effectOption: IHMAnimator.EffectOptions);
        toAnimator(): IHMAnimator;
    }
}
