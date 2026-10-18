import type React from 'react';
import { useTranslation } from 'react-i18next';
import { ServeButton } from '../../../../../components/primitives/ServeButton';
import { ServeDrawer } from '../../../../../components/primitives/ServeDrawer';
import { ServeModal } from '../../../../../components/primitives/ServeModal';
import { LocaleKeys } from '../../../../../generated/locale_keys.g';
import type { OverviewShellAction, OverviewShellState } from '../view/overviewShell.types';
import { OverviewCatalogueSection } from './OverviewCatalogueSection';
import { OverviewKpiGrid } from './OverviewKpiGrid';
import styles from './OverviewShell.module.css';

export interface OverviewShellContentProps {
  readonly state: OverviewShellState;
  readonly onAction: (action: OverviewShellAction) => void;
}

export function OverviewShellContent({
  state,
  onAction,
}: OverviewShellContentProps): React.JSX.Element {
  const { t } = useTranslation();

  return (
    <div className={styles.page}>
      <div className={styles.header}>
        <div>
          <h1 className={styles.title}>{t(LocaleKeys.common_overview_greeting)}</h1>
          <p className={styles.subtitle}>{t(LocaleKeys.common_overview_subtitle)}</p>
        </div>
        <div className={styles.headerActions}>
          <ServeButton
            variant="ghost"
            size="sm"
            onClick={() => onAction({ type: 'OPEN_DRAWER' })}
          >
            {t(LocaleKeys.common_overview_open_drawer)}
          </ServeButton>
          <ServeButton
            variant="gold"
            size="sm"
            onClick={() =>
              onAction({ type: 'TRIGGER_TOAST', message: t(LocaleKeys.common_synced) })
            }
          >
            {t(LocaleKeys.common_overview_simulate_toast)}
          </ServeButton>
          <ServeButton
            variant="primary"
            size="sm"
            onClick={() => onAction({ type: 'OPEN_MODAL' })}
          >
            {t(LocaleKeys.common_overview_open_modal)}
          </ServeButton>
        </div>
      </div>
      <OverviewKpiGrid />
      <OverviewCatalogueSection state={state} onAction={onAction} />
      <ServeModal
        isOpen={state.isModalOpen}
        title={t(LocaleKeys.common_overview_modal_title)}
        onClose={() => onAction({ type: 'CLOSE_MODAL' })}
      >
        <p>{t(LocaleKeys.common_overview_modal_body)}</p>
      </ServeModal>
      <ServeDrawer
        isOpen={state.isDrawerOpen}
        title={t(LocaleKeys.common_overview_drawer_title)}
        onClose={() => onAction({ type: 'CLOSE_DRAWER' })}
      >
        <p>{t(LocaleKeys.common_overview_drawer_body)}</p>
      </ServeDrawer>
    </div>
  );
}
