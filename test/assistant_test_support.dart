import 'package:simpen_woi/core/assistant/assistant_action.dart';
import 'package:simpen_woi/core/assistant/assistant_context.dart';
import 'package:simpen_woi/core/assistant/assistant_data_repository.dart';
import 'package:simpen_woi/core/assistant/proposed_action.dart';
import 'package:simpen_woi/core/database/app_database.dart';
import 'package:simpen_woi/features/assistant/domain/ai_provider.dart';

AssistantContext testContext() => AssistantContext(
  wallets: <Wallet>[
    Wallet(id: 1, name: 'Tunai', balance: 0,
        isDefault: true, createdAt: DateTime(2026)),
  ],
  categories: <Category>[
    Category(id: 1, name: 'Makanan', type: 'expense', createdAt: DateTime(2026)),
    Category(id: 2, name: 'Gaji', type: 'income', createdAt: DateTime(2026)),
  ],
);

class ContextRepository implements AssistantDataRepository {
  ContextRepository(this.context);
  final AssistantContext context;
  @override
  Future<AssistantContext> loadContext() async => context;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RecordingAi implements AiProvider {
  RecordingAi({this.actions, this.available = false, this.failure});
  final List<ProposedAction>? actions;
  final bool available;
  final Object? failure;
  final List<String> inputs = <String>[];
  @override
  bool get isAvailable => available;
  @override
  Future<List<ProposedAction>?> propose(String input, AssistantContext context) async {
    inputs.add(input);
    if (failure != null) throw failure!;
    return actions;
  }
}

ProposedAction transactionProposal({int? categoryId = 1, String type = 'expense', int walletId = 1}) {
  return ProposedAction(
    action: AddTransactionAction(amount: 15000, type: type,
        walletId: walletId, categoryId: categoryId),
    confidence: 0.8, source: ActionSource.ai, summary: 'Usulan model',
  );
}
