import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/ui_text.dart';
import '../../../capture/presentation/providers/capture_providers.dart';
import '../widgets/inspector_settings_section.dart';
import '../widgets/notification_settings_section.dart';
import '../widgets/settings_info_sections.dart';
import '../widgets/settings_management_section.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with WidgetsBindingObserver {
  bool? _listenerEnabled;
  bool _requestingNotification = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshListener();
    }
  }

  Future<void> _refreshListener() async {
    try {
      final bool enabled = await ref
          .read(nativeCaptureBridgeProvider)
          .isListenerEnabled();
      if (mounted) {
        setState(() {
          _listenerEnabled = enabled;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _listenerEnabled = false;
        });
      }
    }
  }

  Future<void> _openListenerSettings() async {
    try {
      await ref.read(nativeCaptureBridgeProvider).openListenerSettings();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka pengaturan akses notifikasi.'),
          ),
        );
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    setState(() {
      _requestingNotification = true;
    });
    try {
      final PermissionStatus status = await Permission.notification.request();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status.isGranted
                ? 'Izin notifikasi diberikan.'
                : 'Izin notifikasi belum diberikan. Aktifkan dari pengaturan '
                      'aplikasi.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _requestingNotification = false;
        });
      }
    }
  }

  Future<void> _simulateCapture() async {
    try {
      await ref.read(nativeCaptureBridgeProvider).simulateCapture();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notifikasi simulasi dikirim. Ketuk kategori atau ketik '
              'catatan, lalu buka kembali aplikasi untuk impor.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Simulasi hanya tersedia di build debug pada perangkat Android.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text(UiText.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          NotificationSettingsSection(
            listenerEnabled: _listenerEnabled,
            requestingNotification: _requestingNotification,
            onOpenListenerSettings: _openListenerSettings,
            onRequestNotificationPermission: _requestNotificationPermission,
            onSimulateCapture: _simulateCapture,
          ),
          const SizedBox(height: 16),
          const SettingsManagementSection(),
          if (kDebugMode) ...<Widget>[
            const SizedBox(height: 16),
            const InspectorSettingsSection(),
          ],
          const SizedBox(height: 16),
          const SettingsInfoSections(),
          const SizedBox(height: 32),
          Center(
            child: Text(
              AppConstants.appName,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
