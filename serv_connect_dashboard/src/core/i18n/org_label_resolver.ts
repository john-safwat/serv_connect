import { useTranslation } from 'react-i18next';
import { LocaleKeys } from '../../generated/locale_keys.g';

export interface OrgLabelOverrides {
  readonly servant?: string;
  readonly servedMember?: string;
  readonly stage?: string;
  readonly group?: string;
}

export interface ResolvedOrgLabels {
  readonly servant: string;
  readonly servedMember: string;
  readonly stage: string;
  readonly group: string;
}

let cachedOverrides: OrgLabelOverrides = {};

export const OrgLabelResolver = {
  setOverrides(overrides: OrgLabelOverrides): void {
    cachedOverrides = { ...overrides };
  },
  getOverrides(): OrgLabelOverrides {
    return cachedOverrides;
  },
  clearOverrides(): void {
    cachedOverrides = {};
  },
};

export function useOrgLabels(): ResolvedOrgLabels {
  const { t } = useTranslation();
  return {
    servant: cachedOverrides.servant ?? t(LocaleKeys.common_role_servant),
    servedMember: cachedOverrides.servedMember ?? t(LocaleKeys.common_role_served_member),
    stage: cachedOverrides.stage ?? t(LocaleKeys.common_stage),
    group: cachedOverrides.group ?? t(LocaleKeys.common_group),
  };
}
