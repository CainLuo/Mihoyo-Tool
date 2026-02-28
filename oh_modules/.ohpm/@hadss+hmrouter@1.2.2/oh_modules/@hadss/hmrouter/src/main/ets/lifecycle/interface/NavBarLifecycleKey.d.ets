import { HMNavPathStack } from '../../router/HMNavPathStack';
import { NavBarParentTypes } from '../enums/NavBarParentTypes';
export interface NavBarLifecycleKey {
    navigationId: string;
    pathStack: HMNavPathStack;
    parentType: NavBarParentTypes;
    parentId: string;
    parentPathStack?: HMNavPathStack;
}
