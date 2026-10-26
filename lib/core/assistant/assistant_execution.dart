class AssistantExecution {
  const AssistantExecution({required this.message, this.undo});

  final String message;
  final Future<void> Function()? undo;
}

class AssistantExecutionException implements Exception {
  const AssistantExecutionException(this.message);

  final String message;
}
