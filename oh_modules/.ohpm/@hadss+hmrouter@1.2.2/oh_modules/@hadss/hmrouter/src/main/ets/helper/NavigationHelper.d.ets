import { AttributeUpdater } from '@kit.ArkUI';
import { HMNavPathStack } from '../router/HMNavPathStack';
/**
 * Binding navigationId
 */
export declare class NavigationUpdater extends AttributeUpdater<NavigationAttribute, NavigationInterface> {
    navigationId: string;
    helper?: NavigationHelper;
    constructor(navigationId: string);
    initializeModifier(instance: NavigationAttribute): void;
}
/**
 * Navigation tool class, used to generate pathStack and animation methods
 */
export declare class NavigationHelper {
    private navBarParent?;
    private component;
    navigationId: string;
    pathStack: HMNavPathStack;
    modifier: NavigationUpdater;
    sdkApiVersion: number;
    constructor(navigationId: string, component: CustomComponent);
    /**
     * Determine whether the route is valid
     * @param callback: (name: string, params: Object) => boolean
     */
    isValidNavDst(callback: (name: string, params: Object) => boolean): void;
    /**
     * Get custom transition configuration
     * @param from
     * @param to
     * @param operation
     * @returns
     */
    getCustomNavContentTransition(from: NavContentInfo, to: NavContentInfo, operation: NavigationOperation): NavigationAnimatedTransition | undefined;
    /**
     * Release the navbar lifecycle and the stored pathStack
     */
    destroy(): void;
}
