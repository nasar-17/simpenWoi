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

class InspectorEntry {
  const InspectorEntry({
    required this.time,
    required this.packageName,
    required this.title,
    required this.text,
    required this.bigText,
    required this.result,
  });

  factory InspectorEntry.fromMap(Map<Object?, Object?> map) {
    final int time = (map[InspectorKeys.time] as num?)?.toInt() ?? 0;
    return InspectorEntry(
      time: DateTime.fromMillisecondsSinceEpoch(time),
      packageName: map[InspectorKeys.package] as String? ?? '',
      title: map[InspectorKeys.title] as String?,
      text: map[InspectorKeys.text] as String?,
      bigText: map[InspectorKeys.bigText] as String?,
      result: map[InspectorKeys.result] as String? ?? '',
    );
  }

  final DateTime time;
  final String packageName;
  final String? title;
  final String? text;
  final String? bigText;
  final String result;
}

class InspectorListenerStatus {
  const InspectorListenerStatus({
    required this.connected,
    required this.updatedAt,
    required this.inspectorEnabled,
  });

  factory InspectorListenerStatus.fromMap(Map<Object?, Object?> map) {
    final int updatedAt = (map[InspectorKeys.updatedAt] as num?)?.toInt() ?? 0;
    return InspectorListenerStatus(
      connected: map[InspectorKeys.connected] as bool? ?? false,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
      inspectorEnabled: map[InspectorKeys.inspectorEnabled] as bool? ?? false,
    );
  }

  final bool connected;
  final DateTime updatedAt;
  final bool inspectorEnabled;
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
