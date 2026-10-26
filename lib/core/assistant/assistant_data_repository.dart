import '../../features/categories/data/category_repository.dart';
import '../../features/wallets/data/wallet_repository.dart';
import 'assistant_context.dart';

class AssistantDataRepository {
  const AssistantDataRepository({
    required this.categoryRepository,
    required this.walletRepository,
  });

  final CategoryRepository categoryRepository;
  final WalletRepository walletRepository;

  Future<AssistantContext> loadContext() async {
    return AssistantContext(
      wallets: await walletRepository.getAll(),
      categories: await categoryRepository.getAll(),
    );
  }
}
