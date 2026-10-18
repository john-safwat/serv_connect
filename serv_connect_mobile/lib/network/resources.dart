import 'package:serv_connect_mobile/network/errors.dart';

enum Status { initial, loading, success, error }

/// Presentation state envelope (`CLAUDE.md §11.2`).
///
/// Preserves cached [data] across [Resources.loading] and [Resources.failure]
/// transitions so offline-first screens keep rendering local data during a
/// background sync or failed refresh.
class Resources<T> {
  const Resources._({
    required this.status,
    this.data,
    this.error,
    this.message,
  });

  const Resources.initial() : this._(status: Status.initial);

  const Resources.loading({T? data})
    : this._(status: Status.loading, data: data);

  const Resources.success({T? data})
    : this._(status: Status.success, data: data);

  const Resources.failure({Errors? exception, String? message, T? data})
    : this._(
        status: Status.error,
        error: exception,
        message: message,
        data: data,
      );

  final Status status;
  final T? data;
  final Errors? error;
  final String? message;

  bool get isInitial => status == Status.initial;
  bool get isLoading => status == Status.loading;
  bool get isSuccess => status == Status.success;
  bool get isError => status == Status.error;
}
