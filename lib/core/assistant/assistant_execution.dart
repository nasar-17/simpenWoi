class AssistantExecution {
  const AssistantExecution({
    required this.message,
    this.undo,
    this.createdCategoryId,
  });

  final String message;
  final Future<void> Function()? undo;
  final int? createdCategoryId;
}

class AssistantExecutionException implements Exception {
  const AssistantExecutionException(this.message);

  final String message;
}
