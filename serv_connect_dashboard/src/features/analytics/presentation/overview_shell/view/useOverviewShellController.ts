import { useCallback, useState } from 'react';
import { Toaster } from '../../../../../components/feedback/toaster_store';
import { assertNever } from '../../../../../core/validation/assert_never';
import { AppErrorFactory } from '../../../../../network/errors';
import { Resources } from '../../../../../network/resources';
import type {
  OverviewSampleRow,
  OverviewShellAction,
  OverviewShellState,
} from './overviewShell.types';

export const INITIAL_SAMPLE_ROWS: readonly OverviewSampleRow[] = [
  {
    id: '00000000-0000-4000-8000-000000000101',
    displayCode: 'Member #101',
    stageLabel: 'Primary',
    photoConsent: true,
    photoUrl: 'https://example.org/avatars/member-101.png',
    statusTone: 'green',
    statusKey: 'present',
  },
  {
    id: '00000000-0000-4000-8000-000000000102',
    displayCode: 'Member #102',
    stageLabel: 'Preparatory',
    photoConsent: false,
    photoUrl: 'https://example.org/avatars/member-102.png',
    statusTone: 'amber',
    statusKey: 'at_risk',
  },
];

function reduceOverviewAction(
  prev: OverviewShellState,
  action: OverviewShellAction,
): OverviewShellState {
  switch (action.type) {
    case 'SELECT_TAB':
      return { ...prev, activeTab: action.tab };
    case 'CHANGE_SEARCH':
      return { ...prev, searchQuery: action.query };
    case 'OPEN_MODAL':
      return { ...prev, isModalOpen: true };
    case 'CLOSE_MODAL':
      return { ...prev, isModalOpen: false };
    case 'OPEN_DRAWER':
      return { ...prev, isDrawerOpen: true };
    case 'CLOSE_DRAWER':
      return { ...prev, isDrawerOpen: false };
    case 'SIMULATE_LOADING':
      return { ...prev, rosterResource: Resources.loading() };
    case 'SIMULATE_FORBIDDEN':
      return {
        ...prev,
        rosterResource: Resources.failure(AppErrorFactory.forbiddenScope('403 Forbidden Scope')),
      };
    case 'SIMULATE_SUCCESS':
      return { ...prev, rosterResource: Resources.success(INITIAL_SAMPLE_ROWS) };
    case 'TRIGGER_TOAST':
      return prev;
    default:
      return assertNever(action);
  }
}

export interface OverviewShellController {
  readonly state: OverviewShellState;
  readonly doAction: (action: OverviewShellAction) => void;
}

export function useOverviewShellController(): OverviewShellController {
  const [state, setState] = useState<OverviewShellState>(() => ({
    activeTab: 'primitives',
    searchQuery: '',
    isModalOpen: false,
    isDrawerOpen: false,
    rosterResource: Resources.success(INITIAL_SAMPLE_ROWS),
  }));

  const doAction = useCallback((action: OverviewShellAction): void => {
    if (action.type === 'TRIGGER_TOAST') {
      Toaster.showSuccess(action.message);
      return;
    }
    setState((prev) => reduceOverviewAction(prev, action));
  }, []);

  return { state, doAction };
}
