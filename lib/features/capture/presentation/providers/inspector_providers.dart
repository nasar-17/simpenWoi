import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/native_capture_models.dart';
import 'capture_providers.dart';

final FutureProvider<List<InspectorEntry>> inspectorLogProvider =
    FutureProvider<List<InspectorEntry>>(
      (ref) => ref.watch(nativeCaptureBridgeProvider).getInspectorLog(),
    );

final FutureProvider<InspectorListenerStatus> inspectorStatusProvider =
    FutureProvider<InspectorListenerStatus>(
      (ref) => ref.watch(nativeCaptureBridgeProvider).getListenerStatus(),
    );
