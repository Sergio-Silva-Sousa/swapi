import 'package:connectivity_plus/connectivity_plus.dart';

import 'network_status.dart';

/// Reports connectivity through the platform's network monitor so the API
/// layer can avoid pointless requests while offline.
class ConnectivityNetworkStatus implements NetworkStatus {
  const ConnectivityNetworkStatus(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }
}
