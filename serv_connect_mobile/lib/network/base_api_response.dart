import 'package:json_annotation/json_annotation.dart';

part 'base_api_response.g.dart';

/// Standard backend response envelope matching `BaseResponseBody<T>` in
/// `sev_connect_backend` (`CLAUDE.md §11`).
@JsonSerializable(genericArgumentFactories: true)
class BaseApiResponse<T> {
  const BaseApiResponse({
    this.data,
    this.message,
    this.code,
    this.fieldErrors = const <String, String>{},
  });

  factory BaseApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$BaseApiResponseFromJson(json, fromJsonT);

  final T? data;
  final String? message;
  final String? code;
  final Map<String, String> fieldErrors;

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$BaseApiResponseToJson(this, toJsonT);
}

/// Paginated response envelope matching Spring `PageResponse<T>` metadata
/// (`CLAUDE.md §11`).
@JsonSerializable(genericArgumentFactories: true)
class PagedContent<T> {
  const PagedContent({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory PagedContent.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$PagedContentFromJson(json, fromJsonT);

  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$PagedContentToJson(this, toJsonT);
}
