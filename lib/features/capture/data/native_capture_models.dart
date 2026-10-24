import '../capture_constants.dart';

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
        (map[CaptureKeys.postedAt] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    return NativeCapture(
      id: (map[CaptureKeys.id] as num?)?.toInt() ?? 0,
      amount: (map[CaptureKeys.amount] as num?)?.toInt() ?? 0,
      merchant: map[CaptureKeys.merchant] as String?,
      sourcePackage: map[CaptureKeys.sourcePackage] as String? ?? '',
      postedAt: DateTime.fromMillisecondsSinceEpoch(postedAt),
      categoryId: (map[CaptureKeys.categoryId] as num?)?.toInt(),
      note: map[CaptureKeys.note] as String?,
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

class DirtyNativeCapture {
  const DirtyNativeCapture({
    required this.id,
    required this.categoryId,
    required this.note,
  });

  factory DirtyNativeCapture.fromMap(Map<Object?, Object?> map) {
    return DirtyNativeCapture(
      id: (map[CaptureKeys.id] as num?)?.toInt() ?? 0,
      categoryId: (map[CaptureKeys.categoryId] as num?)?.toInt(),
      note: map[CaptureKeys.note] as String?,
    );
  }

  final int id;
  final int? categoryId;
  final String? note;
}
