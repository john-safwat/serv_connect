import { AppEnvironment } from '../config/app_environment';

export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

export interface LogEntry {
  readonly level: LogLevel;
  readonly tag: string;
  readonly message: string;
  readonly metadata?: Readonly<Record<string, unknown>>;
  readonly timestampIso: string;
}

const REDACTED_VALUE = '[REDACTED]';
const SENSITIVE_KEY_PATTERN = /authorization|password|otp|token|phone|email|medical|note|name|photo|address|birth/i;

export function redactMetadata(
  input: Readonly<Record<string, unknown>> | undefined,
): Readonly<Record<string, unknown>> | undefined {
  if (!input) return undefined;
  const output: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(input)) {
    if (SENSITIVE_KEY_PATTERN.test(key)) {
      output[key] = REDACTED_VALUE;
    } else if (value !== null && typeof value === 'object' && !Array.isArray(value)) {
      output[key] = redactMetadata(value as Readonly<Record<string, unknown>>);
    } else {
      output[key] = value;
    }
  }
  return output;
}

type LogSink = (entry: LogEntry) => void;
let customSink: LogSink | null = null;

function isProductionEnv(): boolean {
  try {
    return AppEnvironment.config.envName === 'prod';
  } catch {
    return false;
  }
}

function emit(level: LogLevel, tag: string, message: string, metadata?: Readonly<Record<string, unknown>>): void {
  if (isProductionEnv()) return;
  const entry: LogEntry = {
    level,
    tag,
    message,
    metadata: redactMetadata(metadata),
    timestampIso: new Date().toISOString(),
  };
  if (customSink) {
    customSink(entry);
  }
}

export const AppLogger = {
  d(tag: string, message: string, metadata?: Readonly<Record<string, unknown>>): void {
    emit('debug', tag, message, metadata);
  },
  i(tag: string, message: string, metadata?: Readonly<Record<string, unknown>>): void {
    emit('info', tag, message, metadata);
  },
  w(tag: string, message: string, metadata?: Readonly<Record<string, unknown>>): void {
    emit('warn', tag, message, metadata);
  },
  e(tag: string, message: string, metadata?: Readonly<Record<string, unknown>>): void {
    emit('error', tag, message, metadata);
  },
  setSinkForTesting(sink: LogSink | null): void {
    customSink = sink;
  },
};
