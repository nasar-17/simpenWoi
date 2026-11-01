class FunctionGemmaModelStatus {
  const FunctionGemmaModelStatus({
    required this.installed,
    required this.enabled,
    required this.loaded,
    required this.sizeBytes,
    this.error,
    this.completedInferences = 0,
    this.lastInferenceDuration,
  });

  final bool installed;
  final bool enabled;
  final bool loaded;
  final int sizeBytes;
  final String? error;

  /// Volatile session counters; no input or model output is stored.
  final int completedInferences;
  final Duration? lastInferenceDuration;
}
