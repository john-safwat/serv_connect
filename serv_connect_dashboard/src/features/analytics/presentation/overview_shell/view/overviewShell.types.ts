import type { ServeBadgeTone } from '../../../../../components/primitives/ServeBadge';
import type { Resources } from '../../../../../network/resources';

export type OverviewCatalogTab = 'primitives' | 'safeguarding' | 'states';

export interface OverviewSampleRow {
  readonly id: string;
  readonly displayCode: string;
  readonly stageLabel: string;
  readonly photoConsent: boolean;
  readonly photoUrl: string;
  readonly statusTone: ServeBadgeTone;
  readonly statusKey: 'present' | 'absent' | 'at_risk' | 'scheduled';
}

export interface OverviewShellState {
  readonly activeTab: OverviewCatalogTab;
  readonly searchQuery: string;
  readonly isModalOpen: boolean;
  readonly isDrawerOpen: boolean;
  readonly rosterResource: Resources<readonly OverviewSampleRow[]>;
}

export type OverviewShellAction =
  | { readonly type: 'SELECT_TAB'; readonly tab: OverviewCatalogTab }
  | { readonly type: 'CHANGE_SEARCH'; readonly query: string }
  | { readonly type: 'OPEN_MODAL' }
  | { readonly type: 'CLOSE_MODAL' }
  | { readonly type: 'OPEN_DRAWER' }
  | { readonly type: 'CLOSE_DRAWER' }
  | { readonly type: 'SIMULATE_LOADING' }
  | { readonly type: 'SIMULATE_FORBIDDEN' }
  | { readonly type: 'SIMULATE_SUCCESS' }
  | { readonly type: 'TRIGGER_TOAST'; readonly message: string };
