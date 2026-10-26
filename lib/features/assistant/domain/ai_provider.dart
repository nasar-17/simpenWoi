import '../../../core/assistant/assistant_context.dart';
import '../../../core/assistant/proposed_action.dart';

abstract interface class AiProvider {
  bool get isAvailable;

  Future<List<ProposedAction>?> propose(String input, AssistantContext context);
}

class NullAiProvider implements AiProvider {
  const NullAiProvider();

  @override
  bool get isAvailable => false;

  @override
  Future<List<ProposedAction>?> propose(
    String input,
    AssistantContext context,
  ) async {
    return null;
  }
}
