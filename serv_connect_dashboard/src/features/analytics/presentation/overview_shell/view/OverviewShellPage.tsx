import type React from 'react';
import { OverviewShellContent } from '../widgets/OverviewShellContent';
import { useOverviewShellController } from './useOverviewShellController';

export function OverviewShellPage(): React.JSX.Element {
  const { state, doAction } = useOverviewShellController();

  return <OverviewShellContent state={state} onAction={doAction} />;
}
