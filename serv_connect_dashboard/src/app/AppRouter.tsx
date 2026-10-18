import React, { Suspense } from 'react';
import { BrowserRouter, Route, Routes } from 'react-router';
import { DefaultErrorView } from '../components/feedback/DefaultErrorView';
import { ServeTableShimmer } from '../components/shimmer/ServeTableShimmer';
import { OverviewShellPage } from '../features/analytics';
import { AppErrorFactory } from '../network/errors';
import { AppShell } from './AppShell';
import { RouteErrorBoundary } from './RouteErrorBoundary';

export function AppRouter(): React.JSX.Element {
  return (
    <BrowserRouter>
      <RouteErrorBoundary>
        <Suspense fallback={<ServeTableShimmer rows={5} />}>
          <Routes>
            <Route element={<AppShell />}>
              <Route index element={<OverviewShellPage />} />
              <Route path="/schedule" element={<OverviewShellPage />} />
              <Route path="/attendance" element={<OverviewShellPage />} />
              <Route path="/tasks" element={<OverviewShellPage />} />
              <Route path="/members" element={<OverviewShellPage />} />
              <Route path="/groups" element={<OverviewShellPage />} />
              <Route path="/communication" element={<OverviewShellPage />} />
              <Route path="/content" element={<OverviewShellPage />} />
              <Route path="/safeguarding" element={<OverviewShellPage />} />
              <Route path="/settings" element={<OverviewShellPage />} />
              <Route
                path="*"
                element={<DefaultErrorView error={AppErrorFactory.notFound('404')} />}
              />
            </Route>
          </Routes>
        </Suspense>
      </RouteErrorBoundary>
    </BrowserRouter>
  );
}
