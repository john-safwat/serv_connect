export interface BaseApiResponse<T> {
  readonly data?: T;
  readonly message?: string;
  readonly code?: string;
  readonly fieldErrors?: Readonly<Record<string, string>>;
}

export interface PagedContent<T> {
  readonly content: readonly T[];
  readonly page: number;
  readonly size: number;
  readonly totalElements: number;
  readonly totalPages: number;
}
