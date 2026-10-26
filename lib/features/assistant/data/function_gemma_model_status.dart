class FunctionGemmaModelStatus {
  const FunctionGemmaModelStatus({
    required this.installed,
    required this.enabled,
    required this.loaded,
    required this.sizeBytes,
    this.error,
  });

  final bool installed;
  final bool enabled;
  final bool loaded;
  final int sizeBytes;
  final String? error;
}
