import '../../../core/assistant/assistant_action.dart';
import '../../../core/assistant/assistant_context.dart';
import '../../../core/assistant/assistant_validator.dart';
import '../../../core/assistant/proposed_action.dart';

/// Only a validated transaction or explicit non-transaction decision may affect
/// the capture queue. Other model tools can never execute notification text.
class NotificationAiDecision {
  const NotificationAiDecision({this.transaction, this.discard = false});

  static const String ignoreMarker = 'NOT_A_TRANSACTION';
  final AddTransactionAction? transaction;
  final bool discard;

  factory NotificationAiDecision.fromProposals(
    List<ProposedAction>? proposals,
    AssistantContext context,
  ) {
    if (proposals == null || proposals.length != 1) {
      return const NotificationAiDecision();
    }
    final ProposedAction proposal = proposals.single;
    if (proposal.source != ActionSource.ai) {
      return const NotificationAiDecision();
    }
    final AssistantAction action = proposal.action;
    if (action is AskClarificationAction && action.question == ignoreMarker) {
      return const NotificationAiDecision(discard: true);
    }
    if (action is! AddTransactionAction ||
        validateAssistantAction(action, context) != null) {
      return const NotificationAiDecision();
    }
    return NotificationAiDecision(transaction: action);
  }
}
