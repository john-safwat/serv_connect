import React, { useId } from 'react';
import styles from './ServeTextField.module.css';

export interface ServeTextFieldProps extends React.InputHTMLAttributes<HTMLInputElement> {
  readonly label?: string;
  readonly errorText?: string;
  readonly leadingIcon?: React.ReactNode;
  readonly trailingIcon?: React.ReactNode;
}

export const ServeTextField = React.forwardRef<HTMLInputElement, ServeTextFieldProps>(
  function ServeTextFieldInner(
    { label, errorText, leadingIcon, trailingIcon, id, className, ...rest },
    ref,
  ): React.JSX.Element {
    const generatedId = useId();
    const inputId = id ?? generatedId;
    const errorId = `${inputId}-error`;
    const boxClass = `${styles.fieldBox ?? ''} ${errorText ? (styles.fieldBoxError ?? '') : ''}`.trim();

    return (
      <div className={`${styles.wrapper ?? ''} ${className ?? ''}`.trim()}>
        {label ? (
          <label htmlFor={inputId} className={styles.label}>
            {label}
          </label>
        ) : null}
        <div className={boxClass}>
          {leadingIcon ? <span className={styles.iconSlot}>{leadingIcon}</span> : null}
          <input
            ref={ref}
            id={inputId}
            className={styles.input}
            aria-invalid={Boolean(errorText)}
            aria-describedby={errorText ? errorId : undefined}
            {...rest}
          />
          {trailingIcon ? <span className={styles.iconSlot}>{trailingIcon}</span> : null}
        </div>
        {errorText ? (
          <p id={errorId} className={styles.errorText} role="alert">
            {errorText}
          </p>
        ) : null}
      </div>
    );
  },
);
