import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import 'wallet_repository.dart';

final Provider<WalletRepository> walletRepositoryProvider =
    Provider<WalletRepository>(
  (ref) => WalletRepository(ref.watch(databaseProvider)),
);

final StreamProvider<List<Wallet>> walletsProvider =
    StreamProvider<List<Wallet>>(
  (ref) => ref.watch(walletRepositoryProvider).watchAll(),
);
