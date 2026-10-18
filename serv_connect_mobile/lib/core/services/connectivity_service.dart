import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Wraps `connectivity_plus` to expose current and streaming connectivity status
/// (`CLAUDE.md §12 & §19`).
@lazySingleton
class ConnectivityService {
  ConnectivityService() : _connectivity = Connectivity();

  @visibleForTesting
  ConnectivityService.test(this._connectivity);

  final Connectivity _connectivity;

  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return _hasActiveConnection(results);
  }

  Future<bool> isOnWifi() async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
  }

  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_hasActiveConnection);

  bool _hasActiveConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((result) => result != ConnectivityResult.none);
  }
}
