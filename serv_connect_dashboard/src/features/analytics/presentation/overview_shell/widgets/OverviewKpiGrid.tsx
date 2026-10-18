import type React from 'react';
import { useTranslation } from 'react-i18next';
import { ServeBadge } from '../../../../../components/primitives/ServeBadge';
import { ServeCard } from '../../../../../components/primitives/ServeCard';
import { AppFormatters } from '../../../../../core/format/app_formatters';
import { LocaleController } from '../../../../../core/i18n/locale_controller';
import { LocaleKeys } from '../../../../../generated/locale_keys.g';
import styles from './OverviewShell.module.css';

export function OverviewKpiGrid(): React.JSX.Element {
  const { t } = useTranslation();
  const locale = LocaleController.getLocale();

  return (
    <div className={styles.kpiGrid}>
      <ServeCard goldAccent>
        <div className={styles.kpiLabel}>{t(LocaleKeys.common_overview_kpi_members)}</div>
        <div className={styles.kpiValue}>{AppFormatters.formatNumber(842, locale)}</div>
        <ServeBadge tone="green">{t(LocaleKeys.common_synced)}</ServeBadge>
      </ServeCard>
      <ServeCard>
        <div className={styles.kpiLabel}>{t(LocaleKeys.common_overview_kpi_attendance)}</div>
        <div className={styles.kpiValue}>{AppFormatters.formatPercent(92, locale)}</div>
        <ServeBadge tone="gold">{t(LocaleKeys.common_status_present)}</ServeBadge>
      </ServeCard>
      <ServeCard>
        <div className={styles.kpiLabel}>{t(LocaleKeys.common_overview_kpi_at_risk)}</div>
        <div className={styles.kpiValue}>{AppFormatters.formatNumber(18, locale)}</div>
        <ServeBadge tone="red">{t(LocaleKeys.common_status_at_risk)}</ServeBadge>
      </ServeCard>
      <ServeCard>
        <div className={styles.kpiLabel}>{t(LocaleKeys.common_overview_kpi_tasks)}</div>
        <div className={styles.kpiValue}>{AppFormatters.formatNumber(27, locale)}</div>
        <ServeBadge tone="blue">{t(LocaleKeys.common_status_scheduled)}</ServeBadge>
      </ServeCard>
    </div>
  );
}
