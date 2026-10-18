import type React from 'react';
import styles from './ServeTable.module.css';

export interface ServeTableColumn<T> {
  readonly key: string;
  readonly header: string;
  readonly renderCell: (row: T) => React.ReactNode;
}

export interface ServeTableProps<T> {
  readonly columns: readonly ServeTableColumn<T>[];
  readonly rows: readonly T[];
  readonly getRowKey: (row: T) => string;
  readonly onRowClick?: (row: T) => void;
  readonly emptyState?: React.ReactNode;
}

export function ServeTable<T>({
  columns,
  rows,
  getRowKey,
  onRowClick,
  emptyState,
}: ServeTableProps<T>): React.JSX.Element {
  if (rows.length === 0 && emptyState) {
    return <>{emptyState}</>;
  }

  return (
    <div className={styles.tableContainer}>
      <table className={styles.table}>
        <thead>
          <tr>
            {columns.map((col) => (
              <th key={col.key} scope="col" className={styles.th}>
                {col.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr
              key={getRowKey(row)}
              className={`${styles.tr ?? ''} ${onRowClick ? (styles.trClickable ?? '') : ''}`.trim()}
              onClick={onRowClick ? () => onRowClick(row) : undefined}
            >
              {columns.map((col) => (
                <td key={col.key} className={styles.td}>
                  {col.renderCell(row)}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
