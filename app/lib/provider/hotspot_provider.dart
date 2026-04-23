import 'package:localsend_app/provider/local_ip_provider.dart';
import 'package:localsend_app/util/native/channel/android_channel.dart' as android_channel;
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:refena_flutter/refena_flutter.dart';

final _logger = Logger('Hotspot');

enum HotspotStatus { off, starting, active, error }

class HotspotState {
  final HotspotStatus status;
  final String? ssid;
  final String? password;
  final String? error;

  const HotspotState({this.status = HotspotStatus.off, this.ssid, this.password, this.error});
}

final hotspotProvider = NotifierProvider<HotspotService, HotspotState>((ref) => HotspotService());

class HotspotService extends PureNotifier<HotspotState> {
  @override
  HotspotState init() => const HotspotState();

  Future<bool> start() async {
    if (state.status == HotspotStatus.active || state.status == HotspotStatus.starting) return false;

    // Request permissions
    final locationStatus = await Permission.locationWhenInUse.request();
    if (!locationStatus.isGranted) {
      state = const HotspotState(status: HotspotStatus.error, error: 'Location permission denied');
      return false;
    }

    // API 33+ needs NEARBY_WIFI_DEVICES
    final nearbyStatus = await Permission.nearbyWifiDevices.request();
    _logger.info('NEARBY_WIFI_DEVICES permission: $nearbyStatus');

    state = const HotspotState(status: HotspotStatus.starting);

    final result = await android_channel.startHotspot();
    if (result == null) {
      state = const HotspotState(status: HotspotStatus.error, error: 'Failed to start hotspot');
      return false;
    }

    state = HotspotState(
      status: HotspotStatus.active,
      ssid: result.ssid,
      password: result.password,
    );

    _logger.info('Hotspot started: SSID=${result.ssid}');

    // Refresh network interfaces so multicast discovery picks up the new interface
    ensureRef((ref) {
      ref.redux(localIpProvider).dispatchAsync(FetchLocalIpAction());
    });

    return true;
  }

  Future<void> stop() async {
    await android_channel.stopHotspot();
    state = const HotspotState();
    _logger.info('Hotspot stopped');

    ensureRef((ref) {
      ref.redux(localIpProvider).dispatchAsync(FetchLocalIpAction());
    });
  }
}
