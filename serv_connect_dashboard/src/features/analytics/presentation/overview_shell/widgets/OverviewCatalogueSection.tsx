import type React from 'react';
import { useTranslation } from 'react-i18next';
import { DefaultErrorView } from '../../../../../components/feedback/DefaultErrorView';
import { ServeButton } from '../../../../../components/primitives/ServeButton';
import { ServeCard } from '../../../../../components/primitives/ServeCard';
import { ServeTable } from '../../../../../components/primitives/ServeTable';
import { ServeTabs } from '../../../../../components/primitives/ServeTabs';
import { ServeTextField } from '../../../../../components/primitives/ServeTextField';
import { ServeTableShimmer } from '../../../../../components/shimmer/ServeTableShimmer';
import { LocaleKeys } from '../../../../../generated/locale_keys.g';
import type {
  OverviewCatalogTab,
  OverviewSampleRow,
  OverviewShellAction,
  OverviewShellState,
} from '../view/overviewShell.types';
import { buildOverviewColumns } from './overviewCatalogueColumns';
import styles from './OverviewShell.module.css';

export interface OverviewCatalogueSectionProps {
  readonly state: OverviewShellState;
  readonly onAction: (action: OverviewShellAction) => void;
}

interface RosterTableViewProps {
  readonly state: OverviewShellState;
  readonly rows: readonly OverviewSampleRow[];
  readonly onAction: (action: OverviewShellAction) => void;
}

function RosterTableView({ state, rows, onAction }: RosterTableViewProps): React.JSX.Element {
  const { t } = useTranslation();
  if (state.rosterResource.isLoading) {
    return <ServeTableShimmer rows={2} />;
  }
  if (state.rosterResource.isError) {
    return (
      <DefaultErrorView
        error={state.rosterResource.error}
        onRetry={() => onAction({ type: 'SIMULATE_SUCCESS' })}
      />
    );
  }
  return <ServeTable columns={buildOverviewColumns(t)} rows={rows} getRowKey={(r) => r.id} />;
}

export function OverviewCatalogueSection({
  state,
  onAction,
}: OverviewCatalogueSectionProps): React.JSX.Element {
  const { t } = useTranslation();
  const tabs: readonly { readonly key: OverviewCatalogTab; readonly label: string }[] = [
    { key: 'primitives', label: t(LocaleKeys.common_overview_tab_primitives) },
    { key: 'safeguarding', label: t(LocaleKeys.common_overview_tab_safeguarding) },
    { key: 'states', label: t(LocaleKeys.common_overview_tab_states) },
  ];
  const rows = (state.rosterResource.data ?? []).filter((r: OverviewSampleRow) =>
    r.displayCode.toLowerCase().includes(state.searchQuery.toLowerCase()),
  );

  return (
    <ServeCard>
      <div className={styles.sectionHeader}>
        <div>
          <h2 className={styles.sectionTitle}>{t(LocaleKeys.common_overview_catalogue_title)}</h2>
          <p className={styles.subtitle}>{t(LocaleKeys.common_overview_catalogue_subtitle)}</p>
        </div>
        <ServeTabs
          tabs={tabs}
          activeKey={state.activeTab}
          onChange={(tab) => onAction({ type: 'SELECT_TAB', tab })}
        />
      </div>
      <div className={styles.rowFlex}>
        <ServeTextField
          label={t(LocaleKeys.common_search)}
          placeholder={t(LocaleKeys.common_search_placeholder)}
          value={state.searchQuery}
          onChange={(e) => onAction({ type: 'CHANGE_SEARCH', query: e.target.value })}
        />
        <ServeButton variant="ghost" size="sm" onClick={() => onAction({ type: 'SIMULATE_LOADING' })}>
          {t(LocaleKeys.common_loading)}
        </ServeButton>
        <ServeButton variant="soft" size="sm" onClick={() => onAction({ type: 'SIMULATE_FORBIDDEN' })}>
          403
        </ServeButton>
        <ServeButton variant="primary" size="sm" onClick={() => onAction({ type: 'SIMULATE_SUCCESS' })}>
          {t(LocaleKeys.common_retry)}
        </ServeButton>
      </div>
      <RosterTableView state={state} rows={rows} onAction={onAction} />
    </ServeCard>
  );
}
