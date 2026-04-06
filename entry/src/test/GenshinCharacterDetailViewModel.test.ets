import { describe, it, expect } from '@ohos/hypium';
import { GenshinCharacterDetailViewModel } from '../main/ets/viewmodel/GenshinCharacterDetailViewModel';
import { GenshinPropertyType } from 'core';
import { ViewState } from '../main/ets/constants/ViewStates';

/**
 * GenshinCharacterDetailViewModel 单元测试
 *
 * 测试初始状态、init 方法、propertyTypeToResource 静态方法。
 * 不依赖设备。
 */
export default function genshinCharDetailViewModelTest() {
  describe('GenshinCharacterDetailViewModel', () => {

    // ─── 初始状态 ────────────────────────────────────────────────

    it('初始 viewState 为 LOADING', 0, () => {
      const vm = new GenshinCharacterDetailViewModel();
      expect(vm.viewState).assertEqual(ViewState.LOADING);
    });

    it('初始 charName 为空字符串', 0, () => {
      const vm = new GenshinCharacterDetailViewModel();
      expect(vm.charName).assertEqual('');
    });

    it('初始 charLevel 为 0', 0, () => {
      const vm = new GenshinCharacterDetailViewModel();
      expect(vm.charLevel).assertEqual(0);
    });

    it('初始 constellations 为空数组', 0, () => {
      const vm = new GenshinCharacterDetailViewModel();
      expect(vm.constellations.length).assertEqual(0);
    });

    it('初始 relics 为空数组', 0, () => {
      const vm = new GenshinCharacterDetailViewModel();
      expect(vm.relics.length).assertEqual(0);
    });

    it('初始 skills 为空数组', 0, () => {
      const vm = new GenshinCharacterDetailViewModel();
      expect(vm.skills.length).assertEqual(0);
    });

    // ─── init 方法 ───────────────────────────────────────────────

    it('init 设置三个参数不崩溃', 0, () => {
      const vm = new GenshinCharacterDetailViewModel();
      vm.init(1, 'uid1', 'avatarId1');
      expect(true).assertTrue();
    });

    // ─── propertyTypeToResource 静态方法 ─────────────────────────

    it('propertyTypeToResource HP_FLAT 返回非 null', 0, () => {
      const result = GenshinCharacterDetailViewModel.propertyTypeToResource(GenshinPropertyType.HP_FLAT);
      expect(result !== null).assertTrue();
    });

    it('propertyTypeToResource CRIT_RATE 返回非 null', 0, () => {
      const result = GenshinCharacterDetailViewModel.propertyTypeToResource(GenshinPropertyType.CRIT_RATE);
      expect(result !== null).assertTrue();
    });

    it('propertyTypeToResource CRIT_DMG 返回非 null', 0, () => {
      const result = GenshinCharacterDetailViewModel.propertyTypeToResource(GenshinPropertyType.CRIT_DMG);
      expect(result !== null).assertTrue();
    });

    it('propertyTypeToResource 未知类型 9999 返回 null', 0, () => {
      const result = GenshinCharacterDetailViewModel.propertyTypeToResource(9999);
      expect(result).assertNull();
    });

    it('propertyTypeToResource 0 返回 null', 0, () => {
      // 0 不是有效的 GenshinPropertyType，应返回 null
      const result = GenshinCharacterDetailViewModel.propertyTypeToResource(0);
      expect(result).assertNull();
    });

    // ─── KEYS 路径常量 ───────────────────────────────────────────

    it('KEYS.viewState 路径正确', 0, () => {
      expect(GenshinCharacterDetailViewModel.KEYS.viewState).assertEqual('vm.viewState');
    });

  });
}
