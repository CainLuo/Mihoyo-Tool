/**
 * CharacterDataSource — LazyForEach 数据源适配器
 *
 * 包装 GameDataSummary 数组，实现 IDataSource 接口，
 * 供 CharactersContent 的 LazyForEach 使用。
 */
import { GameDataSummary } from 'core';

export class CharacterDataSource implements IDataSource {
  private data: GameDataSummary[] = [];
  private listeners: DataChangeListener[] = [];

  setData(newData: GameDataSummary[]): void {
    this.data = newData;
    this.notifyDataReload();
  }

  totalCount(): number {
    return this.data.length;
  }

  getData(index: number): GameDataSummary {
    return this.data[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners[this.listeners.length] = listener;
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const idx = this.listeners.indexOf(listener);
    if (idx >= 0) {
      this.listeners.splice(idx, 1);
    }
  }

  private notifyDataReload(): void {
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded();
    }
  }
}
