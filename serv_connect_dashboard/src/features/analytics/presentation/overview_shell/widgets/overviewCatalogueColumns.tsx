import type React from 'react';
import { ServeBadge } from '../../../../../components/primitives/ServeBadge';
import { ServeMemberAvatar } from '../../../../../components/primitives/ServeMemberAvatar';
import type { ServeTableColumn } from '../../../../../components/primitives/ServeTable';
import { LocaleKeys } from '../../../../../generated/locale_keys.g';
import type { OverviewSampleRow } from '../view/overviewShell.types';
import styles from './OverviewShell.module.css';

function renderMemberCell(row: OverviewSampleRow): React.ReactNode {
  return (
    <div className={styles.memberCell}>
      <ServeMemberAvatar
        displayName={row.displayCode}
        photoUrl={row.photoUrl}
        photoConsent={row.photoConsent}
        tone={row.photoConsent ? 'gold' : 'red'}
      />
      <span>{row.displayCode}</span>
    </div>
  );
}

export function buildOverviewColumns(
  t: (key: string) => string,
): readonly ServeTableColumn<OverviewSampleRow>[] {
  return [
    { key: 'member', header: t(LocaleKeys.common_table_col_member), renderCell: renderMemberCell },
    { key: 'stage', header: t(LocaleKeys.common_table_col_stage), renderCell: (r) => r.stageLabel },
    {
      key: 'consent',
      header: t(LocaleKeys.common_table_col_consent),
      renderCell: (r) =>
        t(r.photoConsent ? LocaleKeys.common_overview_consent_granted : LocaleKeys.common_overview_consent_withheld),
    },
    {
      key: 'status',
      header: t(LocaleKeys.common_table_col_status),
      renderCell: (r) => <ServeBadge tone={r.statusTone}>{t(`common:status_${r.statusKey}`)}</ServeBadge>,
    },
  ];
}
