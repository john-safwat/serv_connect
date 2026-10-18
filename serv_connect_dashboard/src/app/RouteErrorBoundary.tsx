import React from 'react';
import { DefaultErrorView } from '../components/feedback/DefaultErrorView';
import { AppLogger } from '../core/logger/app_logger';
import { AppErrorFactory } from '../network/errors';

export interface RouteErrorBoundaryProps {
  readonly children: React.ReactNode;
}

interface RouteErrorBoundaryState {
  readonly hasError: boolean;
}

export class RouteErrorBoundary extends React.Component<
  RouteErrorBoundaryProps,
  RouteErrorBoundaryState
> {
  public constructor(props: RouteErrorBoundaryProps) {
    super(props);
    this.state = { hasError: false };
  }

  public static getDerivedStateFromError(): RouteErrorBoundaryState {
    return { hasError: true };
  }

  public override componentDidCatch(error: Error): void {
    AppLogger.e('RouteErrorBoundary', 'Unhandled render error caught by boundary', {
      errorName: error.name,
    });
  }

  public override render(): React.ReactNode {
    if (this.state.hasError) {
      return (
        <DefaultErrorView
          error={AppErrorFactory.unknown('Render error')}
          onRetry={() => this.setState({ hasError: false })}
        />
      );
    }
    return this.props.children;
  }
}
