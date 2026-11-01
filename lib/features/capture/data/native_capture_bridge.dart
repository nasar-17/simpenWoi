import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../capture_constants.dart';
import 'native_capture_models.dart';

/// Jembatan MethodChannel ke layanan capture native.
class NativeCaptureBridge {
  const NativeCaptureBridge();

  static const MethodChannel _channel = MethodChannel(CaptureChannel.name);
  static const EventChannel _eventChannel = EventChannel(CaptureChannel.events);

  Stream<void> get captureEvents =>
      _eventChannel.receiveBroadcastStream().map<void>((dynamic _) {});

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

  Future<List<NativeCapture>> getRecentCaptures() async {
    final List<Object?>? raw = await _channel.invokeMethod<List<Object?>>(
      'getRecentAiCaptures',
    );
    return (raw ?? <Object?>[])
        .whereType<Map<Object?, Object?>>()
        .map(NativeCapture.fromMap)
        .toList(growable: false);
  }

  Future<bool> confirmAiTransfer({
    required int primaryId,
    required int secondaryId,
    required int amount,
    required int fromWalletId,
    required int toWalletId,
    required String primaryDirection,
    required String secondaryDirection,
  }) async => await _channel.invokeMethod<bool>(
    'confirmAiTransfer',
    <String, Object?>{
      'primary_id': primaryId, 'secondary_id': secondaryId, 'amount': amount,
      'from_wallet_id': fromWalletId, 'to_wallet_id': toWalletId,
      'primary_direction': primaryDirection,
      'secondary_direction': secondaryDirection,
    },
  ) ?? false;

  Future<void> resolveAiCapture({
    required int id,
    required int amount,
    required String direction,
    required int? categoryId,
    required String? merchant,
    required String? note,
  }) => _channel.invokeMethod<void>('resolveAiCapture', <String, Object?>{
    'id': id, 'amount': amount, 'direction': direction,
    'category_id': categoryId, 'merchant': merchant, 'note': note,
  });

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

  Future<void> syncCapture({
    required int id,
    required int? categoryId,
    required String? note,
  }) async {
    await _channel.invokeMethod<void>(
      CaptureChannel.syncCapture,
      <String, Object?>{
        CaptureChannel.ids: <int>[id],
        CaptureKeys.categoryId: categoryId,
        CaptureKeys.note: note,
      },
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

