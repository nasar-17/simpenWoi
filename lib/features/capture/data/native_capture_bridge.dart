import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../capture_constants.dart';
import 'native_capture_models.dart';

/// Jembatan MethodChannel ke layanan capture native.
class NativeCaptureBridge {
  const NativeCaptureBridge();

  static const MethodChannel _channel = MethodChannel(CaptureChannel.name);

  Future<List<NativeCapture>> getPendingCaptures() async {
    final List<Object?>? raw = await _channel.invokeMethod<List<Object?>>(
      CaptureChannel.getPendingCaptures,
    );
    if (raw == null) {
      return <NativeCapture>[];
    }
    return raw
        .whereType<Map<Object?, Object?>>()
        .map(NativeCapture.fromMap)
        .toList(growable: false);
  }

  Future<void> markImported(List<int> ids) async {
    if (ids.isEmpty) {
      return;
    }
    await _channel.invokeMethod<void>(
      CaptureChannel.markImported,
      <String, Object?>{CaptureChannel.ids: ids},
    );
  }

  Future<List<DirtyNativeCapture>> getDirtyCaptures() async {
    final List<Object?>? raw = await _channel.invokeMethod<List<Object?>>(
      CaptureChannel.getDirtyCaptures,
    );
    if (raw == null) {
      return <DirtyNativeCapture>[];
    }
    return raw
        .whereType<Map<Object?, Object?>>()
        .map(DirtyNativeCapture.fromMap)
        .toList(growable: false);
  }

  Future<void> markSynced(List<int> ids) async {
    if (ids.isEmpty) {
      return;
    }
    await _channel.invokeMethod<void>(
      CaptureChannel.markSynced,
      <String, Object?>{CaptureChannel.ids: ids},
    );
  }

  Future<void> pushCategories({
    required List<Map<String, Object?>> categories,
    required List<Map<String, Object?>> topCategories,
    required List<Map<String, Object?>> incomeCategories,
    required List<Map<String, Object?>> topIncomeCategories,
  }) async {
    await _channel
        .invokeMethod<void>(CaptureChannel.pushCategories, <String, Object?>{
          CaptureChannel.categories: categories,
          CaptureChannel.topCategories: topCategories,
          CaptureChannel.incomeCategories: incomeCategories,
          CaptureChannel.topIncomeCategories: topIncomeCategories,
        });
  }

  Future<void> pushMerchantRules(List<Map<String, Object?>> rules) async {
    await _channel.invokeMethod<void>(
      CaptureChannel.pushMerchantRules,
      <String, Object?>{CaptureChannel.rules: rules},
    );
  }

  Future<bool> isListenerEnabled() async {
    return await _channel.invokeMethod<bool>(
          CaptureChannel.isListenerEnabled,
        ) ??
        false;
  }

  Future<void> openListenerSettings() async {
    await _channel.invokeMethod<void>(CaptureChannel.openListenerSettings);
  }

  Future<void> simulateCapture({
    int amount = CaptureConstants.defaultSimulationAmount,
    String merchant = CaptureConstants.defaultSimulationMerchant,
  }) async {
    await _channel.invokeMethod<void>(
      CaptureChannel.simulateCapture,
      <String, Object?>{
        CaptureChannel.amount: amount,
        CaptureChannel.merchant: merchant,
      },
    );
  }

  Future<List<InspectorEntry>> getInspectorLog() async {
    final List<Object?>? raw = await _channel.invokeMethod<List<Object?>>(
      CaptureChannel.getInspectorLog,
    );
    if (raw == null) {
      return <InspectorEntry>[];
    }
    return raw
        .whereType<Map<Object?, Object?>>()
        .map(InspectorEntry.fromMap)
        .toList(growable: false);
  }

  Future<void> clearInspectorLog() async {
    await _channel.invokeMethod<void>(CaptureChannel.clearInspectorLog);
  }

  Future<void> setInspectorEnabled(bool enabled) async {
    if (!kDebugMode) {
      throw StateError('Inspektor notifikasi hanya tersedia pada build debug.');
    }
    await _channel.invokeMethod<void>(
      CaptureChannel.setInspectorEnabled,
      <String, Object?>{CaptureChannel.enabled: enabled},
    );
  }

  Future<InspectorListenerStatus> getListenerStatus() async {
    final Map<Object?, Object?>? raw = await _channel
        .invokeMethod<Map<Object?, Object?>>(CaptureChannel.getListenerStatus);
    return InspectorListenerStatus.fromMap(raw ?? <Object?, Object?>{});
  }
}
