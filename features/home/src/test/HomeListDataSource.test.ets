import { describe, it, expect } from '@ohos/hypium';
import { GameRoleCardVM, MihoyoAccountVM } from 'basic';
import { GameId } from 'core';
import {
  buildHomeListItems,
  changedItemIndexes,
  HomeAccountItem,
  HomeListDataSource,
  HomeListItem,
  HomeRoleItem,
  isAccountCollapsed,
  toggleCollapsedAccount
} from '../main/ets/viewmodel/HomeListDataSource';

function role(uid: string, nickname: string): GameRoleCardVM {
  return new GameRoleCardVM(
    GameId.GENSHIN, '原神', $r('app.color.color_primary'), uid, nickname, '天空岛', null, ''
  );
}

function account(accountId: string, roles: GameRoleCardVM[]): MihoyoAccountVM {
  return new MihoyoAccountVM(accountId, `user_${accountId}`, roles, '昵称', '');
}

export default function homeListDataSourceTest() {
  describe('HomeListDataSource', () => {

    // ─── 扁平化 ──────────────────────────────────────────────────

    it('没有账号时列表为空', 0, () => {
      expect(buildHomeListItems([], []).length).assertEqual(0);
    });

    it('账号标题行在前，角色卡片按顺序跟随', 0, () => {
      const items = buildHomeListItems([account('a1', [role('1', '甲'), role('2', '乙')])], []);
      expect(items.length).assertEqual(3);
      expect(items[0] instanceof HomeAccountItem).assertTrue();
      expect(items[1] instanceof HomeRoleItem).assertTrue();
      expect(items[2] instanceof HomeRoleItem).assertTrue();
      const r1 = items[1] as HomeRoleItem;
      const r2 = items[2] as HomeRoleItem;
      expect(r1.role.roleUid).assertEqual('1');
      expect(r2.role.roleUid).assertEqual('2');
    });

    it('多账号时每个账号都有独立标题行', 0, () => {
      const items = buildHomeListItems([
        account('a1', [role('1', '甲')]),
        account('a2', [role('2', '乙')])
      ], []);
      expect(items.length).assertEqual(4);
      expect(items[0] instanceof HomeAccountItem).assertTrue();
      expect(items[2] instanceof HomeAccountItem).assertTrue();
      expect((items[2] as HomeAccountItem).account.accountId).assertEqual('a2');
    });

    it('折叠的账号只保留标题行', 0, () => {
      const items = buildHomeListItems([account('a1', [role('1', '甲'), role('2', '乙')])], ['a1']);
      expect(items.length).assertEqual(1);
      expect((items[0] as HomeAccountItem).isCollapsed).assertTrue();
    });

    it('折叠只影响指定账号', 0, () => {
      const items = buildHomeListItems([
        account('a1', [role('1', '甲')]),
        account('a2', [role('2', '乙')])
      ], ['a1']);
      expect(items.length).assertEqual(3);
      expect((items[0] as HomeAccountItem).isCollapsed).assertTrue();
      expect((items[1] as HomeAccountItem).isCollapsed).assertFalse();
      expect(items[2] instanceof HomeRoleItem).assertTrue();
    });

    it('每个账号的第一张卡片标记 isFirstRoleInSection', 0, () => {
      const items = buildHomeListItems([
        account('a1', [role('1', '甲'), role('2', '乙')]),
        account('a2', [role('3', '丙')])
      ], []);
      expect((items[1] as HomeRoleItem).isFirstRoleInSection).assertTrue();
      expect((items[2] as HomeRoleItem).isFirstRoleInSection).assertFalse();
      expect((items[4] as HomeRoleItem).isFirstRoleInSection).assertTrue();
    });

    // ─── key ────────────────────────────────────────────────────

    it('同账号同角色的 key 稳定', 0, () => {
      const a = account('a1', [role('1', '甲')]);
      const b = account('a1', [role('1', '甲')]);
      expect(buildHomeListItems([a], [])[1].key).assertEqual(buildHomeListItems([b], [])[1].key);
    });

    it('角色数据变化时 key 变化', 0, () => {
      const before = buildHomeListItems([account('a1', [role('1', '甲')])], [])[1].key;
      const after = buildHomeListItems([account('a1', [role('1', '乙')])], [])[1].key;
      expect(before === after).assertFalse();
    });

    it('折叠状态进入账号标题行 key', 0, () => {
      const expanded = buildHomeListItems([account('a1', [])], [])[0].key;
      const collapsed = buildHomeListItems([account('a1', [])], ['a1'])[0].key;
      expect(expanded === collapsed).assertFalse();
    });

    it('不同账号下的同名角色 key 不冲突', 0, () => {
      const items = buildHomeListItems([
        account('a1', [role('1', '甲')]),
        account('a2', [role('1', '甲')])
      ], []);
      const keys: string[] = [];
      for (let i = 0; i < items.length; i++) {
        expect(keys.indexOf(items[i].key)).assertEqual(-1);
        keys.push(items[i].key);
      }
    });

    // ─── 折叠集合 ────────────────────────────────────────────────

    it('isAccountCollapsed 只匹配集合内的 ID', 0, () => {
      expect(isAccountCollapsed(['a1'], 'a1')).assertTrue();
      expect(isAccountCollapsed(['a1'], 'a2')).assertFalse();
      expect(isAccountCollapsed([], 'a1')).assertFalse();
    });

    it('toggleCollapsedAccount 折叠后返回新数组', 0, () => {
      const before: string[] = [];
      const after = toggleCollapsedAccount(before, 'a1');
      expect(after.length).assertEqual(1);
      expect(after[0]).assertEqual('a1');
      expect(before.length).assertEqual(0);
    });

    it('toggleCollapsedAccount 再次调用取消折叠', 0, () => {
      const after = toggleCollapsedAccount(toggleCollapsedAccount([], 'a1'), 'a1');
      expect(after.length).assertEqual(0);
    });

    it('toggleCollapsedAccount 保留其他账号的折叠状态', 0, () => {
      const after = toggleCollapsedAccount(['a1', 'a2'], 'a1');
      expect(after.length).assertEqual(1);
      expect(after[0]).assertEqual('a2');
    });

    // ─── 数据源 ──────────────────────────────────────────────────

    it('changedItemIndexes 内容不变时返回空数组', 0, () => {
      const prev = buildHomeListItems([account('a1', [role('1', '甲')])], []);
      const next = buildHomeListItems([account('a1', [role('1', '甲')])], []);
      const changed = changedItemIndexes(prev, next);
      expect(changed !== null).assertTrue();
      expect((changed as number[]).length).assertEqual(0);
    });

    it('changedItemIndexes 只返回内容变化的条目下标', 0, () => {
      const prev = buildHomeListItems([account('a1', [role('1', '甲'), role('2', '乙')])], []);
      const next = buildHomeListItems([account('a1', [role('1', '甲'), role('2', '丙')])], []);
      const changed = changedItemIndexes(prev, next) as number[];
      expect(changed.length).assertEqual(1);
      expect(changed[0]).assertEqual(2);
    });

    it('角色内容变化不重建账号标题行', 0, () => {
      const prev = buildHomeListItems([account('a1', [role('1', '甲')])], []);
      const next = buildHomeListItems([account('a1', [role('1', '乙')])], []);
      const changed = changedItemIndexes(prev, next) as number[];
      expect(changed.length).assertEqual(1);
      expect(changed[0]).assertEqual(1);
    });

    it('角色数量变化会重建账号标题行（游戏数变了）', 0, () => {
      const prev = buildHomeListItems([account('a1', [role('1', '甲')])], []);
      const next = buildHomeListItems([account('a1', [role('1', '甲'), role('2', '乙')])], []);
      expect(prev[0].key === next[0].key).assertFalse();
    });

    it('changedItemIndexes 条目数量变化时返回 null', 0, () => {
      const prev = buildHomeListItems([account('a1', [role('1', '甲')])], []);
      const next = buildHomeListItems([account('a1', [role('1', '甲')])], ['a1']);
      expect(changedItemIndexes(prev, next)).assertNull();
    });

    it('数据源按 setItems 内容返回 totalCount / getData', 0, () => {
      const source = new HomeListDataSource();
      expect(source.totalCount()).assertEqual(0);
      const items: HomeListItem[] = buildHomeListItems([account('a1', [role('1', '甲')])], []);
      source.setItems(items);
      expect(source.totalCount()).assertEqual(2);
      expect(source.getData(0).key).assertEqual(items[0].key);
      expect(source.getData(1).key).assertEqual(items[1].key);
    });

    it('数据源 setItems 整体替换旧内容', 0, () => {
      const source = new HomeListDataSource();
      source.setItems(buildHomeListItems([account('a1', [role('1', '甲')])], []));
      source.setItems(buildHomeListItems([account('a1', [role('1', '甲')])], ['a1']));
      expect(source.totalCount()).assertEqual(1);
    });

  });
}
