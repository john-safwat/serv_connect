import type React from 'react';
import styles from './ServeTabs.module.css';

export interface ServeTabItem<K extends string = string> {
  readonly key: K;
  readonly label: string;
}

export interface ServeTabsProps<K extends string = string> {
  readonly tabs: readonly ServeTabItem<K>[];
  readonly activeKey: K;
  readonly onChange: (key: K) => void;
  readonly ariaLabel?: string;
}

export function ServeTabs<K extends string = string>({
  tabs,
  activeKey,
  onChange,
  ariaLabel,
}: ServeTabsProps<K>): React.JSX.Element {
  return (
    <div role="tablist" aria-label={ariaLabel} className={styles.tabList}>
      {tabs.map((tab) => {
        const isActive = tab.key === activeKey;
        const btnClass = `${styles.tabButton ?? ''} ${isActive ? (styles.tabButtonActive ?? '') : ''}`.trim();
        return (
          <button
            key={tab.key}
            type="button"
            role="tab"
            aria-selected={isActive}
            className={btnClass}
            onClick={() => onChange(tab.key)}
          >
            {tab.label}
          </button>
        );
      })}
    </div>
  );
}
