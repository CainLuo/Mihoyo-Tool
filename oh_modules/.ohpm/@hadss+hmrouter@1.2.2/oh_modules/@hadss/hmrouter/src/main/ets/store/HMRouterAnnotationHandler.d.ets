import { HMComponent } from './entity/HMComponent';
import { RouterItem } from './entity/BundleInfo';
import { HMRouterStoreImpl } from './HMRouterStoreImpl';
export interface HMRouterAnnotationHandler {
    parseRouterItem(item: RouterItem): HMComponent;
    handlerHMComponent(hmComponent: HMComponent, hmRouterStore: HMRouterStoreImpl): void;
}
export declare class HMRouterAnnotationFactory {
    private hmRouterAnnotationHandlerMap;
    constructor();
    create(name: string): HMRouterAnnotationHandler | undefined;
}
