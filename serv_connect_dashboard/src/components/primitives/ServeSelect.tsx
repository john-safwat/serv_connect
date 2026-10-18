import type React from 'react';
import { useId } from 'react';
import styles from './ServeSelect.module.css';

export interface ServeSelectOption {
  readonly value: string;
  readonly label: string;
}

export interface ServeSelectProps extends React.SelectHTMLAttributes<HTMLSelectElement> {
  readonly label?: string;
  readonly options: readonly ServeSelectOption[];
  readonly errorText?: string;
}

export function ServeSelect({
  label,
  options,
  errorText,
  id,
  className,
  ...rest
}: ServeSelectProps): React.JSX.Element {
  const generatedId = useId();
  const selectId = id ?? generatedId;

  return (
    <div className={`${styles.wrapper ?? ''} ${className ?? ''}`.trim()}>
      {label ? (
        <label htmlFor={selectId} className={styles.label}>
          {label}
        </label>
      ) : null}
      <select
        id={selectId}
        className={`${styles.select ?? ''} ${errorText ? (styles.selectError ?? '') : ''}`.trim()}
        aria-invalid={Boolean(errorText)}
        {...rest}
      >
        {options.map((opt) => (
          <option key={opt.value} value={opt.value}>
            {opt.label}
          </option>
        ))}
      </select>
      {errorText ? (
        <p className={styles.errorText} role="alert">
          {errorText}
        </p>
      ) : null}
    </div>
  );
}
