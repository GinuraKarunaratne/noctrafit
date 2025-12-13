import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

/// Service to monitor network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final Logger _logger = Logger();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = false;

  bool get isOnline => _isOnline;

  /// Start monitoring connectivity
  void startMonitoring(Function(bool isOnline) onConnectivityChanged) {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);

      if (wasOnline != _isOnline) {
        _logger.i('Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
        onConnectivityChanged(_isOnline);
      }
    });

    // Check initial connectivity
    checkConnectivity().then((isOnline) {
      if (_isOnline != isOnline) {
        _isOnline = isOnline;
        onConnectivityChanged(_isOnline);
      }
    });
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.isNotEmpty && !results.contains(ConnectivityResult.none);
    } catch (e) {
      _logger.e('Error checking connectivity', error: e);
      return false;
    }
  }

  /// Stop monitoring connectivity
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stopMonitoring();
  }
}
