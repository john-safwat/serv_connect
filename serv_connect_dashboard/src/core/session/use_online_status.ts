import { useEffect, useState } from 'react';
import { AppEventBus } from '../event_bus/app_event_bus';
import { ConnectivityWatcher } from './connectivity_watcher';

export function useOnlineStatus(): boolean {
  const [isOnline, setIsOnline] = useState<boolean>(() => ConnectivityWatcher.isOnline());

  useEffect(() => {
    ConnectivityWatcher.start();
    return AppEventBus.subscribe((event) => {
      if (event.type === 'CONNECTIVITY_CHANGED') {
        setIsOnline(event.isOnline);
      }
    });
  }, []);

  return isOnline;
}
