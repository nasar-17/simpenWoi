import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NativeCapture {
  const NativeCapture({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.sourcePackage,
    required this.postedAt,
    required this.categoryId,
    required this.note,
  });

  factory NativeCapture.fromMap(Map<Object?, Object?> map) {
    final int postedAt =
        (map['posted_at'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
    return NativeCapture(
      id: (map['id'] as num?)?.toInt() ?? 0,
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      merchant: map['merchant'] as String?,
      sourcePackage: map['source_package'] as String? ?? '',
      postedAt: DateTime.fromMillisecondsSinceEpoch(postedAt),
      categoryId: (map['category_id'] as num?)?.toInt(),
      note: map['note'] as String?,
    );
  }

  final int id;
  final int amount;
  final String? merchant;
  final String sourcePackage;
  final DateTime postedAt;
  final int? categoryId;
  final String? note;
}

class NativeCaptureBridge {
  const NativeCaptureBridge();

  static const MethodChannel _channel = MethodChannel('simpenwoi/capture');

  Future<List<NativeCapture>> getPendingCaptures() async {
    final List<Object?>? raw =
        await _channel.invokeMethod<List<Object?>>('getPendingCaptures');
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
      'markImported',
      <String, Object?>{'ids': ids},
    );
  }

  Future<void> pushCategories({
    required List<Map<String, Object?>> categories,
    required List<Map<String, Object?>> topCategories,
  }) async {
    await _channel.invokeMethod<void>(
      'pushCategories',
      <String, Object?>{
        'categories': categories,
        'top_categories': topCategories,
      },
    );
  }

  Future<void> pushMerchantRules(List<Map<String, Object?>> rules) async {
    await _channel.invokeMethod<void>(
      'pushMerchantRules',
      <String, Object?>{'rules': rules},
    );
  }

  Future<bool> isListenerEnabled() async {
    return await _channel.invokeMethod<bool>('isListenerEnabled') ?? false;
  }

  Future<void> openListenerSettings() async {
    await _channel.invokeMethod<void>('openListenerSettings');
  }

  Future<void> simulateCapture({
    int amount = 25000,
    String merchant = 'Warung Bu Tini',
  }) async {
    await _channel.invokeMethod<void>(
      'simulateCapture',
      <String, Object?>{
        'amount': amount,
        'merchant': merchant,
      },
    );
  }
}

final Provider<NativeCaptureBridge> nativeCaptureBridgeProvider =
    Provider<NativeCaptureBridge>((ref) => const NativeCaptureBridge());
