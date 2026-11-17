/**
 * HomeListDataSource — 首页「账号标题行 + 角色卡片」扁平化列表的数据源
 *
 * 首页把账号 / 角色两层压平成一条 List，交给 LazyForEach 懒加载。
 * 折叠状态由调用方（HomePage）持有，每次重建时一并传入，
 * 因此折叠切换只需重新生成 items 并通知一次 onDataReloaded。
 */
import { GameRoleCardVM, MihoyoAccountVM } from 'basic';

/** 扁平列表中的账号标题行 */
export class HomeAccountItem {
  readonly account: MihoyoAccountVM;
  readonly isCollapsed: boolean;
  readonly key: string;

  constructor(account: MihoyoAccountVM, isCollapsed: boolean) {
    this.account = account;
    this.isCollapsed = isCollapsed;
    // 折叠状态编进 key：LazyForEach 只在 key 变化时重建条目，
    // 不编进去折叠箭头不会翻转。
    this.key = `a_${isCollapsed ? '1' : '0'}_${account.headerKey()}`;
  }
}

/** 扁平列表中的角色卡片 */
export class HomeRoleItem {
  readonly account: MihoyoAccountVM;
  readonly role: GameRoleCardVM;
  /** 是否为本账号下的第一张卡片（还原 8vp / 12vp 两种间距） */
  readonly isFirstRoleInSection: boolean;
  readonly key: string;

  constructor(account: MihoyoAccountVM, role: GameRoleCardVM, isFirstRoleInSection: boolean) {
    this.account = account;
    this.role = role;
    this.isFirstRoleInSection = isFirstRoleInSection;
    this.key = `r_${account.accountId}_${role.renderKey()}`;
  }
}

export type HomeListItem = HomeAccountItem | HomeRoleItem;

/** 账号是否在折叠集合中 */
export function isAccountCollapsed(collapsedIds: string[], accountId: string): boolean {
  for (let i = 0; i < collapsedIds.length; i++) {
    if (collapsedIds[i] === accountId) { return true; }
  }
  return false;
}

/**
 * 切换某个账号的折叠状态，返回新数组。
 *
 * 返回新数组而不是原地修改：@Local 只在引用变化时通知 UI。
 */
export function toggleCollapsedAccount(collapsedIds: string[], accountId: string): string[] {
  const next: string[] = [];
  let removed = false;
  for (let i = 0; i < collapsedIds.length; i++) {
    if (collapsedIds[i] === accountId) {
      removed = true;
    } else {
      next.push(collapsedIds[i]);
    }
  }
  if (!removed) { next.push(accountId); }
  return next;
}

/** 按账号顺序生成扁平列表：每个账号一个标题行，未折叠时其后跟角色卡片 */
export function buildHomeListItems(accounts: MihoyoAccountVM[], collapsedIds: string[]): HomeListItem[] {
  const items: HomeListItem[] = [];
  for (let ai = 0; ai < accounts.length; ai++) {
    const account = accounts[ai];
    const collapsed = isAccountCollapsed(collapsedIds, account.accountId);
    items.push(new HomeAccountItem(account, collapsed));
    if (collapsed) { continue; }
    for (let ri = 0; ri < account.roles.length; ri++) {
      items.push(new HomeRoleItem(account, account.roles[ri], ri === 0));
    }
  }
  return items;
}

/** 计算需要重建的条目下标；返回 null 表示条目数量变化、需要整体 reload */
export function changedItemIndexes(prev: HomeListItem[], next: HomeListItem[]): number[] | null {
  if (prev.length !== next.length) { return null; }
  const changed: number[] = [];
  for (let index = 0; index < next.length; index++) {
    if (prev[index].key !== next[index].key) { changed.push(index); }
  }
  return changed;
}

/** LazyForEach 数据源：整体替换内容并通知 UI 重建 */
export class HomeListDataSource implements IDataSource {
  private items: HomeListItem[] = [];
  private listeners: DataChangeListener[] = [];

  totalCount(): number {
    return this.items.length;
  }

  getData(index: number): HomeListItem {
    return this.items[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  /**
   * 用新的扁平列表替换当前内容。
   *
   * 条目数量不变时逐项比较 key，只对内容变化的条目发 onDataChange（保持复用）；
   * 数量变化（折叠 / 增删账号）时整体 onDataReloaded。
   */
  setItems(next: HomeListItem[]): void {
    const prev = this.items;
    this.items = next;
    const changed = changedItemIndexes(prev, next);
    if (changed === null) {
      for (let i = 0; i < this.listeners.length; i++) {
        this.listeners[i].onDataReloaded();
      }
      return;
    }
    for (let c = 0; c < changed.length; c++) {
      for (let i = 0; i < this.listeners.length; i++) {
        this.listeners[i].onDataChange(changed[c]);
      }
    }
  }
}
