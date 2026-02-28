import { AttributeUpdater } from '@kit.ArkUI';
@Observed
export declare class TranslateOption {
    private _x;
    get x(): number | string | undefined;
    set x(value: number | string | undefined);
    private _y;
    get y(): number | string | undefined;
    set y(value: number | string | undefined);
    private modifier?;
    constructor(modifier?: AttributeUpdater<NavDestinationAttribute>);
}
@Observed
export declare class ScaleOption {
    private _x?;
    get x(): number | undefined;
    set x(value: number | undefined);
    private _y?;
    get y(): number | undefined;
    set y(value: number | undefined);
    private _centerX?;
    get centerX(): number | string | undefined;
    set centerX(value: number | string | undefined);
    private _centerY?;
    get centerY(): number | string | undefined;
    set centerY(value: number | string | undefined);
    private modifier?;
    constructor(modifier?: AttributeUpdater<NavDestinationAttribute>);
}
@Observed
export declare class OpacityOption {
    private _opacity;
    get opacity(): number;
    set opacity(value: number);
    private modifier?;
    constructor(modifier?: AttributeUpdater<NavDestinationAttribute>);
}
