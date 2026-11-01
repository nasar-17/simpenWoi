import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/capture/data/native_capture_bridge.dart';
import '../features/capture/presentation/providers/capture_providers.dart';

final captureRuntimeErrorProvider = NotifierProvider<
    CaptureRuntimeError, String?>(CaptureRuntimeError.new);

class CaptureRuntimeError extends Notifier<String?> {
  @override
  String? build() => null;

  void update(String? message) {
    state = message;
  }
}

final Provider<CaptureRuntime> captureRuntimeProvider = Provider<CaptureRuntime>(
  (ref) {
    final CaptureRuntime runtime = CaptureRuntime(
      bridge: ref.watch(nativeCaptureBridgeProvider),
      synchronize: ref.watch(captureSyncServiceProvider).sync,
      reportError: ref.read(captureRuntimeErrorProvider.notifier).update,
    );
    ref.onDispose(runtime.dispose);
    return runtime;
  },
);

/// Starts before runApp so headless notifications never depend on a UI frame.
class CaptureRuntime {
  CaptureRuntime({
    required this.bridge,
    required this.synchronize,
    required this.reportError,
  });

  final NativeCaptureBridge bridge;
  final Future<void> Function() synchronize;
  final void Function(String?) reportError;
  StreamSubscription<void>? _events;
  bool _started = false;
  bool _disposed = false;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _events = bridge.captureEvents.listen(
      (_) => unawaited(sync()),
      onError: (Object _) => reportError(
        'Koneksi notifikasi terputus. Buka ulang aplikasi untuk mencoba lagi.',
      ),
    );
    unawaited(sync());
  }

  Future<void> sync() async {
    if (_disposed) return;
    try {
      await synchronize();
      if (!_disposed) reportError(null);
    } catch (_) {
      if (!_disposed) {
        reportError(
          'Pemrosesan notifikasi belum selesai. Periksa Model AI dan pastikan '
          'dompet bank/e-wallet tersedia, lalu coba lagi. Antrean lokal tetap tersimpan.',
        );
      }
    }
  }

  void dispose() {
    _disposed = true;
    unawaited(_events?.cancel());
  }
}
