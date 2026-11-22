import 'network_status.dart';

/// Lets requests determine offline state from transport failures until a
/// connectivity monitor is introduced.
class AssumedOnlineNetworkStatus implements NetworkStatus {
  const AssumedOnlineNetworkStatus();

  @override
  Future<bool> isOnline() async => true;
}
