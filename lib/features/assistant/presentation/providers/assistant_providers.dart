import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/assistant/assistant_data_repository.dart';
import '../../../../core/assistant/assistant_executor.dart';
import '../../../../core/assistant/assistant_query_repository.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../targets/presentation/providers/spending_target_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../wallets/presentation/providers/wallet_providers.dart';
import '../../domain/ai_provider.dart';
import '../../domain/category_scorer.dart';
import '../../domain/input_engine.dart';

final Provider<AssistantDataRepository> assistantDataRepositoryProvider =
    Provider<AssistantDataRepository>(
      (ref) => AssistantDataRepository(
        categoryRepository: ref.watch(categoryRepositoryProvider),
        walletRepository: ref.watch(walletRepositoryProvider),
      ),
    );

final Provider<AssistantQueryRepository> assistantQueryRepositoryProvider =
    Provider<AssistantQueryRepository>(
      (ref) => AssistantQueryRepository(ref.watch(databaseProvider)),
    );

final Provider<AssistantExecutor> assistantExecutorProvider =
    Provider<AssistantExecutor>((ref) {
      final AppDatabase database = ref.watch(databaseProvider);
      return AssistantExecutor(
        database: database,
        dataRepository: ref.watch(assistantDataRepositoryProvider),
        queryRepository: ref.watch(assistantQueryRepositoryProvider),
        transactionRepository: ref.watch(transactionRepositoryProvider),
        walletRepository: ref.watch(walletRepositoryProvider),
        categoryRepository: ref.watch(categoryRepositoryProvider),
        targetRepository: ref.watch(spendingTargetRepositoryProvider),
      );
    });

final Provider<CategoryScorer> categoryScorerProvider =
    Provider<CategoryScorer>((ref) => const NullCategoryScorer());

final Provider<AiProvider> aiProviderProvider = Provider<AiProvider>(
  (ref) => const NullAiProvider(),
);

final Provider<InputEngine> inputEngineProvider = Provider<InputEngine>((ref) {
  return InputEngine(
    dataRepository: ref.watch(assistantDataRepositoryProvider),
    categoryScorer: ref.watch(categoryScorerProvider),
    aiProvider: ref.watch(aiProviderProvider),
  );
});
