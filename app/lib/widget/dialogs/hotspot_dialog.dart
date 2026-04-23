import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/provider/hotspot_provider.dart';
import 'package:localsend_app/provider/local_ip_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

class HotspotDialog extends StatelessWidget {
  const HotspotDialog();

  static Future<void> open(BuildContext context) async {
    final started = await context.ref.notifier(hotspotProvider).start();
    if (!started) {
      if (context.mounted) {
        final error = context.ref.read(hotspotProvider).error ?? t.travelMode.error;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }
    if (context.mounted) {
      await showDialog(context: context, builder: (_) => const HotspotDialog());
      // Stop hotspot when dialog is dismissed
      // ignore: use_build_context_synchronously
      context.ref.notifier(hotspotProvider).stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotspot = context.ref.watch(hotspotProvider);
    final localIps = context.ref.watch(localIpProvider).localIps;

    final ssid = hotspot.ssid ?? '';
    final password = hotspot.password ?? '';
    final wifiQr = 'WIFI:S:$ssid;T:WPA;P:$password;;';

    return AlertDialog(
      title: Text(t.travelMode.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: PrettyQrView.data(
              errorCorrectLevel: QrErrorCorrectLevel.Q,
              data: wifiQr,
              decoration: PrettyQrDecoration(
                shape: PrettyQrSmoothSymbol(
                  roundFactor: 0,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(t.travelMode.scanQr, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Text('SSID: $ssid', style: Theme.of(context).textTheme.bodySmall),
          Text('${t.travelMode.password}: $password', style: Theme.of(context).textTheme.bodySmall),
          if (localIps.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('IP: ${localIps.first}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text(t.travelMode.stop),
        ),
      ],
    );
  }
}
