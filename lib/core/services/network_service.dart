import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  NetworkService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _online = true;

  bool get isOnline => _online;

  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _online = _hasConnection(results);
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      _online = _hasConnection(results);
    });
  }

  Future<bool> checkOnline() async {
    final results = await _connectivity.checkConnectivity();
    _online = _hasConnection(results);
    return _online;
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _sub?.cancel();
  }
}
