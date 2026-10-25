import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../capture/presentation/providers/capture_providers.dart';
import '../../data/wallet_repository.dart';
import '../../data/wallet_service.dart';

final Provider<WalletRepository> walletRepositoryProvider =
    Provider<WalletRepository>(
      (ref) => WalletRepository(ref.watch(databaseProvider)),
    );

final Provider<WalletService> walletServiceProvider = Provider<WalletService>(
  (ref) => WalletService(
    repository: ref.watch(walletRepositoryProvider),
    refreshNativeContext: () =>
        ref.read(captureSyncServiceProvider).refreshNativeContext(),
  ),
);

final StreamProvider<List<Wallet>> walletsProvider =
    StreamProvider<List<Wallet>>(
      (ref) => ref.watch(walletRepositoryProvider).watchAll(),
    );
