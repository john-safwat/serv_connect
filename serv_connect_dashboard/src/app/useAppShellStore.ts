import { create } from 'zustand';

export interface AppShellUiState {
  readonly isSidebarCollapsed: boolean;
  readonly toggleSidebar: () => void;
  readonly setSidebarCollapsed: (collapsed: boolean) => void;
}

export const useAppShellStore = create<AppShellUiState>((set) => ({
  isSidebarCollapsed: false,
  toggleSidebar: () =>
    set((state) => ({ isSidebarCollapsed: !state.isSidebarCollapsed })),
  setSidebarCollapsed: (collapsed) => set({ isSidebarCollapsed: collapsed }),
}));
