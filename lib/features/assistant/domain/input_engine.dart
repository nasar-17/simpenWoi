import '../../../core/assistant/assistant_action.dart';
import '../../../core/assistant/assistant_context.dart';
import '../../../core/assistant/assistant_data_repository.dart';
import '../../../core/assistant/assistant_validator.dart';
import '../../../core/assistant/proposed_action.dart';
import 'ai_provider.dart';

/// All natural-language interpretation goes through the on-device model.
class InputEngine {
  const InputEngine({required this.dataRepository, required this.aiProvider});

  final AssistantDataRepository dataRepository;
  final AiProvider aiProvider;

  Future<List<ProposedAction>> process(String raw) async {
    if (raw.trim().isEmpty) return const <ProposedAction>[];
    final AssistantContext context = await dataRepository.loadContext();
    if (context.wallets.isEmpty) {
      return <ProposedAction>[_clarify('Buat dompet terlebih dahulu.')];
    }
    final List<ProposedAction>? proposals = await aiProvider.propose(raw, context);
    if (proposals != null && proposals.isNotEmpty &&
        proposals.every((ProposedAction proposal) =>
            validateAssistantAction(proposal.action, context) == null)) {
      return proposals;
    }
    return <ProposedAction>[
      _clarify('AI lokal belum dapat memahami input. Periksa Pengaturan > '
          'Model AI, impor dan aktifkan FunctionGemma, lalu coba lagi. '
          'Belum ada perubahan yang disimpan.'),
    ];
  }

  ProposedAction _clarify(String message) => ProposedAction(
    action: AskClarificationAction(question: message),
    confidence: 0,
    source: ActionSource.ai,
    summary: message,
  );
}
